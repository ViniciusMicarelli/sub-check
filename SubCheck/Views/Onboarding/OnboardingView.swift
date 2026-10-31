//
//  OnboardingView.swift
//  SubCheck
//
//  Três telas na primeira abertura: o que o app faz, o que ele avisa e o
//  que o Pro acrescenta. Aparece uma vez (`onboardingDone`).
//

import SwiftUI

struct OnboardingView: View {

    static let doneKey = "onboardingDone"

    @AppStorage(OnboardingView.doneKey) private var done = false
    @State private var page = 0

    private struct Page {
        let icon: String?
        let title: String
        let message: String
    }

    private var pages: [Page] {
        [
            Page(icon: nil,
                 title: L.t("Bem-vindo ao SubCheck"),
                 message: L.t("Veja todas as suas assinaturas num só lugar e descubra para onde vai o seu dinheiro.")),
            Page(icon: "bell.badge.fill",
                 title: L.t("Nada de cobrança surpresa"),
                 message: L.t("Avisamos antes de cada cobrança e na véspera do fim de um teste gratuito.")),
            Page(icon: "lightbulb.fill",
                 title: L.t("Economize de verdade"),
                 message: L.t("Insights, previsão de 12 meses e simulador de cancelamento mostram onde cortar."))
        ]
    }

    var body: some View {
        VStack(spacing: Spacing.xl) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                    VStack(spacing: Spacing.xl) {
                        Spacer()
                        hero(item)
                        VStack(spacing: Spacing.md) {
                            Text(item.title)
                                .font(.title.weight(.bold))
                                .foregroundStyle(Color.textPrimary)
                                .multilineTextAlignment(.center)
                            Text(item.message)
                                .font(.body)
                                .foregroundStyle(Color.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.xl)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button {
                Haptics.impact(.light)
                if page < pages.count - 1 {
                    withAnimation(.snappy) { page += 1 }
                } else {
                    done = true
                }
            } label: {
                Text(page < pages.count - 1 ? L.t("Continuar") : L.t("Começar"))
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.lg)
                    .background(
                        Color.brandGradient,
                        in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.lg)
        }
        .background(Color.appBackground)
    }

    @ViewBuilder
    private func hero(_ item: Page) -> some View {
        if let icon = item.icon {
            Image(systemName: icon)
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 128, height: 128)
                .background(
                    Color.brandGradient,
                    in: RoundedRectangle(cornerRadius: 128 * 0.225, style: .continuous)
                )
                .softShadow()
        } else {
            BrandMark(size: 128)
        }
    }
}

#Preview { OnboardingView() }
