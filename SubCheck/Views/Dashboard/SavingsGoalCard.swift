//
//  SavingsGoalCard.swift
//  SubCheck
//
//  Meta de economia mensal: o anel enche conforme os serviços cancelados
//  tiram dinheiro do gasto mensal. Tocar abre o ajuste da meta, com o anel
//  reagindo ao slider em tempo real.
//

import SwiftUI

enum SavingsGoal {
    static let amountKey = "savingsGoal"
}

struct SavingsGoalCard: View {

    /// Quanto os cancelamentos já economizam por mês (moeda base).
    let saved: Double
    /// Gasto mensal atual, que limita o valor máximo da meta.
    let monthly: Double

    @AppStorage(SavingsGoal.amountKey) private var goal = 0.0
    @State private var showEditor = false
    @State private var celebrate = 0

    private var fraction: Double {
        goal > 0 ? min(saved / goal, 1) : 0
    }

    var body: some View {
        Button {
            Haptics.impact(.light)
            showEditor = true
        } label: {
            HStack(spacing: Spacing.lg) {
                SavingsRing(fraction: fraction, lineWidth: 10)
                    .frame(width: 72, height: 72)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Meta de economia")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)

                    if goal > 0 {
                        Text(L.t("%@ de %@ por mês", Money.format(saved), Money.format(goal)))
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                            .contentTransition(.numericText())
                        Text(fraction >= 1 ? L.t("Meta batida. Parabéns!") : L.t("Cancele o que não usa para chegar lá."))
                            .font(.caption)
                            .foregroundStyle(fraction >= 1 ? Color.success : Color.textTertiary)
                    } else {
                        Text("Defina quanto quer economizar por mês e acompanhe aqui.")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.textTertiary)
            }
            .cardSurface()
        }
        .buttonStyle(PressableStyle())
        .successBurst(trigger: celebrate)
        .onChange(of: fraction) { old, new in
            if old < 1, new >= 1, goal > 0 {
                Haptics.success()
                celebrate += 1
            }
        }
        .sheet(isPresented: $showEditor) {
            SavingsGoalEditor(saved: saved, maxGoal: max(monthly + saved, 100))
                .presentationDetents([.height(380)])
        }
    }
}

// MARK: - Anel

/// Anel de progresso que anima o preenchimento e mostra o percentual.
struct SavingsRing: View {

    let fraction: Double
    var lineWidth: CGFloat = 10

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.elevatedBackground, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(
                    fraction >= 1 ? AnyShapeStyle(Color.successGradient) : AnyShapeStyle(Color.brandGradient),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text(Money.percentPlain(fraction))
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Color.textPrimary)
                .contentTransition(.numericText(value: fraction))
        }
        .animation(Motion.snappy, value: fraction)
    }
}

// MARK: - Editor

struct SavingsGoalEditor: View {

    let saved: Double
    let maxGoal: Double

    @AppStorage(SavingsGoal.amountKey) private var goal = 0.0
    @Environment(\.dismiss) private var dismiss

    private var fraction: Double { goal > 0 ? min(saved / goal, 1) : 0 }

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Text("Meta de economia")
                .font(.headline)
                .padding(.top, Spacing.lg)

            SavingsRing(fraction: fraction, lineWidth: 14)
                .frame(width: 112, height: 112)

            VStack(spacing: Spacing.sm) {
                Text(goal > 0 ? L.t("%@ por mês", Money.format(goal)) : L.t("Sem meta"))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.textPrimary)
                    .contentTransition(.numericText(value: goal))

                Slider(value: $goal, in: 0...maxGoal, step: 5)
                    .tint(.brand)
                    .sensoryFeedback(.selection, trigger: Int(goal / 5))
            }
            .padding(.horizontal, Spacing.xl)

            Button {
                Haptics.impact(.light)
                dismiss()
            } label: {
                Text("Pronto")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.lg)
                    .background(
                        Color.brandGradient,
                        in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    )
            }
            .buttonStyle(PressableStyle())
            .padding(.horizontal, Spacing.xl)

            Spacer(minLength: 0)
        }
        .animation(Motion.snappy, value: goal)
        .background(Color.appBackground)
    }
}
