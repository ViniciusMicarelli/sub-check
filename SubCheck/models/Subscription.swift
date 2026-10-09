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
    var daysNoticeBefore: Int // Ex: 2 dias antes
    
    init(
        id: UUID = UUID(),
        name: String,
        cost: Double,
        currencyCode: String = "BRL",
        startDate: Date = Date(),
        frequency: RecurrenceFrequency = .monthly,
        category: String = "Entretenimento",
        enableReminders: Bool = true,
        daysNoticeBefore: Int = 2
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
    }
    
    /// Calcula a próxima data de cobrança a partir da data atual
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
    
    /// Normaliza o custo para uma média mensal
    var monthlyCost: Double {
        switch frequency {
        case .weekly: return cost * 4.33
        case .monthly: return cost
        case .yearly: return cost / 12.0
        }
    }
}