//
//  BudgetCard.swift
//  SubCheck
//
//  Barra de progresso do orçamento mensal no resumo. Só aparece quando o
//  usuário define um teto. Recurso Pro.
//

import SwiftUI

struct BudgetCard: View {

    let spent: Double
    let budget: Double

    private var fraction: Double {
        guard budget > 0 else { return 0 }
        return spent / budget
    }

    private var remaining: Double { budget - spent }

    private var tint: Color {
        if fraction >= 1 { return .danger }
        if fraction >= 0.8 { return .warning }
        return .success
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Label("Orçamento mensal", systemImage: "target")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text(Money.percent(fraction))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint)
                    .contentTransition(.numericText())
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.hairline.opacity(0.5))

                    Capsule()
                        .fill(tint.gradient)
                        .frame(width: proxy.size.width * min(1, fraction))
                }
            }
            .frame(height: 12)

            HStack(spacing: Spacing.sm) {
                Text(Money.format(spent))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)

                Text("de \(Money.format(budget))")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)

                Spacer(minLength: 0)

                Text(remaining >= 0
                     ? L.t("Restam %@", Money.format(remaining))
                     : L.t("Passou %@", Money.format(abs(remaining))))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
            }
        }
        .cardSurface()
        .animation(.snappy, value: fraction)
    }
}
