//
//  CategoriesView.swift
//  SubCheck
//

import SwiftUI
import SwiftData

struct CategoriesView: View {

    @Query(sort: \Subscription.name) private var subscriptions: [Subscription]

    private var stats: [CategoryTotal] {
        let active = subscriptions.filter { !$0.isCancelled }
        let grouped = Dictionary(grouping: active, by: \.categoryType)
        return CategoryType.allCases
            .map { category in
                let subs = grouped[category] ?? []
                return CategoryTotal(
                    category: category,
                    total: subs.monthlyTotal(in: .shared),
                    count: subs.count
                )
            }
            .sorted { $0.total > $1.total }
    }

    private var grandTotal: Double {
        stats.reduce(0) { $0 + $1.total }
    }

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.md),
        GridItem(.flexible(), spacing: Spacing.md)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: Spacing.md) {
                    ForEach(stats) { stat in
                        NavigationLink {
                            CategoryDetailView(category: stat.category)
                        } label: {
                            CategoryCard(stat: stat, share: share(for: stat))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Spacing.lg)
            }
            .background(Color.appBackground)
            .navigationTitle("Categorias")
        }
    }

    private func share(for stat: CategoryTotal) -> Double {
        guard grandTotal > 0 else { return 0 }
        return stat.total / grandTotal
    }
}

private struct CategoryCard: View {

    let stat: CategoryTotal
    let share: Double

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(stat.category.color.opacity(0.16))
                    .frame(width: 46, height: 46)
                Image(systemName: stat.category.icon)
                    .font(.title3)
                    .foregroundStyle(stat.category.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(stat.category.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                Text(stat.count == 1 ? L.t("service.one") : L.t("dashboard.services", stat.count))
                    .font(.caption2)
                    .foregroundStyle(Color.textSecondary)
            }

            Text(Money.format(stat.total))
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
                .contentTransition(.numericText())

            ProgressView(value: share)
                .tint(stat.category.color)
                .animation(.snappy, value: share)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(padding: Spacing.md)
    }
}

struct CategoryDetailView: View {

    let category: CategoryType

    @Query(sort: \Subscription.name) private var subscriptions: [Subscription]

    private var items: [Subscription] {
        subscriptions.filter { $0.categoryType == category && !$0.isCancelled }
    }

    private var monthlyTotal: Double {
        items.monthlyTotal(in: .shared)
    }

    var body: some View {
        List {
            if items.isEmpty {
                EmptyStateView(
                    icon: category.icon,
                    title: L.t("category.empty", category.displayName),
                    message: L.t("Nenhuma assinatura ativa nesta categoria.")
                )
            } else {
                Section {
                    LabeledContent("Total mensal", value: Money.format(monthlyTotal))
                    LabeledContent("Serviços", value: "\(items.count)")
                }

                Section("Assinaturas") {
                    ForEach(items) { subscription in
                        NavigationLink {
                            SubscriptionDetailView(subscription: subscription)
                        } label: {
                            SubscriptionRowView(subscription: subscription)
                        }
                    }
                }
            }
        }
        .navigationTitle(category.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
