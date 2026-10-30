//
//  AnalysisView.swift
//  SubCheck
//
//  Evolução dos gastos: linha do tempo, comparação de períodos, progressão
//  e quebra por categoria. Lê sempre de `PaymentRecord`, já convertido para
//  a moeda base.
//

import SwiftUI
import SwiftData
import Charts

struct AnalysisView: View {

    @Query(sort: \PaymentRecord.paidAt, order: .reverse)
    private var records: [PaymentRecord]

    @Query(sort: \Subscription.cost, order: .reverse)
    private var subscriptions: [Subscription]

    /// Categoria usada para filtrar todas as séries. `nil` = todas.
    @State private var selectedCategory: CategoryType?
    /// Mês apontado no gráfico de evolução.
    @State private var selectedMonth: Date?

    // MARK: - Dados

    private var filtered: [PaymentRecord] {
        guard let selectedCategory else { return records }
        return records.filter { $0.categoryType == selectedCategory }
    }

    private var timeline: [SpendPoint] {
        SpendHistory.monthlyTotals(filtered, months: 12)
    }

    private var monthInterval: DateInterval {
        SpendHistory.monthInterval(containing: Date())
    }

    private var previousMonthInterval: DateInterval {
        let date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return SpendHistory.monthInterval(containing: date)
    }

    private var yearInterval: DateInterval {
        SpendHistory.yearInterval(containing: Date())
    }

    private var previousYearInterval: DateInterval {
        let date = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        return SpendHistory.yearInterval(containing: date)
    }

    private var thisMonthTotal: Double { SpendHistory.total(filtered, in: monthInterval) }
    private var lastMonthTotal: Double { SpendHistory.total(filtered, in: previousMonthInterval) }
    private var thisYearTotal: Double { SpendHistory.total(filtered, in: yearInterval) }
    private var lastYearTotal: Double { SpendHistory.total(filtered, in: previousYearInterval) }

    private var monthChange: Double? {
        SpendHistory.change(current: thisMonthTotal, previous: lastMonthTotal)
    }

    private var yearChange: Double? {
        SpendHistory.change(current: thisYearTotal, previous: lastYearTotal)
    }

    private var categorySeries: [CategorySeriesPoint] {
        SpendHistory.monthlyByCategory(filtered, months: 6).map {
            CategorySeriesPoint(month: $0.month, category: $0.category, total: $0.total)
        }
    }

    /// Categorias com dados no período (ou só a filtrada).
    private var visibleCategories: [CategoryType] {
        if let selectedCategory { return [selectedCategory] }
        let present = Set(categorySeries.map(\.category))
        return CategoryType.allCases.filter { present.contains($0) }
    }

    private var availableCategories: [CategoryType] {
        Array(Set(records.map(\.categoryType)))
            .sorted { $0.displayName < $1.displayName }
    }

    private var progression: [ProgressRow] { ProgressRow.series(from: timeline) }

    /// Cobranças projetadas para os próximos 12 meses.
    private var forecast: [SpendPoint] { SpendHistory.forecast(subscriptions, months: 12) }

    /// Custo diário médio por assinatura ativa.
    private var costPerDay: [CostPerDay] { SpendHistory.costPerDay(subscriptions) }

    /// Total cobrado por dia, para a grade do mapa de calor.
    private var dailyTotals: [DayTotal] { SpendHistory.dailyTotals(filtered) }

    private var hasEstimated: Bool { records.contains(where: \.isEstimated) }

    // MARK: - Tela

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                if records.isEmpty {
                    EmptyStateView(
                        icon: "chart.bar.xaxis",
                        title: L.t("Sem histórico ainda"),
                        message: L.t("As cobranças aparecem aqui conforme forem registradas.")
                    )
                    .cardSurface()
                } else {
                    filterBar
                    comparisonSection
                    timelineCard
                    forecastCard
                    heatmapCard
                    costPerDayCard
                    progressionCard
                    categoryCard

                    if hasEstimated { estimatedNote }
                }
            }
            .padding(Spacing.lg)
        }
        .background(Color.appBackground)
        .navigationTitle("Análise")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.snappy, value: selectedCategory)
    }

    // MARK: - Filtro

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                categoryChip(title: L.t("Todos"), category: nil)

                ForEach(availableCategories, id: \.self) { category in
                    categoryChip(title: category.displayName, category: category)
                }
            }
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 2)
        }
    }

    private func categoryChip(title: String, category: CategoryType?) -> some View {
        let isSelected = selectedCategory == category
        let tint = category?.color ?? .brand

        return Button {
            Haptics.impact(.light)
            withAnimation(.snappy) { selectedCategory = category }
        } label: {
            HStack(spacing: 6) {
                if let category {
                    Image(systemName: category.icon)
                }
                Text(title)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(isSelected ? Color.white : Color.textPrimary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background {
                if isSelected {
                    Capsule().fill(tint.gradient)
                } else {
                    Capsule().fill(Color.cardBackground)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Comparação de períodos

    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Comparar períodos")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: Spacing.md),
                          GridItem(.flexible(), spacing: Spacing.md)],
                spacing: Spacing.md
            ) {
                MetricCard(
                    title: L.t("Este mês"),
                    value: Money.compact(thisMonthTotal),
                    icon: "calendar",
                    tint: changeTint(monthChange),
                    subtitle: changeSubtitle(monthChange, baseline: "vs. mês anterior")
                )

                MetricCard(
                    title: L.t("Este ano"),
                    value: Money.compact(thisYearTotal),
                    icon: "calendar.badge.clock",
                    tint: changeTint(yearChange),
                    subtitle: changeSubtitle(yearChange, baseline: "vs. ano anterior")
                )
            }
        }
    }

    private func changeTint(_ change: Double?) -> Color {
        guard let change else { return .textSecondary }
        if change > 0.001 { return .danger }
        if change < -0.001 { return .success }
        return .textSecondary
    }

    private func changeSubtitle(_ change: Double?, baseline: String) -> String {
        guard let change else { return L.t("sem base de comparação") }
        return "\(L.t(baseline)) \(Money.percent(change))"
    }

    // MARK: - Evolução

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Evolução dos gastos")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("Últimos 12 meses")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Chart {
                ForEach(timeline) { point in
                    AreaMark(
                        x: .value("Mês", point.month, unit: .month),
                        y: .value("Total", point.total)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.brand.opacity(0.35), Color.brand.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Mês", point.month, unit: .month),
                        y: .value("Total", point.total)
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .foregroundStyle(Color.brand)
                }

                if let highlighted {
                    RuleMark(x: .value("Mês", highlighted.month, unit: .month))
                        .foregroundStyle(Color.textTertiary.opacity(0.4))
                        .zIndex(-1)
                        .annotation(
                            position: .top,
                            spacing: 0,
                            overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                        ) {
                            tooltip(highlighted)
                        }
                }
            }
            .chartXSelection(value: $selectedMonth)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month, count: 2)) { _ in
                    AxisGridLine().foregroundStyle(Color.hairline.opacity(0.4))
                    AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine().foregroundStyle(Color.hairline.opacity(0.4))
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(Money.compact(amount))
                        }
                    }
                }
            }
            .frame(height: 220)
            .animation(.snappy, value: timeline)
        }
        .cardSurface()
    }

    /// Mês mais próximo do ponto apontado no gráfico.
    private var highlighted: SpendPoint? {
        guard let selectedMonth else { return nil }
        return timeline.min {
            abs($0.month.timeIntervalSince(selectedMonth)) < abs($1.month.timeIntervalSince(selectedMonth))
        }
    }

    private func tooltip(_ point: SpendPoint) -> some View {
        VStack(spacing: 2) {
            Text(point.label)
                .font(.caption2)
                .foregroundStyle(Color.textSecondary)
            Text(Money.compact(point.total))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
            Text("\(L.t("Cobranças")): \(point.count)")
                .font(.caption2)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            Color.elevatedBackground,
            in: RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
        )
    }

    // MARK: - Gráficos extras

    private var forecastCard: some View {
        ForecastCard(points: forecast)
    }

    private var heatmapCard: some View {
        PaymentHeatmapCard(totals: dailyTotals)
    }

    private var costPerDayCard: some View {
        CostPerDayCard(rows: costPerDay)
    }

    // MARK: - Progressão

    private var progressionCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Progressão")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                ForEach(Array(progression.enumerated()), id: \.element.id) { index, row in
                    HStack(spacing: Spacing.md) {
                        Text(row.point.label)
                            .font(.subheadline)
                            .foregroundStyle(Color.textPrimary)

                        Spacer(minLength: 0)

                        Text(Money.compact(row.point.total))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.textPrimary)
                            .contentTransition(.numericText())

                        changeBadge(row.change)
                            .frame(width: 68, alignment: .trailing)
                    }
                    .padding(.vertical, Spacing.sm)

                    if index < progression.count - 1 {
                        Divider().overlay(Color.hairline)
                    }
                }
            }
        }
        .cardSurface()
    }

    @ViewBuilder
    private func changeBadge(_ change: Double?) -> some View {
        if let change {
            HStack(spacing: 3) {
                Image(systemName: change > 0 ? "arrow.up.right" : (change < 0 ? "arrow.down.right" : "arrow.right"))
                    .font(.caption2.weight(.bold))
                Text(Money.percent(change))
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(changeTint(change))
        } else {
            Text("—")
                .font(.caption2)
                .foregroundStyle(Color.textTertiary)
        }
    }

    // MARK: - Categoria ao longo do tempo

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Gastos por categoria ao longo do tempo")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)

            if categorySeries.isEmpty {
                Text("Sem dados ainda")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            } else {
                Chart(categorySeries) { item in
                    BarMark(
                        x: .value("Mês", item.month, unit: .month),
                        y: .value("Total", item.total)
                    )
                    .foregroundStyle(by: .value("Categoria", item.category.displayName))
                    .cornerRadius(4)
                }
                .chartForegroundStyleScale(
                    domain: visibleCategories.map(\.displayName),
                    range: visibleCategories.map(\.color)
                )
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine().foregroundStyle(Color.hairline.opacity(0.4))
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(Money.compact(amount))
                            }
                        }
                    }
                }
                .frame(height: 210)
                .animation(.snappy, value: categorySeries)
            }
        }
        .cardSurface()
    }

    private var estimatedNote: some View {
        Label(L.t("Estimado a partir do início e da frequência da assinatura."), systemImage: "info.circle")
            .font(.caption)
            .foregroundStyle(Color.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Séries

private struct CategorySeriesPoint: Identifiable, Hashable {
    let month: Date
    let category: CategoryType
    let total: Double

    var id: String { "\(month.timeIntervalSince1970)-\(category.rawValue)" }
}

private struct ProgressRow: Identifiable {
    let point: SpendPoint
    let change: Double?

    var id: Date { point.month }

    /// Últimos seis meses com a variação em relação ao mês anterior.
    static func series(from timeline: [SpendPoint]) -> [ProgressRow] {
        var rows: [ProgressRow] = []
        var previous: Double?

        for point in timeline.suffix(6) {
            let change = previous.flatMap {
                SpendHistory.change(current: point.total, previous: $0)
            }
            rows.append(ProgressRow(point: point, change: change))
            previous = point.total
        }

        return rows.reversed()
    }
}
