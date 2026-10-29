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

            Text(L.t("Total mensal"))
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.85))

            Text(Money.format(entry.monthlyTotal))
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text(L.t("widget.services", entry.activeCount))
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var mediumView: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(L.t("Total mensal"))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.85))
                Text(Money.format(entry.monthlyTotal))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(L.t("widget.servicesYear", entry.activeCount, Money.compact(entry.yearlyTotal)))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider().overlay(.white.opacity(0.3))

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(L.t("Próximas cobranças"))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))

                ForEach(entry.upcoming.prefix(3)) { item in
                    HStack(spacing: Spacing.xs) {
                        SubscriptionIconView(icon: item.icon, fallbackColor: widgetFallback, size: 18)
                        Text(item.name)
                            .font(.caption2)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        dueLabel(item)
                            .font(.caption2.weight(.semibold))
                        payButton(item)
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
                Text(L.t("Total mensal"))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                Text(Money.format(entry.monthlyTotal))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(L.t("widget.servicesActive", entry.activeCount, Money.compact(entry.yearlyTotal)))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.9))
            }

            Divider().overlay(.white.opacity(0.3))

            Text(L.t("Próximas cobranças"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))

            ForEach(entry.upcoming) { item in
                HStack(spacing: Spacing.sm) {
                    SubscriptionIconView(icon: item.icon, fallbackColor: widgetFallback, size: 20)
                        .frame(width: 20)
                    Text(item.name)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Text(Money.format(item.cost, code: item.currencyCode))
                        .font(.caption.weight(.semibold))
                    dueLabel(item)
                        .font(.caption2)
                        .frame(minWidth: 54, alignment: .trailing)
                    payButton(item)
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
            Text(L.t("widget.header", Money.format(entry.monthlyTotal)))
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
            if let next = entry.upcoming.first {
                HStack(spacing: 4) {
                    Text(L.t("widget.nextLine", next.name, daysLabel(next.days), Money.format(next.cost, code: next.currencyCode)))
                        .font(.caption2)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    payButton(next)
                }
            } else {
                Text(L.t("Nenhuma cobrança próxima"))
                    .font(.caption2)
            }
        }
    }

    private var accessoryCircular: some View {
        Gauge(value: min(entry.monthlyTotal, 1000), in: 0...1000) {
            Text(CurrencyService.shared.baseCurrency.symbol)
        } currentValueLabel: {
            Text("\(entry.activeCount)")
                .font(.caption2.bold())
        }
        .gaugeStyle(.accessoryCircular)
    }

    private var inlineText: String {
        L.t("widget.inline", Money.format(entry.monthlyTotal))
    }

    // MARK: - Helpers

    /// Cor de fundo dos ícones sem cor de marca (ficam sobre o gradiente).
    private var widgetFallback: Color { .white.opacity(0.25) }

    private func daysLabel(_ days: Int) -> String {
        switch days {
        case 0: L.t("widget.today")
        case 1: L.t("widget.tomorrow")
        default: L.t("widget.inDays", days)
        }
    }

    /// Contagem ao vivo quando a cobrança é hoje; senão, os dias restantes.
    @ViewBuilder
    private func dueLabel(_ item: UpcomingItem) -> some View {
        if item.days == 0 {
            Text(item.dueDate, style: .timer)
                .monospacedDigit()
        } else {
            Text(daysLabel(item.days))
        }
    }

    /// Botão que registra o pagamento direto do widget, sem abrir o app.
    private func payButton(_ item: UpcomingItem) -> some View {
        Button(intent: MarkPaidIntent(subscriptionID: item.id)) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption2)
        }
        .buttonStyle(.plain)
    }
}
