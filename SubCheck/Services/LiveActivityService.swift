//
//  LiveActivityService.swift
//  SubCheck
//
//  Controla a Live Activity que acompanha a próxima cobrança na ilha
//  dinâmica e na tela de bloqueio. Roda também na extensão de widgets, para
//  que o botão "marcar como pago" consiga atualizar a atividade na hora.
//

import ActivityKit
import Foundation
import Observation
import WidgetKit

/// Regras de duração da atividade, sem depender do ActivityKit para poderem
/// ser testadas.
///
/// O iOS encerra qualquer Live Activity depois de ~8 horas ativa (e tira da
/// tela de bloqueio até 4 horas depois). Sem servidor de push, só o app em
/// primeiro plano consegue iniciar outra. Por isso, ao abrir o app, uma
/// atividade já velha é recriada: o relógio de 8 horas recomeça.
enum LiveActivityLifecycle {

    /// Idade a partir da qual vale recriar a atividade ao abrir o app.
    static let recycleAfter: TimeInterval = 4 * 60 * 60

    static func shouldRecycle(startedAt: Date, now: Date = Date()) -> Bool {
        now.timeIntervalSince(startedAt) >= recycleAfter
    }

    /// Depois do vencimento o conteúdo fica desatualizado (o sistema marca
    /// `isStale`). Antes disso não há o que expirar.
    static func staleDate(forDue due: Date, now: Date = Date()) -> Date? {
        due > now ? due : nil
    }
}

@Observable
@MainActor
final class LiveActivityService {

    static let shared = LiveActivityService()

    /// Interruptor das Ajustes, lido também pelo `@AppStorage` da tela.
    static let enabledKey = "liveActivityEnabled"

    private init() {}

    /// `true` quando o usuário permitiu Live Activities nas Ajustes.
    var areActivitiesEnabled: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    /// Escolha do usuário nas Ajustes. Ligada por padrão.
    var isEnabled: Bool {
        UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    /// Maior número de cobranças listadas na visão expandida.
    private static let upcomingLimit = 3

    /// A extensão de widgets só pode atualizar ou encerrar; criar atividade
    /// exige o app em primeiro plano.
    private var isAppExtension: Bool { Bundle.main.bundlePath.hasSuffix(".appex") }

    private var running: Activity<SubCheckActivityAttributes>? {
        Activity<SubCheckActivityAttributes>.activities.first
    }

    /// Recarrega os widgets e alinha a Live Activity com as assinaturas
    /// atuais. É o único ponto de sincronização: chamado depois de qualquer
    /// mudança que afete a próxima cobrança.
    func syncAll(with subscriptions: [Subscription], service: CurrencyService = .shared) {
        WidgetCenter.shared.reloadAllTimelines()

        guard isEnabled, areActivitiesEnabled else {
            stop()
            return
        }
        start(with: subscriptions, service: service)
    }

    /// Resultado de uma tentativa de iniciar a atividade, para as Ajustes
    /// poderem explicar por que a ilha não apareceu.
    enum StartResult: Equatable {
        case started, updated, disabledBySystem, noSubscriptions
        case failed(String)
    }

    /// Começa a acompanhar a próxima cobrança. Se já existe uma atividade,
    /// apenas atualiza o conteúdo. Só funciona com o app em primeiro plano.
    @discardableResult
    func start(with subscriptions: [Subscription], service: CurrencyService = .shared) -> StartResult {
        guard areActivitiesEnabled else { return .disabledBySystem }
        guard let state = Self.state(from: subscriptions, service: service) else {
            // Sem assinaturas ativas não sobra nada a mostrar: encerra a
            // atividade antiga em vez de deixá-la com dados apagados.
            stop()
            return .noSubscriptions
        }

        let content = ActivityContent(
            state: state,
            staleDate: LiveActivityLifecycle.staleDate(forDue: state.nextDueDate)
        )

        if let running {
            // Atividade velha: encerra e cria outra para zerar o limite de 8h.
            if !isAppExtension,
               LiveActivityLifecycle.shouldRecycle(startedAt: running.attributes.startedAt) {
                let old = running
                Task {
                    await old.end(nil, dismissalPolicy: .immediate)
                    _ = Self.request(content)
                }
                return .started
            }
            Task { await running.update(content) }
            return .updated
        }

        guard !isAppExtension else { return .failed("extension") }
        if let error = Self.request(content) { return .failed(error) }
        return .started
    }

    /// Cria a atividade. Devolve a mensagem de erro, se houver.
    private static func request(_ content: ActivityContent<SubCheckActivityAttributes.ContentState>) -> String? {
        do {
            _ = try Activity.request(
                attributes: SubCheckActivityAttributes(startedAt: Date()),
                content: content
            )
            return nil
        } catch {
            // Sem permissão ou limite de atividades atingido: o app segue normal.
            return error.localizedDescription
        }
    }

    /// Recalcula o conteúdo da atividade em andamento, se houver.
    func refresh(with subscriptions: [Subscription], service: CurrencyService = .shared) {
        guard let running,
              let state = Self.state(from: subscriptions, service: service) else { return }
        let content = ActivityContent(
            state: state,
            staleDate: LiveActivityLifecycle.staleDate(forDue: state.nextDueDate)
        )
        Task { await running.update(content) }
    }

    func stop() {
        let activities = Activity<SubCheckActivityAttributes>.activities
        Task {
            for activity in activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    // MARK: - Estado

    /// Monta o conteúdo a partir das assinaturas ativas, ordenadas pela
    /// próxima cobrança. Devolve `nil` quando não há nada a mostrar.
    static func state(
        from subscriptions: [Subscription],
        service: CurrencyService = .shared
    ) -> SubCheckActivityAttributes.ContentState? {
        let active = subscriptions
            .filter { !$0.isCancelled }
            .sorted { $0.nextBillingDate < $1.nextBillingDate }

        guard let next = active.first else { return nil }

        let upcoming = active.prefix(upcomingLimit).map {
            SubCheckActivityAttributes.UpcomingCharge(
                id: $0.id.uuidString,
                name: $0.name,
                amount: $0.cost(in: service),
                dueDate: $0.nextBillingDate,
                category: $0.category
            )
        }

        return SubCheckActivityAttributes.ContentState(
            nextID: next.id.uuidString,
            nextName: next.name,
            nextAmount: next.cost(in: service),
            nextDueDate: next.nextBillingDate,
            nextCategory: next.category,
            monthlyTotal: active.monthlyTotal(in: service),
            upcoming: Array(upcoming)
        )
    }
}
