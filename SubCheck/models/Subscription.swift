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
        isCancelled: Bool = false
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
    }
}

// MARK: - Derived values

extension Subscription {
    /// Próxima data de cobrança a partir de hoje.
    var nextBillingDate: Date {
        let calendar = Calendar.current
        let now = Date()

        if startDate > now { return startDate }

        var nextDate = startDate
        while nextDate <= now {
            switch frequency {
            case .weekly:
                nextDate = calendar.date(byAdding: .day, value: 7, to: nextDate) ?? nextDate
            case .monthly:
                nextDate = calendar.date(byAdding: .month, value: 1, to: nextDate) ?? nextDate
            case .yearly:
                nextDate = calendar.date(byAdding: .year, value: 1, to: nextDate) ?? nextDate
            }
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
}
