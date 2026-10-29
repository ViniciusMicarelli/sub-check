//
//  SubCheckWidget.swift
//  SubCheckWidgets
//
//  Lê o banco do App Group e alimenta os três widgets: resumo, próximas
//  cobranças e distribuição por categoria.
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Modelos do timeline

struct UpcomingItem: Identifiable {
    let id: UUID
    let name: String
    let cost: Double
    let days: Int
    let dueDate: Date
    let icon: SubscriptionIcon
    let color: Color
}

struct CategorySlice: Identifiable {
    let id: String
    let name: String
    let symbol: String
    let color: Color
    /// Já convertido para a moeda base do app.
    let amount: Double
    /// Fatia do total mensal (0...1).
    let share: Double
}

struct SubCheckEntry: TimelineEntry {
    let date: Date
    let monthlyTotal: Double
    let yearlyTotal: Double
    let activeCount: Int
    let dueSoonCount: Int
    let averageCost: Double
    let upcoming: [UpcomingItem]
    let categories: [CategorySlice]

    var nextItem: UpcomingItem? { upcoming.first }

    static var placeholder: SubCheckEntry {
        let now = Date()
        let month: Double = 412.90
        return SubCheckEntry(
            date: now,
            monthlyTotal: month,
            yearlyTotal: month * 12,
            activeCount: 8,
            dueSoonCount: 2,
            averageCost: month / 8,
            upcoming: [
                UpcomingItem(id: UUID(), name: "Netflix", cost: 55.90, days: 0,
                             dueDate: now.addingTimeInterval(5_400),
                             icon: .brand("netflix"), color: .red),
                UpcomingItem(id: UUID(), name: "Spotify", cost: 21.90, days: 3,
                             dueDate: now.addingTimeInterval(259_200),
                             icon: .brand("spotify"), color: .green),
                UpcomingItem(id: UUID(), name: "iCloud+", cost: 12.90, days: 6,
                             dueDate: now.addingTimeInterval(518_400),
                             icon: .brand("icloud"), color: .blue)
            ],
            categories: [
                CategorySlice(id: "Entretenimento", name: L.t("category.entertainment"),
                              symbol: "play.tv.fill",
                              color: CategoryType.entertainment.color, amount: 180.70, share: 0.44),
                CategorySlice(id: "Produtividade", name: L.t("category.productivity"),
                              symbol: "hammer.fill",
                              color: CategoryType.productivity.color, amount: 112.00, share: 0.27),
                CategorySlice(id: "Utilidades", name: L.t("category.utilities"),
                              symbol: "bolt.fill",
                              color: CategoryType.utilities.color, amount: 74.20, share: 0.18),
                CategorySlice(id: "Outros", name: L.t("category.miscellaneous"),
                              symbol: "square.grid.2x2.fill",
                              color: CategoryType.miscellaneous.color, amount: 46.00, share: 0.11)
            ]
        )
    }
}

// MARK: - Provider

struct SubCheckProvider: TimelineProvider {

    func placeholder(in context: Context) -> SubCheckEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (SubCheckEntry) -> Void) {
        completion(context.isPreview ? .placeholder : makeEntry(for: Date()))
    }

    /// Gera um entry por virada de dia. Assim os rótulos "em N dias" se
    /// corrigem sozinhos à meia-noite, sem depender de uma recarga.
    func getTimeline(in context: Context, completion: @escaping (Timeline<SubCheckEntry>) -> Void) {
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: Date())

        var entries: [SubCheckEntry] = []
        for offset in 0..<8 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: midnight) else { continue }
            // O primeiro entry vale para agora, para a contagem ao vivo
            // começar no momento certo.
            entries.append(makeEntry(for: offset == 0 ? Date() : day.addingTimeInterval(1)))
        }

        let next = calendar.date(byAdding: .day, value: 8, to: midnight)
            ?? midnight.addingTimeInterval(691_200)
        completion(Timeline(entries: entries, policy: .after(next)))
    }

    /// Monta o entry como se "hoje" fosse `reference`.
    private func makeEntry(for reference: Date) -> SubCheckEntry {
        let context = ModelContext(SharedModelContainer.shared)
        let stored = (try? context.fetch(FetchDescriptor<Subscription>())) ?? []
        let active = stored.filter { !$0.isCancelled }

        let service = CurrencyService.shared
        let monthly = active.monthlyTotal(in: service)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: reference)

        let upcoming = active
            .sorted { $0.nextBillingDate < $1.nextBillingDate }
            .prefix(5)
            .map { subscription -> UpcomingItem in
                let due = subscription.nextBillingDate
                let days = calendar.dateComponents(
                    [.day], from: today, to: calendar.startOfDay(for: due)
                ).day ?? 0

                return UpcomingItem(
                    id: subscription.id,
                    name: subscription.name,
                    cost: service.convert(subscription.cost, from: subscription.currencyCode),
                    days: max(0, days),
                    dueDate: due,
                    icon: subscription.resolvedIcon,
                    color: subscription.categoryColor
                )
            }

        // Soma por categoria, já na moeda base.
        var totals: [CategoryType: Double] = [:]
        for subscription in active {
            totals[subscription.categoryType, default: 0] += subscription.monthlyCost(in: service)
        }

        let categories = totals
            .map { type, amount in
                CategorySlice(
                    id: type.rawValue,
                    name: type.displayName,
                    symbol: type.icon,
                    color: type.color,
                    amount: amount,
                    share: monthly > 0 ? amount / monthly : 0
                )
            }
            .sorted { $0.amount > $1.amount }

        let horizon = calendar.date(byAdding: .day, value: 7, to: today) ?? today

        return SubCheckEntry(
            date: reference,
            monthlyTotal: monthly,
            yearlyTotal: monthly * 12,
            activeCount: active.count,
            dueSoonCount: active.filter { calendar.startOfDay(for: $0.nextBillingDate) <= horizon }.count,
            averageCost: active.isEmpty ? 0 : monthly / Double(active.count),
            upcoming: Array(upcoming),
            categories: categories
        )
    }
}

// MARK: - Widgets

/// Totais e distribuição por categoria.
struct SubCheckSummaryWidget: Widget {

    let kind = "SubCheckWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SubCheckProvider()) { entry in
            SummaryWidgetView(entry: entry)
        }
        .configurationDisplayName(L.t("Total mensal"))
        .description(L.t("Seu gasto mensal e a distribuição por categoria."))
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryInline,
            .accessoryRectangular
        ])
    }
}

/// Próximas cobranças, com contagem regressiva e botão de registrar pagamento.
struct SubCheckUpcomingWidget: Widget {

    let kind = "SubCheckUpcomingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SubCheckProvider()) { entry in
            UpcomingWidgetView(entry: entry)
        }
        .configurationDisplayName(L.t("Próximas cobranças"))
        .description(L.t("O que vence em seguida e quanto falta para cada cobrança."))
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryInline,
            .accessoryRectangular,
            .accessoryCircular
        ])
    }
}

/// Quanto cada categoria representa do gasto mensal.
struct SubCheckCategoriesWidget: Widget {

    let kind = "SubCheckCategoriesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SubCheckProvider()) { entry in
            CategoriesWidgetView(entry: entry)
        }
        .configurationDisplayName(L.t("Categorias"))
        .description(L.t("Quanto cada categoria representa do seu gasto mensal."))
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryRectangular,
            .accessoryCircular
        ])
    }
}
