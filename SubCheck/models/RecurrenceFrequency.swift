import Foundation
import SwiftData

enum RecurrenceFrequency: String, Codable, CaseIterable, Identifiable {
    case monthly = "Mensal"
    case yearly = "Anual"
    case weekly = "Semanal"
    
    var id: String { rawValue }

    /// Nome traduzido para exibição. `rawValue` continua em português porque
    /// é o valor persistido no banco.
    var displayName: String {
        switch self {
        case .monthly: L.t("frequency.monthly")
        case .yearly:  L.t("frequency.yearly")
        case .weekly:  L.t("frequency.weekly")
        }
    }

    /// "por mês", "por ano", "por semana" — usado em valores por período.
    var perPeriodLabel: String {
        switch self {
        case .monthly: L.t("frequency.perMonth")
        case .yearly:  L.t("frequency.perYear")
        case .weekly:  L.t("frequency.perWeek")
        }
    }
}