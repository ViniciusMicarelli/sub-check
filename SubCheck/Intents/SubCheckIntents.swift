//
//  SubCheckIntents.swift
//  SubCheck
//
//  Ações para Atalhos e Siri: dá para encadeá-las em automações do app
//  Atalhos ("ao chegar em casa", "todo dia 1º", "ao abrir o Modo Foco") e
//  falar com a Siri. Leem e gravam no mesmo banco do app.
//

import AppIntents
import Foundation
import SwiftData

// MARK: - Erros

private enum IntentFailure: Error, CustomLocalizedStringResourceConvertible {
    case limitReached(Int)
    case invalidAmount
    case notFound

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .limitReached(let limit):
            "\(L.t("Você atingiu o limite de %lld assinaturas ativas. O SubCheck Pro libera ilimitadas.", limit))"
        case .invalidAmount:
            "\(L.t("Informe um valor maior que zero."))"
        case .notFound:
            "\(L.t("Não encontrei essa assinatura."))"
        }
    }
}

@MainActor
private func allSubscriptions() throws -> [Subscription] {
    try SharedModelContainer.shared.mainContext.fetch(FetchDescriptor<Subscription>())
}

// MARK: - Próxima cobrança

struct NextChargeIntent: AppIntent {

    static var title: LocalizedStringResource = "Próxima cobrança"
    static var description = IntentDescription("Diz qual assinatura será cobrada em seguida e quando.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let active = try allSubscriptions().filter { !$0.isCancelled }

        guard let next = active.min(by: { $0.nextBillingDate < $1.nextBillingDate }) else {
            let text = L.t("Você não tem assinaturas ativas.")
            return .result(value: text, dialog: "\(text)")
        }

        let days = next.daysUntilNextBilling
        let when = days == 0 ? L.t("hoje") : L.t("em %lld dia(s)", days)
        let text = L.t(
            "%@ será cobrada %@: %@.",
            next.name, when, Money.format(next.cost, code: next.currencyCode)
        )
        return .result(value: text, dialog: "\(text)")
    }
}

// MARK: - Total mensal

struct MonthlyTotalIntent: AppIntent {

    static var title: LocalizedStringResource = "Total mensal"
    static var description = IntentDescription("Informa quanto suas assinaturas custam por mês e por ano.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Double> & ProvidesDialog {
        let active = try allSubscriptions().filter { !$0.isCancelled }
        let monthly = active.monthlyTotal(in: .shared)
        let text = L.t(
            "Você gasta %@ por mês (%@ por ano) em %lld assinatura(s).",
            Money.format(monthly), Money.compact(monthly * 12), active.count
        )
        return .result(value: monthly, dialog: "\(text)")
    }
}

// MARK: - Cobranças dos próximos dias

struct UpcomingChargesIntent: AppIntent {

    static var title: LocalizedStringResource = "Cobranças dos próximos dias"
    static var description = IntentDescription("Soma o que será cobrado nos próximos dias.")

    @Parameter(title: "Dias", default: 7, inclusiveRange: (1, 90))
    var days: Int

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Double> & ProvidesDialog {
        let total = InsightsService.upcomingTotal(try allSubscriptions(), days: days)
        let text = total > 0
            ? L.t("Nos próximos %lld dias serão cobrados %@.", days, Money.format(total))
            : L.t("Nenhuma cobrança nos próximos %lld dias.", days)
        return .result(value: total, dialog: "\(text)")
    }
}

// MARK: - Nova assinatura

enum FrequencyOption: String, AppEnum {
    case monthly, yearly, weekly

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Frequência" }
    static var caseDisplayRepresentations: [FrequencyOption: DisplayRepresentation] {
        [
            .monthly: DisplayRepresentation(title: "Mensal"),
            .yearly: DisplayRepresentation(title: "Anual"),
            .weekly: DisplayRepresentation(title: "Semanal")
        ]
    }

    var recurrence: RecurrenceFrequency {
        switch self {
        case .monthly: .monthly
        case .yearly: .yearly
        case .weekly: .weekly
        }
    }
}

struct AddSubscriptionIntent: AppIntent {

    static var title: LocalizedStringResource = "Adicionar assinatura"
    static var description = IntentDescription("Cadastra uma nova assinatura no SubCheck.")

    @Parameter(title: "Nome", requestValueDialog: "Qual o nome da assinatura?")
    var name: String

    @Parameter(title: "Valor", requestValueDialog: "Qual o valor?")
    var cost: Double

    @Parameter(title: "Frequência", default: .monthly)
    var frequency: FrequencyOption

    static var parameterSummary: some ParameterSummary {
        Summary("Adicionar \(\.$name) por \(\.$cost) (\(\.$frequency))")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard cost > 0 else { throw IntentFailure.invalidAmount }

        let existing = try allSubscriptions()
        let activeCount = existing.filter { !$0.isCancelled }.count
        if !StoreService.shared.hasProAccess && activeCount >= StoreService.freeLimit {
            throw IntentFailure.limitReached(StoreService.freeLimit)
        }

        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let subscription = Subscription(
            name: trimmed,
            cost: cost,
            currencyCode: CurrencyService.shared.baseCode,
            frequency: frequency.recurrence,
            category: SubscriptionCategorizer.categorize(name: trimmed).rawValue
        )

        let context = SharedModelContainer.shared.mainContext
        context.insert(subscription)
        try context.save()

        NotificationService.shared.scheduleNotification(for: subscription)
        LiveActivityService.shared.syncAll(with: existing + [subscription])

        return .result(dialog: "\(L.t("%@ adicionada.", trimmed))")
    }
}

// MARK: - Assinatura como entidade (a Siri pergunta "qual?")

struct SubscriptionEntity: AppEntity {

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Assinatura" }
    static var defaultQuery = SubscriptionEntityQuery()

    var id: String
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    init(_ subscription: Subscription) {
        self.init(id: subscription.id.uuidString, name: subscription.name)
    }
}

struct SubscriptionEntityQuery: EntityStringQuery {

    @MainActor
    func entities(for identifiers: [String]) async throws -> [SubscriptionEntity] {
        try allSubscriptions()
            .filter { identifiers.contains($0.id.uuidString) }
            .map(SubscriptionEntity.init)
    }

    /// "Netflix", "o spotify": casa pelo nome sem diferenciar acento.
    @MainActor
    func entities(matching string: String) async throws -> [SubscriptionEntity] {
        let all = try allSubscriptions()
        return SubscriptionNameMatcher
            .rank(string, in: all.map(\.name))
            .map { SubscriptionEntity(all[$0]) }
    }

    @MainActor
    func suggestedEntities() async throws -> [SubscriptionEntity] {
        try allSubscriptions()
            .filter { !$0.isCancelled }
            .sorted { $0.nextBillingDate < $1.nextBillingDate }
            .map(SubscriptionEntity.init)
    }
}

@MainActor
private func subscription(for entity: SubscriptionEntity) throws -> Subscription {
    guard let id = UUID(uuidString: entity.id),
          let found = try allSubscriptions().first(where: { $0.id == id }) else {
        throw IntentFailure.notFound
    }
    return found
}

// MARK: - Registrar pagamento

struct MarkSubscriptionPaidIntent: AppIntent {

    static var title: LocalizedStringResource = "Registrar pagamento de assinatura"
    static var description = IntentDescription("Marca a próxima cobrança de uma assinatura como paga.")

    @Parameter(title: "Assinatura", requestValueDialog: "Qual assinatura?")
    var subscription: SubscriptionEntity

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let target = try SubCheck.subscription(for: subscription)
        PaymentLedger.markPaid(target, in: SharedModelContainer.shared.mainContext)

        let next = target.nextBillingDate.formatted(date: .abbreviated, time: .omitted)
        return .result(dialog: "\(L.t("Pagamento de %@ registrado. Próxima cobrança em %@.", target.name, next))")
    }
}

// MARK: - Atualizar valor

struct UpdateSubscriptionPriceIntent: AppIntent {

    static var title: LocalizedStringResource = "Atualizar valor da assinatura"
    static var description = IntentDescription("Muda o valor de uma assinatura quando houver reajuste.")

    @Parameter(title: "Assinatura", requestValueDialog: "Qual assinatura?")
    var subscription: SubscriptionEntity

    @Parameter(title: "Novo valor", requestValueDialog: "Qual o novo valor?")
    var newCost: Double

    static var parameterSummary: some ParameterSummary {
        Summary("Atualizar \(\.$subscription) para \(\.$newCost)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard newCost > 0 else { throw IntentFailure.invalidAmount }

        let target = try SubCheck.subscription(for: subscription)
        let old = target.cost
        target.cost = newCost
        target.recordPriceChange(from: old)

        let context = SharedModelContainer.shared.mainContext
        try context.save()
        NotificationService.shared.scheduleNotification(for: target)

        let all = try allSubscriptions()
        LiveActivityService.shared.syncAll(with: all)
        BudgetService.evaluate(all)

        let text = L.t(
            "%@ agora custa %@ (antes %@).",
            target.name,
            Money.format(newCost, code: target.currencyCode),
            Money.format(old, code: target.currencyCode)
        )
        return .result(dialog: "\(text)")
    }
}

// MARK: - Cancelar

struct CancelSubscriptionIntent: AppIntent {

    static var title: LocalizedStringResource = "Marcar assinatura como cancelada"
    static var description = IntentDescription("Marca uma assinatura como cancelada no SubCheck. Não cancela o serviço de verdade.")

    @Parameter(title: "Assinatura", requestValueDialog: "Qual assinatura?")
    var subscription: SubscriptionEntity

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let target = try SubCheck.subscription(for: subscription)

        // Confirma antes: a Siri pode ter entendido o nome errado.
        let question = L.t("Marcar %@ como cancelada no SubCheck?", target.name)
        try await requestConfirmation(result: .result(dialog: "\(question)"))

        if !target.isCancelled {
            SubscriptionStore.toggleCancelled(target, in: SharedModelContainer.shared.mainContext)
        }
        return .result(dialog: "\(L.t("%@ marcada como cancelada. Lembre de cancelar também no serviço.", target.name))")
    }
}

// MARK: - Atalhos prontos (Siri e app Atalhos)

struct SubCheckShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NextChargeIntent(),
            phrases: [
                "Qual a próxima cobrança no \(.applicationName)",
                "Próxima cobrança do \(.applicationName)"
            ],
            shortTitle: "Próxima cobrança",
            systemImageName: "calendar.badge.clock"
        )
        AppShortcut(
            intent: MonthlyTotalIntent(),
            phrases: [
                "Quanto gasto por mês no \(.applicationName)",
                "Total mensal do \(.applicationName)"
            ],
            shortTitle: "Total mensal",
            systemImageName: "creditcard"
        )
        AppShortcut(
            intent: UpcomingChargesIntent(),
            phrases: [
                "O que vence nos próximos dias no \(.applicationName)"
            ],
            shortTitle: "Cobranças dos próximos dias",
            systemImageName: "bell.badge"
        )
        AppShortcut(
            intent: AddSubscriptionIntent(),
            phrases: [
                "Adicionar assinatura no \(.applicationName)",
                "Registrar assinatura no \(.applicationName)"
            ],
            shortTitle: "Adicionar assinatura",
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: MarkSubscriptionPaidIntent(),
            phrases: [
                "Registrar pagamento de \(\.$subscription) no \(.applicationName)",
                "Registrar pagamento no \(.applicationName)"
            ],
            shortTitle: "Registrar pagamento",
            systemImageName: "checkmark.circle"
        )
        AppShortcut(
            intent: UpdateSubscriptionPriceIntent(),
            phrases: [
                "Atualizar valor de \(\.$subscription) no \(.applicationName)",
                "Atualizar valor de assinatura no \(.applicationName)"
            ],
            shortTitle: "Atualizar valor",
            systemImageName: "arrow.up.arrow.down.circle"
        )
        AppShortcut(
            intent: CancelSubscriptionIntent(),
            phrases: [
                "Cancelar \(\.$subscription) no \(.applicationName)",
                "Cancelar assinatura no \(.applicationName)"
            ],
            shortTitle: "Cancelar assinatura",
            systemImageName: "xmark.circle"
        )
    }
}
