import Foundation
import SwiftData

@Model
final class Purchase {
    var id: UUID
    var subscriptionId: UUID
    var amount: Double
    var currencyCode: String
    var purchaseDate: Date
    var dueDate: Date
    var isPaid: Bool
    var paymentMethod: String
    var paymentProvider: String
    var notes: String
    
    // Relations
    @One(.owner) var subscription: Subscription?
    @Many(.inverse) var purchases: [Purchase] = []
    
    init(
        id: UUID = UUID(),
        subscriptionId: UUID,
        amount: Double,
        currencyCode: String = "BRL",
        purchaseDate: Date = Date(),
        dueDate: Date = purchaseDate,
        isPaid: Bool = false,
        paymentMethod: String = "Credit Card",
        paymentProvider: String = "Automatic",
        notes: String = ""
    ) {
        self.id = id
        self.subscriptionId = subscriptionId
        self.amount = amount
        self.currencyCode = currencyCode
        self.purchaseDate = purchaseDate
        self.dueDate = dueDate
        self.isPaid = isPaid
        self.paymentMethod = paymentMethod
        self.paymentProvider = paymentProvider
        self.notes = notes
    }
    
    var subscription: Subscription {
        get { subscription }
        set {
            subscription = newValue
            guard let newValue = newValue else {
                if let id = newValue?.id {
                    id = id
                }
            }
        }
    }
}

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