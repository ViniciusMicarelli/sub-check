//
//  MetricCard.swift
//  SubCheck
//
//  Compact KPI tile used on the dashboard grid.
//

import SwiftUI

struct MetricCard: View {

    let title: String
    let value: String
    let icon: String
    let tint: Color
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 30, height: 30)
                    .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
                Spacer(minLength: 0)
            }

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())

            Text(title)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)

            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(tint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(padding: Spacing.md)
    }
}
