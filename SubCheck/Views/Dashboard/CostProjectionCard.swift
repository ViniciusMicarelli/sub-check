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
    /// Reajuste anual em %, escolhido por quem usa (é uma hipótese, não um dado).
    @AppStorage("projectionRatePercent") private var ratePercent = 8.0
    @FocusState private var rateFocused: Bool
    private let maxYears = 10

    private var annualIncrease: Double { CostProjection.clamp(ratePercent / 100) }

    private var selected: Int { Int(years.rounded()) }

    /// Total acumulado em `n` anos.
    private func total(years n: Int) -> Double {
        CostProjection.total(monthly: monthly, years: n, annualRate: withInflation ? annualIncrease : 0)
    }

    /// Quanto o reajuste soma ao total do horizonte escolhido.
    private var inflationExtra: Double {
        CostProjection.total(monthly: monthly, years: selected, annualRate: annualIncrease)
            - CostProjection.total(monthly: monthly, years: selected, annualRate: 0)
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
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .contentTransition(.numericText(value: total(years: selected)))
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            bars

            Slider(value: $years, in: 1...Double(maxYears), step: 1)
                .tint(.brand)

            Toggle(isOn: $withInflation) {
                Text("Considerar reajuste anual")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            .tint(.brand)

            if withInflation { rateControls }
        }
        .cardSurface()
        .animation(Motion.snappy, value: years)
        .animation(Motion.snappy, value: withInflation)
        .animation(Motion.snappy, value: ratePercent)
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

    // MARK: - Reajuste

    private var rateControls: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Text("Reajuste ao ano")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                TextField("0", value: $ratePercent, format: .number.precision(.fractionLength(0...1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .focused($rateFocused)
                    .frame(width: 56)
                    .padding(.vertical, 6)
                    .padding(.horizontal, Spacing.sm)
                    .background(Color.elevatedBackground, in: RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
                    .onChange(of: ratePercent) { _, newValue in
                        let clamped = CostProjection.clamp(newValue / 100) * 100
                        if clamped != newValue { ratePercent = clamped }
                    }
                Text("%").font(.subheadline.weight(.semibold)).foregroundStyle(Color.textPrimary)
            }

            Slider(value: $ratePercent, in: 0...30, step: 0.5)
                .tint(.brand)

            HStack(spacing: Spacing.sm) {
                ForEach([4.0, 8.0, 12.0], id: \.self) { preset in
                    Button {
                        rateFocused = false
                        ratePercent = preset
                    } label: {
                        Text("\(Int(preset))%")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, 6)
                            .background(
                                (ratePercent == preset ? Color.brand : Color.elevatedBackground),
                                in: Capsule()
                            )
                            .foregroundStyle(ratePercent == preset ? Color.white : Color.textPrimary)
                    }
                    .buttonStyle(PressableStyle())
                }
                Spacer()
            }

            Text(L.t("O reajuste soma %@ em %lld anos.", Money.compact(inflationExtra), selected))
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}
