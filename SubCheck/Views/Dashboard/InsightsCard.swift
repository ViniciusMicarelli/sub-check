//
//  InsightsCard.swift
//  SubCheck
//
//  Dicas automáticas no resumo. Com Pro mostra todas; sem Pro mostra uma e
//  um convite para ver o restante.
//

import SwiftUI

struct InsightsCard: View {

    let insights: [Insight]
    let hasPro: Bool
    /// Chamado quando o usuário sem Pro toca para ver o restante.
    var onUnlock: () -> Void

    private var visible: [Insight] {
        hasPro ? insights : Array(insights.prefix(1))
    }

    private var hiddenCount: Int { max(0, insights.count - visible.count) }

    var body: some View {
        if !insights.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Label("Insights", systemImage: "lightbulb.fill")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    if !hasPro {
                        Label(L.t("Pro"), systemImage: "lock.fill")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.warning)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(Color.warning.opacity(0.15), in: Capsule())
                    }
                }

                ForEach(visible) { insight in
                    row(insight)
                }

                if hiddenCount > 0 {
                    Button {
                        Haptics.impact(.light)
                        onUnlock()
                    } label: {
                        Text(L.t("Ver mais %lld insights com o Pro", hiddenCount))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.brand)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(
                                Color.brand.opacity(0.12),
                                in: RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .cardSurface()
        }
    }

    private func row(_ insight: Insight) -> some View {
        let tint = color(for: insight.tone)
        return HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: insight.icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(
                    tint.opacity(0.15),
                    in: RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(insight.detail)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private func color(for tone: Insight.Tone) -> Color {
        switch tone {
        case .info: .info
        case .warning: .warning
        case .success: .success
        }
    }
}
