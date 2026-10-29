//
//  TopSubscriptionsChart.swift
//  SubCheck
//
//  Horizontal bar chart of the most expensive subscriptions (monthly normalized).
//

import SwiftUI
import Charts

struct TopSubscriptionsChart: View {

    let subscriptions: [Subscription]

    private var top: [Subscription] {
        subscriptions
            .filter { !$0.isCancelled }
            .sorted { $0.monthlyCost(in: .shared) > $1.monthlyCost(in: .shared) }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Maiores gastos mensais")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)

            if top.isEmpty {
                Text("Sem assinaturas ativas.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            } else {
                Chart(top) { subscription in
                    BarMark(
                        x: .value("Custo mensal", subscription.monthlyCost(in: .shared)),
                        y: .value("Serviço", subscription.name)
                    )
                    .foregroundStyle(subscription.categoryColor.gradient)
                    .cornerRadius(6)
                    .annotation(position: .trailing, alignment: .leading) {
                        Text(Money.compact(subscription.monthlyCost(in: .shared)))
                            .font(.caption2)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(preset: .aligned, position: .leading) { _ in
                        AxisValueLabel()
                            .font(.caption)
                    }
                }
                .frame(height: CGFloat(top.count) * 42 + 16)
                // Anima a entrada das barras e a troca de filtro.
                .animation(.snappy, value: top.map(\.id))
            }
        }
        .cardSurface()
    }
}
