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

    /// Começa a acompanhar a próxima cobrança. Se já existe uma atividade,
    /// apenas atualiza o conteúdo.
    func start(with subscriptions: [Subscription], service: CurrencyService = .shared) {
        guard areActivitiesEnabled,
              let state = Self.state(from: subscriptions, service: service) else { return }

        if let running {
            let content = ActivityContent(state: state, staleDate: nil)
            Task { await running.update(content) }
            return
        }

        do {
            _ = try Activity.request(
                attributes: SubCheckActivityAttributes(startedAt: Date()),
                content: ActivityContent(state: state, staleDate: nil)
            )
        } catch {
            // Sem permissão ou limite de atividades atingido: o app segue normal.
        }
    }

    /// Recalcula o conteúdo da atividade em andamento, se houver.
    func refresh(with subscriptions: [Subscription], service: CurrencyService = .shared) {
        guard let running,
              let state = Self.state(from: subscriptions, service: service) else { return }
        let content = ActivityContent(state: state, staleDate: nil)
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
