//
//  UpcomingPaymentsSection.swift
//  SubCheck
//
//  Next charges for the coming weeks with urgency styling.
//

import SwiftUI

struct UpcomingPaymentsSection: View {

    let subscriptions: [Subscription]

    private var upcoming: [Subscription] {
        subscriptions
            .filter { !$0.isCancelled && $0.daysUntilNextBilling <= 30 }
            .sorted { $0.daysUntilNextBilling < $1.daysUntilNextBilling }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Próximas cobranças")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("30 dias")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            if upcoming.isEmpty {
                Text("Nenhuma cobrança nos próximos 30 dias.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(upcoming.enumerated()), id: \.element.id) { index, subscription in
                        NavigationLink {
                            SubscriptionDetailView(subscription: subscription)
                        } label: {
                            UpcomingPaymentRow(subscription: subscription)
                        }
                        .buttonStyle(.plain)

                        if index < upcoming.count - 1 {
                            Divider().overlay(Color.hairline)
                        }
                    }
                }
            }
        }
        .cardSurface()
    }
}

private struct UpcomingPaymentRow: View {

    let subscription: Subscription

    private var urgencyColor: Color {
        switch subscription.daysUntilNextBilling {
        case 0...2: .danger
        case 3...7: .warning
        default: .textSecondary
        }
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(subscription.categoryColor.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: subscription.categoryIcon)
                    .font(.subheadline)
                    .foregroundStyle(subscription.categoryColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                Text(subscription.nextBillingDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 2) {
                Text(Money.format(subscription.cost, code: subscription.currencyCode))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                Text(daysLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(urgencyColor)
            }
        }
        .padding(.vertical, Spacing.sm)
        .contentShape(Rectangle())
    }

    private var daysLabel: String {
        switch subscription.daysUntilNextBilling {
        case 0: "Hoje"
        case 1: "Amanhã"
        default: "em \(subscription.daysUntilNextBilling) dias"
        }
    }
}
