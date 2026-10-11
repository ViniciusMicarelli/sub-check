import SwiftUI
import SwiftData
import Charts

struct DashboardTabView: View {
    @Query(sort: \Subscription.name) private var subscriptions: [Subscription]

    private var totalMonthlyExpense: Double {
        subscriptions.reduce(0) { $0 + $1.monthlyCost }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // MARK: - Resumo Financeiro
                    FinanceSummaryCard(monthlyTotal: totalMonthlyExpense, subscriptionCount: subscriptions.count, upcoming: subscriptions.min { $0.nextBillingDate < $1.nextBillingDate })

                    // MARK: - Distribuição por Categoria (Gráfico)
                    if !subscriptions.isEmpty {
                        CategoryDistributionChart(subscriptions: subscriptions)
                    }

                    // MARK: - Assinaturas Ativas
                    ActiveSubscriptionsView(subscriptions: subscriptions)
                }
                .padding(16)
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isAddingSubscription = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingSubscription) {
                AddSubscriptionView()
            }
        }
    }

    @State private var isAddingSubscription = false
}

struct FinanceSummaryCard: View {
    let monthlyTotal: Double
    let subscriptionCount: Int
    let upcoming: Subscription?

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gasto Mensal")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(monthlyTotal, format: .currency(code: "BRL"))
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                HStack(alignment: .top) {
                    Text("\(subscriptionCount) ")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Assinaturas")
                        .font(.callout)
                        .fontWeight(.bold)
                }
            }

            if let upcoming {
                Divider()
                    .overlay(.white.opacity(0.2))

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Próxima Cobrança", systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(upcoming.nextBillingDate.formatted(.dateTime.day().month(.wide)))
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }

                    Text(upcoming.name)
                        .font(.headline)
                }
            }
        }
        .padding(20)
        .background(Color.ultraDark)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .primary.opacity(0.2), radius: 10, x: 0, y: 5)
    }

}

struct CategoryDistributionChart: View {
    let subscriptions: [Subscription]

    private var categoryData: [(category: String, amount: Double)] {
        let grouped = Dictionary(grouping: subscriptions, by: { categoryForSubscription($0) })
        return grouped.map { (key, items) in
            (category: key, amount: items.reduce(0) { $0 + $1.monthlyCost })
        }.sorted { $0.amount > $1.amount }
    }

    private func categoryForSubscription(_ subscription: Subscription) -> String {
        SubscriptionManager.shared.categorize(name: subscription.name)
    }

    var body: some View {
        Chart(categoryData, id: \.category) { item in
            SectorMark(
                angle: .value("Gasto", item.amount),
                innerRadius: .ratio(0.65),
                angularInset: 2.0
            )
            .cornerRadius(6)
            .foregroundStyle(by: .value("Categoria", item.category))
        }
        .frame(height: 180)
        .chartLegend(position: .bottom, alignment: .center, spacing: 12)
        .padding(.vertical, 8)
    }
}

struct ActiveSubscriptionsView: View {
    let subscriptions: [Subscription]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Assinaturas Ativas").font(.title3).bold()
            if subscriptions.isEmpty {
                ContentUnavailableView("Nenhuma assinatura", systemImage: "creditcard",
                    description: Text("Adicione suas primeiras assinaturas para começar."))
            } else {
                ForEach(subscriptions) { subscription in
                    SubscriptionRowView(subscription: subscription)
                }
            }
        }
    }
}

struct SubscriptionRowView: View {
    let subscription: Subscription

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.headline)
                    .foregroundStyle(categoryColor(for: subscription.category))

                Text("Próximo vencimento: \(subscription.nextBillingDate.formatted(date: .numeric, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(subscription.cost, format: .currency(code: subscription.currencyCode))
                    .font(.subheadline)
                    .bold()

                Text(subscription.frequency.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.1))
            }
        }
        .padding(14)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "entretenimento": return .purple
        case "trabalho": return .blue
        case "saúde": return .green
        case "utilitários": return .orange
        default: return .gray
        }
    }
}
