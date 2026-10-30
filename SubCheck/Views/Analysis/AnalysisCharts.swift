//
//  AnalysisCharts.swift
//  SubCheck
//
//  Gráficos extras da Análise: mapa de calor das cobranças, custo por dia
//  e previsão de 12 meses com o acumulado. Recebem os dados já agregados
//  por `SpendHistory`, então não conhecem SwiftData.
//

import SwiftUI
import Charts

// MARK: - Mapa de calor

/// Grade no estilo "contribuições": uma coluna por semana, uma linha por dia
/// da semana. A intensidade da cor acompanha o total cobrado no dia.
struct PaymentHeatmapCard: View {

    let totals: [DayTotal]

    private static let cell: CGFloat = 12
    private static let gap: CGFloat = 3

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Mapa de calor das cobranças")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("Últimos 12 meses")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            if totals.isEmpty {
                Text("Sem dados ainda")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: Self.gap) {
                        weekdayAxis
                        HStack(spacing: Self.gap) {
                            ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                                VStack(spacing: Self.gap) {
                                    ForEach(Array(column.enumerated()), id: \.offset) { _, day in
                                        cellView(day)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .defaultScrollAnchor(.trailing)

                legend
            }
        }
        .cardSurface()
    }

    // MARK: - Peças

    private var weekdayAxis: some View {
        VStack(spacing: Self.gap) {
            ForEach(Array(weekdayLabels.enumerated()), id: \.offset) { _, label in
                Text(label)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
                    .frame(width: Self.cell, height: Self.cell)
            }
        }
    }

    @ViewBuilder
    private func cellView(_ day: DayTotal?) -> some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(color(for: day))
            .frame(width: Self.cell, height: Self.cell)
    }

    private var legend: some View {
        HStack(spacing: Spacing.sm) {
            Text("Menos")
                .font(.caption2)
                .foregroundStyle(Color.textTertiary)

            ForEach(0..<4, id: \.self) { step in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.brand.opacity(0.2 + Double(step) * 0.25))
                    .frame(width: 10, height: 10)
            }

            Text("Mais")
                .font(.caption2)
                .foregroundStyle(Color.textTertiary)

            Spacer(minLength: 0)

            Text(L.t("Total no período") + ": " + Money.compact(total))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.textSecondary)
        }
    }

    // MARK: - Dados

    private var total: Double { totals.reduce(0) { $0 + $1.total } }

    private var maxTotal: Double { totals.map(\.total).max() ?? 0 }

    private func color(for day: DayTotal?) -> Color {
        guard let day, day.total > 0, maxTotal > 0 else {
            return Color.hairline.opacity(0.35)
        }
        let level = min(1, day.total / maxTotal)
        return Color.brand.opacity(0.2 + 0.8 * level)
    }

    /// Colunas de sete dias, alinhadas ao primeiro dia da semana do sistema.
    private var columns: [[DayTotal?]] {
        let calendar = Calendar.current
        guard let first = totals.first?.day, let last = totals.last?.day else { return [] }

        var byDay: [Date: DayTotal] = [:]
        for item in totals { byDay[calendar.startOfDay(for: item.day)] = item }

        let lastDay = calendar.startOfDay(for: last)
        guard var weekStart = calendar.dateInterval(of: .weekOfYear, for: first)?.start else { return [] }

        var result: [[DayTotal?]] = []
        while weekStart <= lastDay {
            var column: [DayTotal?] = []
            for offset in 0..<7 {
                let day = calendar.date(byAdding: .day, value: offset, to: weekStart) ?? weekStart
                let normalized = calendar.startOfDay(for: day)
                column.append(normalized > lastDay ? nil : byDay[normalized])
            }
            result.append(column)

            guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart),
                  next > weekStart else { break }
            weekStart = next
        }
        return result
    }

    /// Iniciais dos dias da semana no idioma do app, começando pelo primeiro
    /// dia da semana do calendário.
    private var weekdayLabels: [String] {
        let formatter = DateFormatter()
        formatter.locale = L.current
        formatter.dateFormat = "EEEEE"
        guard let symbols = formatter.veryShortStandaloneWeekdaySymbols, symbols.count == 7 else {
            return []
        }
        let first = Calendar.current.firstWeekday - 1
        guard (0..<7).contains(first) else { return symbols }
        return Array(symbols[first...] + symbols[..<first])
    }
}

// MARK: - Custo por dia

/// Ranking do custo diário médio de cada assinatura ativa.
struct CostPerDayCard: View {

    let rows: [CostPerDay]

    /// Quantas assinaturas aparecem antes de cortar a lista.
    private static let limit = 8

    private var visible: [CostPerDay] { Array(rows.prefix(Self.limit)) }

    private var totalPerDay: Double { rows.reduce(0) { $0 + $1.perDay } }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Custo por dia")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text(Money.format(totalPerDay) + "/" + L.t("dia"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.brand)
            }

            if visible.isEmpty {
                Text("Sem assinaturas ativas.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            } else {
                Chart(visible) { row in
                    BarMark(
                        x: .value("Por dia", row.perDay),
                        y: .value("Serviço", row.name)
                    )
                    .foregroundStyle(row.category.color.gradient)
                    .cornerRadius(5)
                    .annotation(position: .trailing, alignment: .leading) {
                        Text(Money.format(row.perDay))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine().foregroundStyle(Color.hairline.opacity(0.4))
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(Money.compact(amount))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisValueLabel(horizontalSpacing: Spacing.sm)
                    }
                }
                .frame(height: CGFloat(visible.count) * 34 + 24)
                .animation(.snappy, value: visible)
            }
        }
        .cardSurface()
    }
}

// MARK: - Previsão

/// Cobranças projetadas para os próximos 12 meses (barras) e o quanto elas
/// somam no acumulado (linha). O acumulado é reescalado para o eixo das
/// barras, já que o Swift Charts não suporta dois eixos Y independentes.
struct ForecastCard: View {

    let points: [SpendPoint]

    private var cumulative: [SpendPoint] { SpendHistory.cumulative(points) }

    private var forecastMax: Double {
        max(points.map(\.total).max() ?? 0, 1)
    }

    private var cumulativeMax: Double {
        max(cumulative.last?.total ?? 0, 1)
    }

    private var total: Double { points.reduce(0) { $0 + $1.total } }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Previsão de 12 meses")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text(Money.compact(total))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.brand)
            }

            if points.isEmpty {
                Text("Sem assinaturas ativas.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            } else {
                Chart {
                    ForEach(points) { point in
                        BarMark(
                            x: .value("Mês", point.month, unit: .month),
                            y: .value("Previsto", point.total)
                        )
                        .foregroundStyle(Color.brand.opacity(0.45))
                        .cornerRadius(4)
                    }

                    ForEach(cumulative) { point in
                        LineMark(
                            x: .value("Mês", point.month, unit: .month),
                            y: .value("Acumulado", scaled(point.total)),
                            series: .value("Série", "acumulado")
                        )
                        .interpolationMethod(.monotone)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .foregroundStyle(Color.info)

                        PointMark(
                            x: .value("Mês", point.month, unit: .month),
                            y: .value("Acumulado", scaled(point.total))
                        )
                        .symbolSize(20)
                        .foregroundStyle(Color.info)
                    }
                }
                .chartYScale(domain: 0...forecastMax)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month, count: 2)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine().foregroundStyle(Color.hairline.opacity(0.4))
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(Money.compact(amount))
                            }
                        }
                    }
                    AxisMarks(position: .trailing, values: .automatic) { value in
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(Money.compact(unscaled(amount)))
                            }
                        }
                    }
                }
                .frame(height: 220)
                .animation(.snappy, value: points)

                legend
            }
        }
        .cardSurface()
    }

    private var legend: some View {
        HStack(spacing: Spacing.lg) {
            legendItem(color: Color.brand.opacity(0.45), title: L.t("Previsto no mês"))
            legendItem(color: Color.info, title: L.t("Acumulado"))
            Spacer(minLength: 0)
        }
    }

    private func legendItem(color: Color, title: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color.textSecondary)
        }
    }

    // MARK: - Escala

    /// Leva o acumulado para o mesmo domínio das barras.
    private func scaled(_ value: Double) -> Double {
        value / cumulativeMax * forecastMax
    }

    /// Caminho inverso, para o rótulo do eixo da direita.
    private func unscaled(_ value: Double) -> Double {
        value / forecastMax * cumulativeMax
    }
}
