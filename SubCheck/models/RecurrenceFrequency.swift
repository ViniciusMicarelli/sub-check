import Foundation
import SwiftData

enum RecurrenceFrequency: String, Codable, CaseIterable, Identifiable {
    case monthly = "Mensal"
    case yearly = "Anual"
    case weekly = "Semanal"
    
    var id: String { rawValue }
}