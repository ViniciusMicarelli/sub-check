import Foundation
import SwiftData

@Model
final class Subscription {
    var id: UUID
    var name: String
    var cost: Double
    var currencyCode: String
    var startDate: Date
    var frequency: RecurrenceFrequency
    var category: String
    var enableReminders: Bool
    var daysNoticeBefore: Int
    var isCancelled: Bool
    /// Ícone escolhido pelo usuário (ver `SubscriptionIcon`). `nil` = automático.
    var iconRaw: String?
    /// Data da última cobrança registrada. `nil` = nada pago ainda, o ciclo
    /// começa em `startDate`. Ver `PaymentLedger`.
    var lastPaymentDate: Date?

    init(
        id: UUID = UUID(),
        name: String,
        cost: Double,
        currencyCode: String = "BRL",
        startDate: Date = Date(),
        frequency: RecurrenceFrequency = .monthly,
        category: String = CategoryType.entertainment.rawValue,
        enableReminders: Bool = true,
        daysNoticeBefore: Int = 2,
        isCancelled: Bool = false,
        iconRaw: String? = nil,
        lastPaymentDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.cost = cost
        self.currencyCode = currencyCode
        self.startDate = startDate
        self.frequency = frequency
        self.category = category
        self.enableReminders = enableReminders
        self.daysNoticeBefore = daysNoticeBefore
        self.isCancelled = isCancelled
        self.iconRaw = iconRaw
        self.lastPaymentDate = lastPaymentDate
    }
}

// MARK: - Derived values

extension Subscription {

    /// Data da última cobrança; sem histórico, o ciclo parte do início.
    var billingAnchor: Date { lastPaymentDate ?? startDate }

    /// Avança uma data em um ciclo de cobrança.
    func advancing(_ date: Date) -> Date {
        let calendar = Calendar.current
        switch frequency {
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        }
    }

    /// Próxima data de cobrança a partir de hoje.
    var nextBillingDate: Date {
        let now = Date()
        let anchor = billingAnchor

        if anchor > now { return anchor }

        var nextDate = anchor
        while nextDate <= now {
            nextDate = advancing(nextDate)
        }
        return nextDate
    }

    /// Dias restantes até a próxima cobrança (nunca negativo).
    var daysUntilNextBilling: Int {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: nextBillingDate).day ?? 0
        return max(0, days)
    }

    /// Custo normalizado para uma média mensal.
    var monthlyCost: Double {
        switch frequency {
        case .weekly: return cost * 4.33
        case .monthly: return cost
        case .yearly: return cost / 12.0
        }
    }

    /// Custo anualizado.
    var yearlyCost: Double { monthlyCost * 12 }

    var categoryType: CategoryType {
        CategoryType(rawValue: category) ?? .miscellaneous
    }

    /// Cobrança nos próximos N dias.
    func isDue(within days: Int) -> Bool {
        !isCancelled && daysUntilNextBilling <= days
    }

    // MARK: - Histórico

    /// Registra a próxima cobrança como paga e empurra o ciclo para frente,
    /// preservando o dia original do vencimento. Fica no modelo para poder
    /// ser chamado também de dentro da extensão de widget.
    @discardableResult
    func recordPayment(at date: Date = Date(), in context: ModelContext) -> PaymentRecord {
        let due = nextBillingDate

        let record = PaymentRecord(from: self, paidAt: date, isEstimated: false)
        context.insert(record)

        lastPaymentDate = max(due, lastPaymentDate ?? due)
        try? context.save()
        return record
    }
}
