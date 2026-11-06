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
import SwiftData
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
    func start(
        with subscriptions: [Subscription],
        service: CurrencyService = .shared,
        bills: [SubCheckActivityAttributes.UpcomingCharge]? = nil
    ) -> StartResult {
        guard areActivitiesEnabled else { return .disabledBySystem }
        guard let state = Self.state(from: subscriptions, service: service, bills: bills ?? Self.billCharges()) else {
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
              let state = Self.state(from: subscriptions, service: service, bills: Self.billCharges()) else { return }
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
        service: CurrencyService = .shared,
        bills: [SubCheckActivityAttributes.UpcomingCharge] = []
    ) -> SubCheckActivityAttributes.ContentState? {
        let active = subscriptions.filter { !$0.isCancelled }

        let subscriptionCharges = active.map {
            SubCheckActivityAttributes.UpcomingCharge(
                id: $0.id.uuidString,
                name: $0.name,
                amount: $0.cost(in: service),
                dueDate: $0.nextBillingDate,
                category: $0.category
            )
        }

        // Assinaturas e contas da casa na mesma fila, da mais próxima à mais distante.
        let all = (subscriptionCharges + bills).sorted { $0.dueDate < $1.dueDate }
        guard let next = all.first else { return nil }

        return SubCheckActivityAttributes.ContentState(
            nextID: next.id,
            nextName: next.name,
            nextAmount: next.amount,
            nextDueDate: next.dueDate,
            nextCategory: next.category,
            monthlyTotal: active.monthlyTotal(in: service),
            upcoming: Array(all.prefix(upcomingLimit)),
            nextKind: next.kind
        )
    }

    /// Contas da casa que pedem atenção: vencidas ou vencendo nos próximos
    /// dias e ainda sem pagamento. Lê do mesmo banco que o app e os widgets.
    static func billCharges(
        now: Date = Date(), calendar: Calendar = .current
    ) -> [SubCheckActivityAttributes.UpcomingCharge] {
        let context = ModelContext(SharedModelContainer.shared)
        let entries = (try? context.fetch(FetchDescriptor<BillEntry>())) ?? []
        let bills = (try? context.fetch(FetchDescriptor<Bill>())) ?? []
        let expected = Dictionary(bills.map { ($0.id, $0.expectedAmount) }, uniquingKeysWith: { first, _ in first })

        return entries
            .filter { entry in
                let days = BillMath.daysUntil(entry.dueDate, now: now, calendar: calendar)
                return !entry.isPaid && !entry.isSkipped && days <= 3 && days >= -35
            }
            .map { entry in
                SubCheckActivityAttributes.UpcomingCharge(
                    id: entry.billID.uuidString,
                    name: entry.billName,
                    amount: entry.amount > 0 ? entry.amount : (expected[entry.billID] ?? 0),
                    dueDate: entry.dueDate,
                    category: entry.categoryRaw,
                    kind: "bill"
                )
            }
    }
}
