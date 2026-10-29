//
//  SubCheckWidget.swift
//  SubCheckWidgets
//
//  Reads the App Group backed SwiftData store so the widget always mirrors
//  what the app shows.
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Entry

struct UpcomingItem: Identifiable {
    let id: UUID
    let name: String
    let cost: Double
    let days: Int
    let dueDate: Date
    let icon: SubscriptionIcon
    let color: Color
    let currencyCode: String
}

struct SubCheckEntry: TimelineEntry {
    let date: Date
    let monthlyTotal: Double
    let yearlyTotal: Double
    let activeCount: Int
    let upcoming: [UpcomingItem]

    static var placeholder: SubCheckEntry {
        let now = Date()
        return SubCheckEntry(
            date: now,
            monthlyTotal: 412.90,
            yearlyTotal: 4954.80,
            activeCount: 8,
            upcoming: [
                UpcomingItem(id: UUID(), name: "Netflix", cost: 55.90, days: 2,
                             dueDate: now.addingTimeInterval(172_800),
                             icon: .brand("netflix"), color: .purple, currencyCode: "BRL"),
                UpcomingItem(id: UUID(), name: "Spotify", cost: 21.90, days: 5,
                             dueDate: now.addingTimeInterval(432_000),
                             icon: .brand("spotify"), color: .green, currencyCode: "BRL"),
                UpcomingItem(id: UUID(), name: "iCloud+", cost: 12.90, days: 9,
                             dueDate: now.addingTimeInterval(777_600),
                             icon: .brand("icloud"), color: .orange, currencyCode: "BRL")
            ]
        )
    }
}

// MARK: - Provider

struct SubCheckProvider: TimelineProvider {

    func placeholder(in context: Context) -> SubCheckEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (SubCheckEntry) -> Void) {
        completion(context.isPreview ? .placeholder : loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SubCheckEntry>) -> Void) {
        let entry = loadEntry()
        let next = Calendar.current.date(byAdding: .hour, value: 4, to: Date())
            ?? Date().addingTimeInterval(14_400)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadEntry() -> SubCheckEntry {
        let context = ModelContext(SharedModelContainer.shared)
        let subscriptions = (try? context.fetch(FetchDescriptor<Subscription>())) ?? []
        let active = subscriptions.filter { !$0.isCancelled }
        // Totais já convertidos para a moeda base escolhida no app.
        let monthly = active.monthlyTotal(in: .shared)

        let upcoming = active
            .sorted { $0.daysUntilNextBilling < $1.daysUntilNextBilling }
            .prefix(4)
            .map { subscription in
                UpcomingItem(
                    id: subscription.id,
                    name: subscription.name,
                    cost: subscription.cost,
                    days: subscription.daysUntilNextBilling,
                    dueDate: subscription.nextBillingDate,
                    icon: subscription.resolvedIcon,
                    color: subscription.categoryColor,
                    currencyCode: subscription.currencyCode
                )
            }

        return SubCheckEntry(
            date: Date(),
            monthlyTotal: monthly,
            yearlyTotal: monthly * 12,
            activeCount: active.count,
            upcoming: upcoming
        )
    }
}

// MARK: - Widget

struct SubCheckWidget: Widget {

    let kind = "SubCheckWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SubCheckProvider()) { entry in
            SubCheckWidgetView(entry: entry)
        }
        .configurationDisplayName("SubCheck")
        .description(L.t("Seus gastos mensais e as próximas cobranças."))
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCircular
        ])
    }
}
