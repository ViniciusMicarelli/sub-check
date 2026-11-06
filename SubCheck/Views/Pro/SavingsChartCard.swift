//
//  SavingsChartCard.swift
//  SubCheck
//
//  Gráfico do simulador de cancelamento: quanto a economia vira em até 10
//  anos, com o reajuste dos preços (inflação) e, se a pessoa quiser, o
//  rendimento de investir o que sobra. Arrastar o dedo mostra cada ponto.
//

import SwiftUI
import Charts

struct SavingsChartCard: View {

    /// Gasto mensal atual e a parte que seria cancelada (na moeda base).
    let monthlyTotal: Double
    let monthlySaved: Double

    @AppStorage("savings.years") private var years = 5
    /// Em pontos percentuais (5 = 5%).
    @AppStorage("savings.inflation") private var inflationPercent = 5.0
    @AppStorage("savings.invest") private var invest = false
    @AppStorage("savings.yield") private var yieldPercent = 10.0

    @State private var scrubMonth: Double?

    private var curve: [SavingsPoint] {
        SavingsProjection.curve(
            monthlyTotal: monthlyTotal,
            monthlySaved: monthlySaved,
            years: years,
            inflation: inflationPercent / 100,
            yield: invest ? yieldPercent / 100 : 0
        )
    }

    /// Ponto exibido: o que o dedo toca ou, sem toque, o fim do período.
    private var shown: SavingsPoint? {
        if let scrubMonth { return SavingsProjection.point(atMonth: scrubMonth, in: curve) }
        return curve.last
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Quanto isso vira com o tempo")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)

            readout
            chart

            VStack(spacing: Spacing.sm) {
                HStack {
                    Text("Horizonte")
                    Spacer()
                    Text(L.t("%lld anos", years)).monospacedDigit().fontWeight(.semibold)
                }
                .font(.subheadline)
                Slider(
                    value: Binding(get: { Double(years) }, set: { years = Int($0.rounded()) }),
                    in: 1...Double(SavingsProjection.maxYears), step: 1
                )
                .tint(.brand)
                .accessibilityLabel(Text("Horizonte em anos"))

                stepperRow(title: L.t("Inflação ao ano"), value: $inflationPercent)

                Toggle("Investir a economia", isOn: $invest.animation(.snappy))
                    .font(.subheadline)
                    .tint(.brand)
                if invest {
                    stepperRow(title: L.t("Rendimento ao ano"), value: $yieldPercent)
                }
            }

            Text("Estimativa: os preços sobem pela inflação a cada ano. Não é promessa de rendimento.")
                .font(.caption2)
                .foregroundStyle(Color.textTertiary)
        }
        .cardSurface()
    }

    // MARK: Leitura

    @ViewBuilder
    private var readout: some View {
        if let point = shown {
            VStack(alignment: .leading, spacing: 2) {
                Text(point.month == 0
                     ? L.t("Hoje")
                     : L.t("Em %@", period(point.month)))
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                Text(Money.format(invest ? point.savedInvested : point.saved))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.success)
                    .contentTransition(.numericText())
                    .monospacedDigit()
                Text(L.t("economizados · sem cancelar seriam %@", Money.compact(point.spentWithoutCancelling)))
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
            .animation(.snappy, value: point.month)
        }
    }

    private func period(_ months: Int) -> String {
        let y = months / 12, m = months % 12
        if m == 0 { return L.t("%lld ano(s)", y) }
        if y == 0 { return L.t("%lld mes(es)", m) }
        return L.t("%lld ano(s) e %lld mes(es)", y, m)
    }

    // MARK: Gráfico

    private var chart: some View {
        Chart {
            ForEach(curve) { point in
                LineMark(
                    x: .value("Mês", point.month),
                    y: .value("Sem cancelar", point.spentWithoutCancelling),
                    series: .value("Série", "spent")
                )
                .foregroundStyle(Color.danger.opacity(0.8))
                .interpolationMethod(.monotone)

                AreaMark(
                    x: .value("Mês", point.month),
                    y: .value("Economia", invest ? point.savedInvested : point.saved),
                    series: .value("Série", "saved")
                )
                .foregroundStyle(Color.success.opacity(0.28))
                .interpolationMethod(.monotone)

                LineMark(
                    x: .value("Mês", point.month),
                    y: .value("Economia", invest ? point.savedInvested : point.saved),
                    series: .value("Série", "saved-line")
                )
                .foregroundStyle(Color.success)
                .interpolationMethod(.monotone)
            }

            if scrubMonth != nil, let point = shown {
                RuleMark(x: .value("Mês", Double(point.month)))
                    .foregroundStyle(Color.textTertiary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3]))
                PointMark(x: .value("Mês", Double(point.month)),
                          y: .value("Economia", invest ? point.savedInvested : point.saved))
                    .foregroundStyle(Color.success)
                    .symbolSize(70)
            }
        }
        .chartXSelection(value: $scrubMonth)
        .chartXAxis {
            AxisMarks(values: Array(stride(from: 0, through: years * 12, by: years > 5 ? 24 : 12))) { value in
                AxisGridLine().foregroundStyle(Color.hairline)
                AxisValueLabel {
                    if let m = value.as(Int.self) { Text("\(m / 12)a").font(.caption2) }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(Color.hairline)
                AxisValueLabel {
                    if let v = value.as(Double.self) { Text(Money.compact(v)).font(.caption2) }
                }
            }
        }
        .chartLegend(.hidden)
        .frame(height: 200)
        .accessibilityLabel(Text("Gráfico da economia ao longo dos anos"))
    }

    private func stepperRow(title: String, value: Binding<Double>) -> some View {
        Stepper(value: value, in: 0...30, step: 0.5) {
            HStack {
                Text(title)
                Spacer()
                Text(value.wrappedValue.formatted(.number.precision(.fractionLength(0...1))) + "%")
                    .monospacedDigit().fontWeight(.semibold)
            }
            .font(.subheadline)
        }
    }
}
