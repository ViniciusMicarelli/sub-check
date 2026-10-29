//
//  SubscriptionRowView.swift
//  SubCheck
//

import SwiftUI

struct SubscriptionRowView: View {

    let subscription: Subscription

    var body: some View {
        HStack(spacing: Spacing.md) {
            SubscriptionIconView(
                icon: subscription.resolvedIcon,
                fallbackColor: subscription.categoryColor,
                size: 44
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(subscription.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)

                HStack(spacing: 6) {
                    Text(subscription.frequency.displayName)
                    Text("•")
                    Text(nextBillingText)
                }
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 3) {
                Text(Money.format(subscription.cost, code: subscription.currencyCode))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                    .contentTransition(.numericText())
                Text(L.t("subscription.perMonth", Money.format(subscription.monthlyCost(in: .shared))))
                    .font(.caption2)
                    .foregroundStyle(Color.textSecondary)
                    .contentTransition(.numericText())
            }
        }
        .padding(.vertical, 4)
        .opacity(subscription.isCancelled ? 0.55 : 1)
        .animation(.snappy, value: subscription.cost)
        .animation(.snappy, value: subscription.monthlyCost(in: .shared))
    }

    private var nextBillingText: String {
        if subscription.isCancelled { return L.t("Cancelada") }
        if subscription.daysUntilNextBilling == 0 { return L.t("Cobra hoje") }
        return L.t("due.inDays", subscription.daysUntilNextBilling)
    }
}
