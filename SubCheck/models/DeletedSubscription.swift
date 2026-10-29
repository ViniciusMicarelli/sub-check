import Foundation
import SwiftData

@Model
final class DeletedSubscription {
    var id: UUID
    var name: String
    var cost: Double
    var currencyCode: String
    var startDate: Date
    var deletedDate: Date
    var deleteReason: String
    
    init(
        id: UUID = UUID(),
        name: String,
        cost: Double,
        currencyCode: String = "BRL",
        startDate: Date = Date(),
        deletedDate: Date = Date(),
        deleteReason: String = "User deleted"
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