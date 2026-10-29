//
//  CategoryDonutChart.swift
//  SubCheck
//
//  Donut breakdown of monthly spend per category with an interactive legend.
//

import SwiftUI
import Charts

struct CategoryTotal: Identifiable {
    let category: CategoryType
    let total: Double
    let count: Int
    var id: CategoryType { category }
}

struct CategoryDonutChart: View {

    let subscriptions: [Subscription]
    /// Categoria destacada; quem chama usa isso para filtrar os outros gráficos.
    @Binding var selection: CategoryType?

    init(subscriptions: [Subscription], selection: Binding<CategoryType?>) {
        self.subscriptions = subscriptions
        self._selection = selection
    }

    private var breakdown: [CategoryTotal] {
        Dictionary(grouping: subscriptions, by: \.categoryType)
            .map { category, subs in
                CategoryTotal(
                    category: category,
                    total: subs.monthlyTotal(in: .shared),
                    count: subs.count
                )
            }
            .sorted { $0.total > $1.total }
    }

    private var grandTotal: Double {
        breakdown.reduce(0) { $0 + $1.total }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Gastos por categoria")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)

            if breakdown.isEmpty {
                EmptyStateView(
                    icon: "chart.pie",
                    title: "Sem dados ainda",
                    message: "Adicione assinaturas para ver a distribuição por categoria."
                )
            } else {
                chart
                legend
            }
        }
        .cardSurface()
    }

    private var chart: some View {
        Chart(breakdown) { item in
            SectorMark(
                angle: .value("Total", item.total),
                innerRadius: .ratio(0.62),
                angularInset: 2
            )
            .cornerRadius(6)
            .foregroundStyle(item.category.color)
            .opacity(selection == nil || selection == item.category ? 1 : 0.28)
        }
        .frame(height: 210)
        .chartLegend(.hidden)
        .chartBackground { proxy in
            GeometryReader { geo in
                if let frame = proxy.plotFrame {
                    let rect = geo[frame]
                    VStack(spacing: 2) {
                        Text(selection?.displayName ?? L.t("Total mensal"))
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                            .lineLimit(1)
                        Text(Money.compact(selectedTotal))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.textPrimary)
                            .contentTransition(.numericText())
                    }
                    .position(x: rect.midX, y: rect.midY)
                }
            }
        }
        .animation(.snappy, value: selection)
    }

    private var legend: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(breakdown) { item in
                Button {
                    withAnimation(.snappy) {
                        selection = (selection == item.category) ? nil : item.category
                    }
                    Haptics.impact(.light)
                } label: {
                    HStack(spacing: Spacing.md) {
                        Circle()
                            .fill(item.category.color)
                            .frame(width: 10, height: 10)

                        Image(systemName: item.category.icon)
                            .font(.caption)
                            .foregroundStyle(item.category.color)
                            .frame(width: 18)

                        Text(item.category.displayName)
                            .font(.subheadline)
                            .foregroundStyle(Color.textPrimary)

                        Text("\(item.count)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.elevatedBackground, in: Capsule())

                        Spacer(minLength: 0)

                        Text(Money.format(item.total))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.textPrimary)

                        Text(percent(for: item))
                            .font(.caption2)
                            .foregroundStyle(Color.textSecondary)
                            .frame(width: 38, alignment: .trailing)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var selectedTotal: Double {
        guard let selection else { return grandTotal }
        return breakdown.first { $0.category == selection }?.total ?? grandTotal
    }

    private func percent(for item: CategoryTotal) -> String {
        guard grandTotal > 0 else { return "0%" }
        return (item.total / grandTotal).formatted(.percent.precision(.fractionLength(0)))
    }
}
