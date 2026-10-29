import Foundation
import SwiftData

enum ThemeType: String, Codable, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    case custom = "Custom"
}

enum CurrencyPreference: String, Codable, CaseIterable {
    case usd = "USD"
    case euro = "EUR"
    case brl = "BRL"
    case gbp = "GBP"
    
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .euro: return "€"
        case .brl: return "R$"
        case .gbp: return "£"
        }
    }
}

enum SubscriptionStatus: String, Codable {
    case active = "Active"
    case expired = "Expired"
    case canceled = "Canceled"
    case pending = "Pending"
}

enum NotificationType: String, Codable {
    case reminder = "Reminder"
    case overdue = "Overdue"
    case receipt = "Receipt"
    case alert = "Alert"
}

struct UserInfo: Identifiable {
    let id: UUID
    let name: String
    let email: String?
    let avatarUrl: String?
    let isPremium: Bool
    let phoneNumber: String?
    
    init(
        id: UUID = UUID(),
        name: String = "",
        email: String? = nil,
        avatarUrl: String? = nil,
        isPremium: Bool = false,
        phoneNumber: String? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.avatarUrl = avatarUrl
        self.isPremium = isPremium
        self.phoneNumber = phoneNumber
    }
}

@Model
final class User {
    @Attribute(.unique) var userId: String
    var name: String
    var email: String?
    var avatarUrl: String?
    var isPremium: Bool = false
    var phoneNumber: String?
    var address: String?
    var birthdate: Date?
    
    // Theme preferences
    var theme: ThemeType = ThemeType.system
    var prefersDarkMode: Bool = true
    
    // Currency preferences
    var preferredCurrency: CurrencyPreference = CurrencyPreference.usd
    
    // Notification preferences
    var notificationEnabled: Bool = true
    var notificationSound: Bool = true
    var notificationBadge: Bool = true
    var remindersEnabled: Bool = true
    var remindersBefore: Int = 15 // minutes before due
    
    // Created/modified timestamps
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()
    
    // Derived properties
    var displayName: String {
        name
    }
    
    init(userId: String,
         name: String = "",
         email: String? = nil,
         avatarUrl: String? = nil,
         isPremium: Bool = false,
         phoneNumber: String? = nil,
         address: String? = nil,
         birthdate: Date? = nil,
         theme: ThemeType = .system,
         prefersDarkMode: Bool = true,
         preferredCurrency: CurrencyPreference = .usd,
         notificationEnabled: Bool = true,
         notificationSound: Bool = true,
         notificationBadge: Bool = true,
         remindersEnabled: Bool = true,
         remindersBefore: Int = 15) {
        self.userId = userId
        self.name = name
        self.email = email
        self.avatarUrl = avatarUrl
        self.isPremium = isPremium
        self.phoneNumber = phoneNumber
        self.address = address
        self.birthdate = birthdate
        self.theme = theme
        self.prefersDarkMode = prefersDarkMode
        self.preferredCurrency = preferredCurrency
        self.notificationEnabled = notificationEnabled
        self.notificationSound = notificationSound
        self.notificationBadge = notificationBadge
        self.remindersEnabled = remindersEnabled
        self.remindersBefore = remindersBefore
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}

@Model
final class PaymentMethod {
    @Attribute(.unique) var paymentMethodId: String
    var name: String
    var type: PaymentMethodType
    var last4Digits: String?
    var expirationMonth: String?
    var expirationYear: String?
    var cvv: String?
    var isDefault: Bool = false
    var isLocked: Bool = false
    var isActive: Bool = true
    
    // Relationship to subscriptions
    var subscriptionId: UUID?
    @Relationship(deleteRule: .cascade) var subscriptions: [Subscription] = []
    
    // Created/modified timestamps
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()
    
    enum PaymentMethodType: String, Codable {
        case creditCard = "Credit Card"
        case debitCard = "Debit Card"
        case applePay = "Apple Pay"
        case googlePay = "Google Pay"
        case paypal = "PayPal"
        case bankTransfer = "Bank Transfer"
        case wallet = "Wallet"
        case other = "Other"
    }
    
    init(paymentMethodId: String,
         name: String = "",
         type: PaymentMethodType = .creditCard,
         last4Digits: String? = nil,
         expirationMonth: String? = nil,
         expirationYear: String? = nil,
         cvv: String? = nil,
         isDefault: Bool = false,
         isLocked: Bool = false,
         isActive: Bool = true,
         subscriptionId: UUID? = nil) {
        self.paymentMethodId = paymentMethodId
        self.name = name
        self.type = type
        self.last4Digits = last4Digits
        self.expirationMonth = expirationMonth
        self.expirationYear = expirationYear
        self.cvv = cvv
        self.isDefault = isDefault
        self.isLocked = isLocked
        self.isActive = isActive
        self.subscriptionId = subscriptionId
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
    
    // Check if payment method is valid for subscription
    var isValidForSubscription: Bool {
        isActive && !isLocked
    }
}