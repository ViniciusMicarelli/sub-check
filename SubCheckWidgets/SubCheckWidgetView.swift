//
//  SubCheckWidgetView.swift
//  SubCheckWidgets
//

import WidgetKit
import SwiftUI

struct SubCheckWidgetView: View {

    @Environment(\.widgetFamily) private var family
    let entry: SubCheckEntry

    var body: some View {
        content
            .containerBackground(for: .widget) {
                if isAccessory {
                    AccessoryWidgetBackground()
                } else {
                    Color.brandGradient
                }
            }
    }

    private var isAccessory: Bool {
        switch family {
        case .accessoryRectangular, .accessoryInline, .accessoryCircular: true
        default: false
        }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemSmall:      smallView
        case .systemMedium:     mediumView
        case .systemLarge:      largeView
        case .accessoryRectangular: accessoryRectangular
        case .accessoryInline:  Text(inlineText)
        case .accessoryCircular: accessoryCircular
        default:                smallView
        }
    }

    // MARK: - System families

    private var smallView: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Image(systemName: "chart.pie.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))

            Text("Total mensal")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.85))

            Text(Money.format(entry.monthlyTotal))
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text("\(entry.activeCount) serviços")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var mediumView: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Total mensal")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.85))
                Text(Money.format(entry.monthlyTotal))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("\(entry.activeCount) serviços · \(Money.compact(entry.yearlyTotal))/ano")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider().overlay(.white.opacity(0.3))

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Próximas cobranças")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))

                ForEach(entry.upcoming.prefix(3)) { item in
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: item.icon)
                            .font(.caption2)
                        Text(item.name)
                            .font(.caption2)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Text(daysLabel(item.days))
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(.white.opacity(0.95))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var largeView: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Total mensal")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                Text(Money.format(entry.monthlyTotal))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("\(entry.activeCount) serviços ativos · \(Money.compact(entry.yearlyTotal)) por ano")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.9))
            }

            Divider().overlay(.white.opacity(0.3))

            Text("Próximas cobranças")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))

            ForEach(entry.upcoming) { item in
                HStack(spacing: Spacing.sm) {
                    Image(systemName: item.icon)
                        .font(.caption)
                        .frame(width: 18)
                    Text(item.name)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Text(Money.format(item.cost, code: item.currencyCode))
                        .font(.caption.weight(.semibold))
                    Text(daysLabel(item.days))
                        .font(.caption2)
                        .frame(width: 54, alignment: .trailing)
                }
                .foregroundStyle(.white.opacity(0.95))
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Accessory (lock screen)

    private var accessoryRectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("SubCheck · \(Money.format(entry.monthlyTotal))/mês")
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
            if let next = entry.upcoming.first {
                Text("\(next.name) · \(daysLabel(next.days)) · \(Money.format(next.cost, code: next.currencyCode))")
                    .font(.caption2)
                    .lineLimit(1)
            } else {
                Text("Nenhuma cobrança próxima")
                    .font(.caption2)
            }
        }
    }

    private var accessoryCircular: some View {
        Gauge(value: min(entry.monthlyTotal, 1000), in: 0...1000) {
            Text("R$")
        } currentValueLabel: {
            Text("\(entry.activeCount)")
                .font(.caption2.bold())
        }
        .gaugeStyle(.accessoryCircular)
    }

    private var inlineText: String {
        "SubCheck: \(Money.format(entry.monthlyTotal))/mês"
    }

    // MARK: - Helpers

    private func daysLabel(_ days: Int) -> String {
        switch days {
        case 0: "hoje"
        case 1: "amanhã"
        default: "\(days)d"
        }
    }
}
