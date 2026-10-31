//
//  TrialsCard.swift
//  SubCheck
//
//  Testes gratuitos em curso, do que acaba primeiro para o último, com o
//  valor que passa a ser cobrado. É o aviso que mais evita cobrança surpresa.
//

import SwiftUI

struct TrialsCard: View {

    let subscriptions: [Subscription]

    private var trials: [(subscription: Subscription, days: Int)] {
        subscriptions
            .compactMap { sub in sub.trialDaysLeft.map { (sub, $0) } }
            .sorted { $0.days < $1.days }
    }

    var body: some View {
        if !trials.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Label("Testes gratuitos", systemImage: "hourglass")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)

                ForEach(trials, id: \.subscription.id) { item in
                    NavigationLink {
                        SubscriptionDetailView(subscription: item.subscription)
                    } label: {
                        row(item.subscription, days: item.days)
                    }
                    .buttonStyle(.plain)
                }
            }
            .cardSurface()
        }
    }

    private func row(_ subscription: Subscription, days: Int) -> some View {
        let urgent = days <= 3
        let tint: Color = urgent ? .danger : .warning
        return HStack(spacing: Spacing.md) {
            SubscriptionIconView(
                icon: subscription.resolvedIcon,
                fallbackColor: subscription.categoryColor,
                size: 36
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                Text(L.t("Depois cobra %@", Money.format(subscription.cost, code: subscription.currencyCode)))
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer(minLength: 0)

            Text(days == 0 ? L.t("Hoje") : L.t("due.days", days))
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(tint.opacity(0.15), in: Capsule())
        }
    }
}
