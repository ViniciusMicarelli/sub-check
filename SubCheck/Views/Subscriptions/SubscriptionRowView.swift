//
//  SubscriptionRowView.swift
//  SubCheck
//

import SwiftUI

struct SubscriptionRowView: View {

    let subscription: Subscription

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(subscription.categoryColor.opacity(0.16))
                    .frame(width: 44, height: 44)
                Image(systemName: subscription.categoryIcon)
                    .font(.body)
                    .foregroundStyle(subscription.categoryColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(subscription.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)

                HStack(spacing: 6) {
                    Text(subscription.frequency.rawValue)
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
                Text("\(Money.format(subscription.monthlyCost))/mês")
                    .font(.caption2)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.vertical, 4)
        .opacity(subscription.isCancelled ? 0.55 : 1)
    }

    private var nextBillingText: String {
        if subscription.isCancelled { return "Cancelada" }
        if subscription.daysUntilNextBilling == 0 { return "Cobra hoje" }
        return "em \(subscription.daysUntilNextBilling) dias"
    }
}
