import Foundation
import SwiftData

@Model
final class DeletedSubscription {
    // CloudKit exige valor padrão em toda propriedade (iCloud em Ajustes).
    var id: UUID = UUID()
    var name: String = ""
    var cost: Double = 0
    var currencyCode: String = "BRL"
    var startDate: Date = Date()
    var deletedDate: Date = Date()
    var deleteReason: String = "Removida pelo usuário"
    
    init(
        id: UUID = UUID(),
        name: String,
        cost: Double,
        currencyCode: String = "BRL",
        startDate: Date = Date(),
        deletedDate: Date = Date(),
        deleteReason: String = "Removida pelo usuário"
    ) {
        self.id = id
        self.name = name
        self.cost = cost
        self.currencyCode = currencyCode
        self.startDate = startDate
        self.deletedDate = deletedDate
        self.deleteReason = deleteReason
    }
}