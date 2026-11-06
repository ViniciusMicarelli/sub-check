//
//  PersonalizeChoices.swift
//  SubCheck
//
//  Passo "Do seu jeito" da introdução: idioma e aparência em cartões com
//  prévia, no lugar de dois seletores soltos. A escolha vale na hora, então
//  a pessoa vê a tela mudar enquanto decide.
//

import SwiftUI

struct PersonalizeChoices: View {

    @Binding var language: AppLanguage
    @Binding var appearance: AppearanceOption

    var body: some View {
        VStack(spacing: Spacing.xl) {
            group(title: L.t("Idioma"), systemImage: "globe") {
                HStack(spacing: Spacing.sm) {
                    ForEach(AppLanguage.allCases) { option in
                        LanguageCard(option: option, isSelected: language == option) {
                            select { language = option }
                        }
                    }
                }
            }

            group(title: L.t("Aparência"), systemImage: "circle.lefthalf.filled") {
                HStack(spacing: Spacing.sm) {
                    ForEach(AppearanceOption.allCases) { option in
                        AppearanceCard(option: option, isSelected: appearance == option) {
                            select { appearance = option }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: 360)
    }

    private func select(_ change: () -> Void) {
        withAnimation(Motion.snappy) { change() }
        Haptics.selection()
    }

    private func group<Content: View>(
        title: String, systemImage: String, @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textSecondary)
            content()
        }
    }
}

// MARK: - Idioma

private struct LanguageCard: View {

    let option: AppLanguage
    let isSelected: Bool
    let action: () -> Void

    private var flag: String {
        switch option {
        case .system: "🌐"
        case .ptBR:   "🇧🇷"
        case .en:     "🇺🇸"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(flag).font(.system(size: 30))
                Text(option.displayName)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 84)
            .selectableCard(isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(option.displayName))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Aparência

private struct AppearanceCard: View {

    let option: AppearanceOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                preview
                    .frame(height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                Text(option.label)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 112)
            .selectableCard(isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(option.label))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// Mini tela: barra, cartão de destaque e duas linhas, nas cores do tema.
    @ViewBuilder
    private var preview: some View {
        switch option {
        case .light: miniScreen(dark: false)
        case .dark: miniScreen(dark: true)
        case .system:
            // Metade clara, metade escura, na diagonal.
            ZStack {
                miniScreen(dark: false)
                miniScreen(dark: true)
                    .mask(
                        GeometryReader { geo in
                            Path { p in
                                p.move(to: CGPoint(x: geo.size.width, y: 0))
                                p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                                p.addLine(to: CGPoint(x: 0, y: geo.size.height))
                                p.closeSubpath()
                            }
                        }
                    )
            }
        }
    }

    private func miniScreen(dark: Bool) -> some View {
        let background = dark ? Color(red: 0.07, green: 0.07, blue: 0.10) : Color(red: 0.95, green: 0.95, blue: 0.97)
        let card = dark ? Color(red: 0.14, green: 0.14, blue: 0.19) : Color.white
        let line = dark ? Color.white.opacity(0.25) : Color.black.opacity(0.12)

        return ZStack(alignment: .topLeading) {
            background
            VStack(alignment: .leading, spacing: 5) {
                Capsule().fill(line).frame(width: 26, height: 4)
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.brandGradient)
                    .frame(height: 20)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(card)
                    .frame(height: 9)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(card)
                    .frame(width: 44, height: 9)
            }
            .padding(7)
        }
    }
}

// MARK: - Estilo comum

private extension View {

    /// Cartão selecionável: borda da marca e selo de confirmação quando escolhido.
    func selectableCard(isSelected: Bool) -> some View {
        self
            .padding(.vertical, 10)
            .background(
                Color.cardBackground,
                in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .stroke(isSelected ? Color.brand : Color.hairline, lineWidth: isSelected ? 2 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(Color.brand)
                        .background(Circle().fill(Color.cardBackground))
                        .offset(x: 6, y: -6)
                        .transition(.scale.combined(with: .opacity))
                }
            }
    }
}
