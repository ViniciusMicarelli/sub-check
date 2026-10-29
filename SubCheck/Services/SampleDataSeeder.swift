//
//  SampleDataSeeder.swift
//  SubCheck
//
//  Fills the store with a realistic starter set the first time the app runs
//  so the dashboard, charts and widgets have something to show.
//

import Foundation
import SwiftData

enum SampleDataSeeder {

    private struct Sample {
        let name: String
        let cost: Double
        let frequency: RecurrenceFrequency
        let category: CategoryType
        let startMonthsAgo: Int
    }

    private static let samples: [Sample] = [
        Sample(name: "Netflix", cost: 55.90, frequency: .monthly, category: .entertainment, startMonthsAgo: 14),
        Sample(name: "Spotify", cost: 21.90, frequency: .monthly, category: .entertainment, startMonthsAgo: 22),
        Sample(name: "iCloud+", cost: 12.90, frequency: .monthly, category: .utilities, startMonthsAgo: 30),
        Sample(name: "Figma", cost: 89.00, frequency: .monthly, category: .productivity, startMonthsAgo: 9),
        Sample(name: "Amazon Prime", cost: 19.90, frequency: .monthly, category: .entertainment, startMonthsAgo: 18),
        Sample(name: "Smart Fit", cost: 119.90, frequency: .monthly, category: .health, startMonthsAgo: 6),
        Sample(name: "Notion", cost: 48.00, frequency: .monthly, category: .productivity, startMonthsAgo: 4),
        Sample(name: "Folha de S.Paulo", cost: 29.90, frequency: .monthly, category: .news, startMonthsAgo: 12),
        Sample(name: "Duolingo", cost: 39.90, frequency: .yearly, category: .education, startMonthsAgo: 8),
        Sample(name: "Adobe Creative Cloud", cost: 299.00, frequency: .monthly, category: .productivity, startMonthsAgo: 20),
        Sample(name: "Sem Parar", cost: 24.90, frequency: .monthly, category: .transport, startMonthsAgo: 16),
        Sample(name: "1Password", cost: 179.00, frequency: .yearly, category: .utilities, startMonthsAgo: 5)
    ]

    static func seedIfNeeded(in context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<Subscription>())) ?? 0
        guard count == 0 else { return }
        seed(in: context)
    }

    static func seed(in context: ModelContext) {
        let calendar = Calendar.current
        for sample in samples {
            let start = calendar.date(byAdding: .month, value: -sample.startMonthsAgo, to: Date()) ?? Date()
            let subscription = Subscription(
                name: sample.name,
                cost: sample.cost,
                startDate: start,
                frequency: sample.frequency,
                category: sample.category.rawValue
            )
            context.insert(subscription)
        }
        try? context.save()
    }

    static func eraseAll(in context: ModelContext) {
        try? context.delete(model: Subscription.self)
        try? context.delete(model: DeletedSubscription.self)
        try? context.delete(model: PaymentRecord.self)
        try? context.save()
    }
}
