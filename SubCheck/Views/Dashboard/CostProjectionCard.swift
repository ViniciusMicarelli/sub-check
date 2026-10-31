//
//  CostProjectionCard.swift
//  SubCheck
//
//  "Quanto isso vira?": arraste o horizonte (1 a 10 anos) e veja o total
//  que as assinaturas atuais custam, com ou sem reajuste anual. Interativo
//  de ponta a ponta: slider, toque nas barras, chave de reajuste e háptico.
//

import SwiftUI

struct CostProjectionCard: View {

    /// Gasto mensal atual, na moeda base.
    let monthly: Double

    @State private var years = 5.0
    @State private var withInflation = false

    /// Reajuste anual típico das mensalidades. É uma hipótese, não um dado.
    private let annualIncrease = 0.08
    private let maxYears = 10

    private var selected: Int { Int(years.rounded()) }

    /// Total acumulado em `n` anos.
    private func total(years n: Int) -> Double {
        let yearly = monthly * 12
        guard withInflation else { return yearly * Double(n) }
        return (0..<n).reduce(0) { $0 + yearly * pow(1 + annualIncrease, Double($1)) }
    }

    private var maxTotal: Double { max(total(years: maxYears), 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Label("Quanto isso vira?", systemImage: "hourglass.bottomhalf.filled")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text(L.t("%lld anos", selected))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.brand)
                    .contentTransition(.numericText())
            }

            Text(Money.compact(total(years: selected)))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textPrimary)
                .contentTransition(.numericText(value: total(years: selected)))
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            bars

            Slider(value: $years, in: 1...Double(maxYears), step: 1)
                .tint(.brand)

            Toggle(isOn: $withInflation) {
                Text(L.t("Com reajuste de %@ ao ano", Money.percentPlain(annualIncrease)))
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            .tint(.brand)
        }
        .cardSurface()
        .animation(Motion.snappy, value: years)
        .animation(Motion.snappy, value: withInflation)
        .sensoryFeedback(.selection, trigger: selected)
        .sensoryFeedback(.impact(weight: .light), trigger: withInflation)
    }

    /// Uma barra por ano; as do horizonte escolhido ficam acesas e tocar
    /// numa barra move o horizonte até ela.
    private var bars: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(1...maxYears, id: \.self) { year in
                let active = year <= selected
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(active ? AnyShapeStyle(Color.brandGradient) : AnyShapeStyle(Color.elevatedBackground))
                    .frame(height: max(8, 72 * total(years: year) / maxTotal))
                    .frame(maxWidth: .infinity)
                    .scaleEffect(y: year == selected ? 1.06 : 1, anchor: .bottom)
                    .contentShape(Rectangle())
                    .onTapGesture { years = Double(year) }
                    .accessibilityLabel(L.t("%lld anos", year))
            }
        }
        .frame(height: 72, alignment: .bottom)
    }
}
