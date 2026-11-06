//
//  ProTrialCard.swift
//  SubCheck
//
//  Convite no painel para quem ainda está no plano grátis: ativar os 7 dias de
//  Pro (a pessoa escolhe, nada liga sozinho) ou ver o que muda. Depois que o
//  teste acaba, vira um convite para desbloquear.
//

import SwiftUI

struct ProTrialCard: View {

    let state: TrialState
    let onActivate: () -> Void
    let onSeeDifferences: () -> Void
    let onUnlock: () -> Void

    private var expired: Bool { state == .expired }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.brandGradient, in: RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
                    .accessibilityHidden(true)
                Text(expired ? "Seu teste do Pro terminou" : "Experimente o Pro por 7 dias")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
            }

            Text(expired
                 ? L.t("Você continua no plano grátis. Um pagamento único libera tudo para sempre.")
                 : LiveSurface.text(
                    island: "Sem cartão e sem cobrança. Veja a Ilha Dinâmica, a Análise, o orçamento e o iCloud funcionando.",
                    noIsland: "Sem cartão e sem cobrança. Veja a Análise, o orçamento, a atividade ao vivo e o iCloud funcionando."))
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)

            HStack(spacing: Spacing.sm) {
                Button {
                    Haptics.impact(.light)
                    expired ? onUnlock() : onActivate()
                } label: {
                    Text(expired ? "Ver o Pro" : "Ativar 7 dias grátis")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm + 2)
                        .background(Color.brandGradient, in: Capsule())
                }
                .buttonStyle(PressableStyle())

                if !expired {
                    Button {
                        Haptics.impact(.light)
                        onSeeDifferences()
                    } label: {
                        Text("Ver o que muda")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.brand)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm + 2)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .stroke(Color.brand.opacity(0.35), lineWidth: 1)
        )
    }
}
