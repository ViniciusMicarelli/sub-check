//
//  Theme.swift
//  SubCheck
//
//  Layout + typography primitives shared across every screen so spacing
//  and corner radii stay consistent.
//

import SwiftUI

// MARK: - Spacing

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - Corner radius

enum Radius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 16
    static let lg: CGFloat = 22
    static let pill: CGFloat = 999
}

// MARK: - Reusable surface modifiers

extension View {
    /// Standard card surface used for KPIs, list containers and info blocks.
    func cardSurface(padding: CGFloat = Spacing.lg, radius: CGFloat = Radius.md) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Color.cardBackground)
            )
    }
}

// MARK: - Shadow

extension View {
    /// Soft elevation used sparingly (hero cards, floating summaries).
    func softShadow() -> some View {
        self.shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Appearance

/// User selectable color scheme, persisted with `@AppStorage`.
enum AppearanceOption: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: L.t("appearance.system")
        case .light:  L.t("appearance.light")
        case .dark:   L.t("appearance.dark")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light:  .light
        case .dark:   .dark
        }
    }
}


// MARK: - Telas largas (iPad, dobráveis abertos, janela dividida)

enum Layout {
    /// Largura máxima de uma coluna de leitura. No iPhone nunca chega a valer.
    static let readableWidth: CGFloat = 720
}

extension View {

    /// Mantém o conteúdo numa coluna confortável e centralizada quando a tela
    /// é larga; as laterais seguem com a cor de fundo do app.
    func readableWidth(_ maxWidth: CGFloat = Layout.readableWidth) -> some View {
        self
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
            .background(Color.appBackground.ignoresSafeArea())
    }
}
