//
//  SubCheckWidgetView.swift
//  SubCheckWidgets
//
//  Desenho dos três widgets. Usam as cores semânticas do app, que já
//  acompanham claro/escuro, em vez de um gradiente fixo.
//

import WidgetKit
import SwiftUI

// MARK: - Fundo

extension View {
    /// Fundo obrigatório do WidgetKit: material do sistema na tela de
    /// bloqueio, cartão do app na tela inicial.
    func widgetContainerBackground(accessory: Bool) -> some View {
        containerBackground(for: .widget) {
            if accessory {
                AccessoryWidgetBackground()
            } else {
                Color.cardBackground
            }
        }
    }
}

/// Selo com ícone da área e rótulo, usado como cabeçalho de cada widget.
struct WidgetBadge: View {

    let icon: String
    let title: String
    var tint: Color = .brand

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(
                    tint.gradient,
                    in: RoundedRectangle(cornerRadius: 5, style: .continuous)
                )

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.textSecondary)
                .lineLimit(1)
        }
    }
}

/// Número com legenda, usado nos cantos dos widgets grandes.
struct StatPill: View {

    let value: String
    let label: String
    var tint: Color = .brand

    var body: some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
                .contentTransition(.numericText())

            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(Color.textSecondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Peças compartilhadas

/// Barra proporcional do gasto por categoria.
struct CategoryBar: View {

    let slices: [CategorySlice]
    var limit = 4
    var height: CGFloat = 8

    private let gap: CGFloat = 2

    private var visible: [CategorySlice] { Array(slices.prefix(limit)) }

    /// O que sobra fora das categorias mostradas.
    private var remainder: Double {
        max(0, 1 - visible.reduce(0) { $0 + $1.share })
    }

    var body: some View {
        GeometryReader { proxy in
            let parts = visible.count + (remainder > 0.005 ? 1 : 0)
            let available = max(0, proxy.size.width - gap * CGFloat(max(0, parts - 1)))

            HStack(spacing: gap) {
                ForEach(visible) { slice in
                    segment(slice.color, width: available * slice.share)
                }
                if remainder > 0.005 {
                    segment(Color.textTertiary.opacity(0.35), width: available * remainder)
                }
            }
            .frame(width: proxy.size.width, alignment: .leading)
        }
        .frame(height: height)
    }

    private func segment(_ color: Color, width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: height / 2, style: .continuous)
            .fill(color)
            .frame(width: max(0, width))
    }
}

/// Categoria com bolinha de cor, nome e valor.
struct CategoryLegendRow: View {

    let slice: CategorySlice

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(slice.color)
                .frame(width: 8, height: 8)

            Text(slice.name)
                .font(.caption2)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)

            Spacer(minLength: 4)

            Text(Money.compact(slice.amount))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.textSecondary)
                .lineLimit(1)
        }
    }
}

/// Categoria com ícone, valor e barra de participação.
struct CategoryRow: View {

    let slice: CategorySlice

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: slice.symbol)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 16, height: 16)
                    .background(
                        slice.color.gradient,
                        in: RoundedRectangle(cornerRadius: 4, style: .continuous)
                    )

                Text(slice.name)
                    .font(.caption2)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: 4)

                Text(Money.compact(slice.amount))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.textTertiary.opacity(0.18))
                    Capsule()
                        .fill(slice.color)
                        .frame(width: max(2, proxy.size.width * slice.share))
                }
            }
            .frame(height: 4)
        }
    }
}

/// Contagem ao vivo quando a cobrança é hoje; senão, os dias restantes.
struct CountdownLabel: View {

    let item: UpcomingItem

    var body: some View {
        if item.days == 0 {
            Text(item.dueDate, style: .timer)
                .monospacedDigit()
        } else {
            Text(Self.daysLabel(item.days))
        }
    }

    static func daysLabel(_ days: Int) -> String {
        switch days {
        case 0: L.t("widget.today")
        case 1: L.t("widget.tomorrow")
        default: L.t("widget.inDays", days)
        }
    }
}

/// Cobrança com ícone da marca, prazo e valor.
struct ChargeRow: View {

    let item: UpcomingItem
    var showsAction = true

    var body: some View {
        HStack(spacing: 8) {
            SubscriptionIconView(icon: item.icon, fallbackColor: item.color, size: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.name)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                CountdownLabel(item: item)
                    .font(.caption2)
                    .foregroundStyle(item.days <= 1 ? Color.warning : Color.textSecondary)
            }

            Spacer(minLength: 4)

            Text(Money.compact(item.cost))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)

            if showsAction {
                MarkPaidButton(item: item)
            }
        }
    }
}

/// Registra o pagamento direto do widget, sem abrir o app. Círculo com
/// contorno em vez de check cheio, para não parecer item já concluído.
struct MarkPaidButton: View {

    let item: UpcomingItem

    var body: some View {
        Button(intent: MarkPaidIntent(subscriptionID: item.id)) {
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.brand)
                .frame(width: 22, height: 22)
                .background(Color.brand.opacity(0.14), in: Circle())
        }
        .buttonStyle(.plain)
    }
}

/// Participação sem sinal ("44%").
private func shareLabel(_ share: Double) -> String {
    share.formatted(.percent.precision(.fractionLength(0)).locale(L.current))
}

// MARK: - Resumo

struct SummaryWidgetView: View {

    @Environment(\.widgetFamily) private var family
    let entry: SubCheckEntry

    var body: some View {
        content
            .widgetURL(entry.nextItem.map { WidgetLink.subscription($0.id) } ?? WidgetLink.dashboard)
            .widgetContainerBackground(accessory: isAccessory)
    }

    private var isAccessory: Bool {
        switch family {
        case .accessoryInline, .accessoryRectangular, .accessoryCircular: true
        default: false
        }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemMedium:         medium
        case .systemLarge:          large
        case .accessoryInline:      Text(L.t("widget.inline", Money.compact(entry.monthlyTotal)))
        case .accessoryRectangular: accessoryRectangular
        default:                    small
        }
    }

    // MARK: Tela inicial

    private var small: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            WidgetBadge(icon: "chart.pie.fill", title: L.t("Total mensal"))

            Text(Money.format(entry.monthlyTotal))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textPrimary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Spacer(minLength: 0)

            if !entry.categories.isEmpty {
                CategoryBar(slices: entry.categories, limit: 3)
            }

            Text(L.t("widget.summary.footer", entry.activeCount, Money.compact(entry.yearlyTotal)))
                .font(.caption2)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var medium: some View {
        HStack(alignment: .top, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                WidgetBadge(icon: "chart.pie.fill", title: L.t("Total mensal"))

                Text(Money.format(entry.monthlyTotal))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                if !entry.categories.isEmpty {
                    CategoryBar(slices: entry.categories, limit: 3)
                }

                Text(L.t("widget.summary.footer", entry.activeCount, Money.compact(entry.yearlyTotal)))
                    .font(.caption2)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(L.t("Categorias"))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)

                ForEach(entry.categories.prefix(3)) { slice in
                    CategoryLegendRow(slice: slice)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var large: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    WidgetBadge(icon: "chart.pie.fill", title: L.t("Total mensal"))

                    Text(Money.format(entry.monthlyTotal))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }

                Spacer(minLength: Spacing.sm)

                VStack(alignment: .trailing, spacing: Spacing.sm) {
                    StatPill(value: "\(entry.activeCount)", label: L.t("widget.servicesShort"))
                    StatPill(
                        value: "\(entry.dueSoonCount)",
                        label: L.t("widget.dueSoonShort"),
                        tint: entry.dueSoonCount > 0 ? .warning : .success
                    )
                }
            }

            CategoryBar(slices: entry.categories, limit: 4, height: 10)

            Text(L.t("Categorias"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.textSecondary)

            ForEach(entry.categories.prefix(4)) { slice in
                CategoryRow(slice: slice)
            }

            Spacer(minLength: 0)

            Text(L.t("widget.summary.footer", entry.activeCount, Money.compact(entry.yearlyTotal)))
                .font(.caption2)
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: Tela de bloqueio

    private var accessoryRectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(L.t("Total mensal"))
                .font(.caption2.weight(.semibold))
                .lineLimit(1)

            Text(L.t("widget.accessory.total", Money.format(entry.monthlyTotal), entry.activeCount))
                .font(.caption2)
                .lineLimit(1)

            if let next = entry.nextItem {
                Text(L.t("widget.accessory.next", next.name, CountdownLabel.daysLabel(next.days)))
                    .font(.caption2)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Próximas cobranças

struct UpcomingWidgetView: View {

    @Environment(\.widgetFamily) private var family
    let entry: SubCheckEntry

    var body: some View {
        content
            .widgetURL(entry.nextItem.map { WidgetLink.subscription($0.id) } ?? WidgetLink.dashboard)
            .widgetContainerBackground(accessory: isAccessory)
    }

    private var isAccessory: Bool {
        switch family {
        case .accessoryInline, .accessoryRectangular, .accessoryCircular: true
        default: false
        }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemMedium:         medium
        case .systemLarge:          large
        case .accessoryInline:
            if let next = entry.nextItem {
                Text(L.t("widget.accessory.next", next.name, CountdownLabel.daysLabel(next.days)))
            } else {
                Text(L.t("Nenhuma cobrança próxima"))
            }
        case .accessoryCircular:    accessoryCircular
        case .accessoryRectangular: accessoryRectangular
        default:                    small
        }
    }

    // MARK: Tela inicial

    private var small: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            WidgetBadge(icon: "calendar.badge.clock", title: L.t("Próximas cobranças"), tint: .warning)

            if let next = entry.nextItem {
                HStack(spacing: Spacing.sm) {
                    SubscriptionIconView(icon: next.icon, fallbackColor: next.color, size: 24)

                    Text(next.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                }

                CountdownLabel(item: next)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(next.days <= 1 ? Color.warning : Color.textSecondary)

                Text(Money.format(next.cost))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.textPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Spacer(minLength: 0)

                HStack {
                    Spacer(minLength: 0)
                    MarkPaidButton(item: next)
                }
            } else {
                Text(L.t("Nenhuma cobrança próxima"))
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var medium: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            WidgetBadge(icon: "calendar.badge.clock", title: L.t("Próximas cobranças"), tint: .warning)

            if entry.upcoming.isEmpty {
                Text(L.t("Nenhuma cobrança próxima"))
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            } else {
                ForEach(entry.upcoming.prefix(3)) { item in
                    ChargeRow(item: item)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var large: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top) {
                WidgetBadge(icon: "calendar.badge.clock", title: L.t("Próximas cobranças"), tint: .warning)

                Spacer(minLength: Spacing.sm)

                StatPill(
                    value: "\(entry.dueSoonCount)",
                    label: L.t("widget.dueSoonShort"),
                    tint: entry.dueSoonCount > 0 ? .warning : .success
                )
            }

            if entry.upcoming.isEmpty {
                Text(L.t("Nenhuma cobrança próxima"))
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)

                Spacer(minLength: 0)
            } else {
                ForEach(entry.upcoming) { item in
                    ChargeRow(item: item)
                }

                Spacer(minLength: 0)

                Text(L.t("widget.tapToPay"))
                    .font(.caption2)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: Tela de bloqueio

    private var accessoryRectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            if let next = entry.nextItem {
                Text(next.name)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    CountdownLabel(item: next)
                    Text("·")
                    Text(Money.compact(next.cost))
                        .fontWeight(.semibold)
                }
                .font(.caption2)
                .lineLimit(1)
            } else {
                Text(L.t("Nenhuma cobrança próxima"))
                    .font(.caption2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Anel com os dias que faltam para a próxima cobrança (janela de 30 dias).
    @ViewBuilder
    private var accessoryCircular: some View {
        if let next = entry.nextItem {
            Gauge(value: Double(min(next.days, 30)), in: 0...30) {
                Text(L.t("widget.daysShort"))
            } currentValueLabel: {
                Text(next.days == 0 ? L.t("widget.today") : "\(next.days)")
                    .font(.caption2.bold())
            }
            .gaugeStyle(.accessoryCircular)
        } else {
            Gauge(value: 0, in: 0...30) {
                Text(L.t("widget.daysShort"))
            } currentValueLabel: {
                Image(systemName: "checkmark")
            }
            .gaugeStyle(.accessoryCircular)
        }
    }
}

// MARK: - Categorias

struct CategoriesWidgetView: View {

    @Environment(\.widgetFamily) private var family
    let entry: SubCheckEntry

    var body: some View {
        content
            .widgetURL(WidgetLink.dashboard)
            .widgetContainerBackground(accessory: isAccessory)
    }

    private var isAccessory: Bool {
        switch family {
        case .accessoryInline, .accessoryRectangular, .accessoryCircular: true
        default: false
        }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemMedium:         medium
        case .systemLarge:          large
        case .accessoryRectangular: accessoryRectangular
        case .accessoryCircular:    accessoryCircular
        default:                    small
        }
    }

    // MARK: Tela inicial

    private var small: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            WidgetBadge(icon: "square.grid.2x2.fill", title: L.t("Categorias"), tint: .info)

            if let top = entry.categories.first {
                Text(top.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                Text(Money.format(top.amount))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(top.color)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text(L.t("widget.categoryShare", shareLabel(top.share)))
                    .font(.caption2)
                    .foregroundStyle(Color.textSecondary)
            } else {
                Text(L.t("Sem dados ainda"))
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer(minLength: 0)

            if entry.categories.count > 1 {
                CategoryBar(slices: entry.categories, limit: 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var medium: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            WidgetBadge(icon: "square.grid.2x2.fill", title: L.t("Categorias"), tint: .info)

            ForEach(entry.categories.prefix(4)) { slice in
                CategoryRow(slice: slice)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var large: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    WidgetBadge(icon: "square.grid.2x2.fill", title: L.t("Categorias"), tint: .info)

                    Text(Money.format(entry.monthlyTotal))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }

                Spacer(minLength: Spacing.sm)

                StatPill(value: "\(entry.categories.count)", label: L.t("Categorias"))
            }

            CategoryBar(slices: entry.categories, limit: 5, height: 10)

            ForEach(entry.categories.prefix(5)) { slice in
                CategoryRow(slice: slice)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: Tela de bloqueio

    private var accessoryRectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            if let top = entry.categories.first {
                Text(top.name)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)

                Text(L.t("widget.categoryShare", shareLabel(top.share)))
                    .font(.caption2)
                    .lineLimit(1)
            } else {
                Text(L.t("Sem dados ainda"))
                    .font(.caption2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Anel com a participação da maior categoria no gasto do mês.
    @ViewBuilder
    private var accessoryCircular: some View {
        if let top = entry.categories.first {
            Gauge(value: min(top.share, 1), in: 0...1) {
                Text(top.name)
            } currentValueLabel: {
                Text(shareLabel(top.share))
                    .font(.caption2.bold())
            }
            .gaugeStyle(.accessoryCircular)
        } else {
            Gauge(value: 0, in: 0...1) {
                Text(L.t("Categorias"))
            } currentValueLabel: {
                Image(systemName: "chart.pie")
            }
            .gaugeStyle(.accessoryCircular)
        }
    }
}
