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

    /// A ilha só aparece quando há algo perto de vencer. Uma cobrança a 20
    /// dias deixaria a ilha fixa o tempo todo, sem dizer nada de útil.
    static let windowDays = 3

    /// `true` se o vencimento é hoje, já passou ou cai nos próximos `days` dias.
    static func isWithinWindow(
        due: Date, days: Int = windowDays, now: Date = Date(), calendar: Calendar = .current
    ) -> Bool {
        let start = calendar.startOfDay(for: now)
        let target = calendar.startOfDay(for: due)
        let diff = calendar.dateComponents([.day], from: start, to: target).day ?? 0
        return diff <= days
    }

    /// Quanto tempo a atividade fica na tela. Passado isso, ela é encerrada.
    static let visibleSeconds: TimeInterval = 60

    static func isExpired(startedAt: Date, now: Date = Date()) -> Bool {
        now.timeIntervalSince(startedAt) >= visibleSeconds
    }

    /// Regra de exibição, pura para teste: Pro ativo, interruptor ligado e
    /// permissão do sistema.
    static func shouldRun(hasPro: Bool, enabled: Bool, systemAllows: Bool) -> Bool {
        hasPro && enabled && systemAllows
    }
}

/// Cota diária: quantas vezes por dia a atividade pode aparecer. Só contam as
/// que começam; atualizar uma em andamento não gasta cota.
enum LiveActivityBudget {

    static let defaultDailyLimit = 3
    static let limitRange = 1...10
    static let dailyLimitKey = "liveActivityDailyLimit"
    private static let dayKey = "liveActivityBudgetDay"
    private static let countKey = "liveActivityBudgetCount"

    static func clamp(_ limit: Int) -> Int {
        min(max(limit, limitRange.lowerBound), limitRange.upperBound)
    }

    /// Regra pura: ainda cabe mais uma hoje?
    static func canStart(usedToday: Int, limit: Int) -> Bool {
        usedToday < clamp(limit)
    }

    /// Identifica o dia (aaaammdd) para zerar a contagem à meia-noite.
    static func dayNumber(_ date: Date = Date(), calendar: Calendar = .current) -> Int {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return (c.year ?? 0) * 10_000 + (c.month ?? 0) * 100 + (c.day ?? 0)
    }

    static func usedToday(defaults: UserDefaults = .standard, now: Date = Date()) -> Int {
        defaults.integer(forKey: dayKey) == dayNumber(now) ? defaults.integer(forKey: countKey) : 0
    }

    static func recordStart(defaults: UserDefaults = .standard, now: Date = Date()) {
        let today = dayNumber(now)
        let used = usedToday(defaults: defaults, now: now)
        defaults.set(today, forKey: dayKey)
        defaults.set(used + 1, forKey: countKey)
    }

    static var dailyLimit: Int {
        let stored = UserDefaults.standard.object(forKey: dailyLimitKey) as? Int
        return clamp(stored ?? defaultDailyLimit)
    }
}

@Observable
@MainActor
final class LiveActivityService {

    static let shared = LiveActivityService()

    /// Interruptor das Ajustes, lido também pelo `@AppStorage` da tela.
    static let enabledKey = "liveActivityEnabled"

    private init() {}

    /// O app define como encerrar a atividade depois de `visibleSeconds`
    /// (precisa de UIKit, que a extensão de widgets não tem).
    static var scheduleAutoEnd: ((Activity<SubCheckActivityAttributes>) -> Void)?

    /// `true` quando o usuário permitiu Live Activities nas Ajustes.
    var areActivitiesEnabled: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    /// Escolha do usuário nas Ajustes. Ligada por padrão.
    var isEnabled: Bool {
        UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    /// Acesso Pro compartilhado com a extensão de widgets, que não enxerga o
    /// Keychain do app. O app grava a cada sincronização.
    static let sharedProKey = "liveActivityProAccess"

    /// A Ilha Dinâmica é um recurso Pro (compra ou teste ativo).
    var hasProAccess: Bool {
        let shared = UserDefaults(suiteName: SharedModelContainer.appGroupID)
        if isAppExtension { return shared?.bool(forKey: Self.sharedProKey) ?? false }
        let value = ProAccessSnapshot.current()
        shared?.set(value, forKey: Self.sharedProKey)
        return value
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

        guard LiveActivityLifecycle.shouldRun(
            hasPro: hasProAccess, enabled: isEnabled, systemAllows: areActivitiesEnabled
        ) else {
            stop()
            return
        }
        start(with: subscriptions, service: service)
    }

    /// Resultado de uma tentativa de iniciar a atividade, para as Ajustes
    /// poderem explicar por que a ilha não apareceu.
    enum StartResult: Equatable {
        case started, updated, disabledBySystem, noSubscriptions
        /// Nada vence nos próximos dias: a ilha fica desligada de propósito.
        case nothingSoon
        /// A cota de avisos de hoje já foi usada.
        case dailyLimitReached
        case requiresPro
        case failed(String)
    }

    /// Começa a acompanhar a próxima cobrança. Se já existe uma atividade,
    /// apenas atualiza o conteúdo. Só funciona com o app em primeiro plano.
    @discardableResult
    func start(
        with subscriptions: [Subscription],
        service: CurrencyService = .shared,
        bills: [SubCheckActivityAttributes.UpcomingCharge]? = nil,
        ignoringPolicy: Bool = false
    ) -> StartResult {
        guard areActivitiesEnabled else { return .disabledBySystem }
        if !ignoringPolicy, !hasProAccess {
            stop()
            return .requiresPro
        }
        let window = ignoringPolicy ? nil : LiveActivityLifecycle.windowDays
        let all = bills ?? Self.billCharges()
        guard let state = Self.state(from: subscriptions, service: service, bills: all, windowDays: window) else {
            // Nada a mostrar (sem assinaturas, ou nada vence em breve):
            // encerra a atividade em vez de deixá-la fixa na ilha.
            stop()
            let hasAny = subscriptions.contains { !$0.isCancelled } || !all.isEmpty
            return hasAny ? .nothingSoon : .noSubscriptions
        }

        let content = ActivityContent(
            state: state,
            staleDate: LiveActivityLifecycle.staleDate(forDue: state.nextDueDate)
        )

        if let running {
            // Passou de 1 minuto na tela: encerra. Só volta a aparecer se ainda
            // houver cota hoje.
            if !ignoringPolicy, !isAppExtension,
               LiveActivityLifecycle.isExpired(startedAt: running.attributes.startedAt) {
                let old = running
                Task { await old.end(nil, dismissalPolicy: .immediate) }
                return startNew(content, ignoringPolicy: ignoringPolicy)
            }
            Task { await running.update(content) }
            return .updated
        }

        guard !isAppExtension else { return .failed("extension") }
        return startNew(content, ignoringPolicy: ignoringPolicy)
    }

    /// Começa uma atividade respeitando a cota diária.
    private func startNew(
        _ content: ActivityContent<SubCheckActivityAttributes.ContentState>,
        ignoringPolicy: Bool
    ) -> StartResult {
        if !ignoringPolicy,
           !LiveActivityBudget.canStart(usedToday: LiveActivityBudget.usedToday(), limit: LiveActivityBudget.dailyLimit) {
            return .dailyLimitReached
        }
        if let error = Self.request(content) { return .failed(error) }
        if !ignoringPolicy { LiveActivityBudget.recordStart() }
        return .started
    }

    /// Cria a atividade. Devolve a mensagem de erro, se houver.
    private static func request(_ content: ActivityContent<SubCheckActivityAttributes.ContentState>) -> String? {
        do {
            let activity = try Activity.request(
                attributes: SubCheckActivityAttributes(startedAt: Date()),
                content: content
            )
            scheduleAutoEnd?(activity)
            return nil
        } catch {
            // Sem permissão ou limite de atividades atingido: o app segue normal.
            return error.localizedDescription
        }
    }

    /// Encerra o que já passou de `visibleSeconds` na tela. Chamado ao abrir e
    /// ao sair do app, caso o encerramento agendado não tenha rodado.
    func endExpired(now: Date = Date()) {
        for activity in Activity<SubCheckActivityAttributes>.activities
        where LiveActivityLifecycle.isExpired(startedAt: activity.attributes.startedAt, now: now) {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }

    /// Recalcula o conteúdo da atividade em andamento, se houver.
    func refresh(with subscriptions: [Subscription], service: CurrencyService = .shared) {
        guard let running,
              let state = Self.state(
                from: subscriptions, service: service, bills: Self.billCharges(),
                windowDays: LiveActivityLifecycle.windowDays
              ) else { return }
        let content = ActivityContent(
            state: state,
            staleDate: LiveActivityLifecycle.staleDate(forDue: state.nextDueDate)
        )
        Task { await running.update(content) }
    }

    /// Mostra "Pago ✓" na atividade por alguns segundos depois do botão
    /// "Registrar pagamento". Sem atividade em andamento não faz nada.
    func confirmPaid(
        name: String,
        subscriptions: [Subscription],
        service: CurrencyService = .shared,
        showFor seconds: Double = 3
    ) async {
        guard let running else { return }
        var state = running.content.state
        state.confirmedName = name
        await running.update(ActivityContent(state: state, staleDate: nil))
        try? await Task.sleep(for: .seconds(seconds))
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
        bills: [SubCheckActivityAttributes.UpcomingCharge] = [],
        windowDays: Int? = nil,
        now: Date = Date()
    ) -> SubCheckActivityAttributes.ContentState? {
        let active = subscriptions.filter { !$0.isCancelled }

        let subscriptionCharges = active.map {
            SubCheckActivityAttributes.UpcomingCharge(
                id: $0.id.uuidString,
                name: $0.name,
                amount: $0.cost(in: service),
                dueDate: $0.nextBillingDate,
                category: $0.category,
                icon: Self.iconRaw(for: $0)
            )
        }

        // Assinaturas e contas da casa na mesma fila, da mais próxima à mais distante.
        var all = (subscriptionCharges + bills).sorted { $0.dueDate < $1.dueDate }
        if let windowDays {
            all = all.filter { LiveActivityLifecycle.isWithinWindow(due: $0.dueDate, days: windowDays, now: now) }
        }
        guard let next = all.first else { return nil }

        return SubCheckActivityAttributes.ContentState(
            nextID: next.id,
            nextName: next.name,
            nextAmount: next.amount,
            nextDueDate: next.dueDate,
            nextCategory: next.category,
            monthlyTotal: active.monthlyTotal(in: service),
            upcoming: Array(all.prefix(upcomingLimit)),
            nextKind: next.kind,
            nextIcon: next.icon
        )
    }

    /// Ícone da assinatura como texto. Endereços muito longos ficam de fora
    /// para a atividade respeitar o limite de tamanho do ActivityKit.
    private static func iconRaw(for subscription: Subscription) -> String? {
        let raw = subscription.resolvedIcon.rawValue
        return raw.count <= 120 ? raw : nil
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
