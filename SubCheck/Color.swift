//
//  Color.swift
//  SubCheck
//
//  Semantic color tokens. All colors adapt to light/dark automatically
//  (except the brand palette) so the app never hard-codes a single appearance.
//

import SwiftUI

extension Color {

    // MARK: - Surfaces

    /// Page background (grouped list background).
    static let appBackground = Color(uiColor: .systemGroupedBackground)
    /// Card / row background.
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    /// Slightly elevated background (nested cards, badges).
    static let elevatedBackground = Color(uiColor: .tertiarySystemGroupedBackground)
    /// Hairline separators.
    static let hairline = Color(uiColor: .separator)

    // MARK: - Text

    static let textPrimary = Color(uiColor: .label)
    static let textSecondary = Color(uiColor: .secondaryLabel)
    static let textTertiary = Color(uiColor: .tertiaryLabel)

    // MARK: - Brand

    static let brand = Color(red: 0.33, green: 0.34, blue: 0.86)
    static let brandSecondary = Color(red: 0.61, green: 0.29, blue: 0.94)

    // MARK: - Status

    static let success = Color(red: 0.14, green: 0.72, blue: 0.45)
    static let warning = Color(red: 0.96, green: 0.65, blue: 0.13)
    static let danger = Color(red: 0.91, green: 0.26, blue: 0.29)
    static let info = Color(red: 0.16, green: 0.55, blue: 0.96)

    // MARK: - Gradients

    static let brandGradient = LinearGradient(
        colors: [brand, brandSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let successGradient = LinearGradient(
        colors: [success, Color(red: 0.20, green: 0.83, blue: 0.65)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Brand colors

/// Converte as cores de marca em hexadecimal (`RRGGBB`) usadas pelo catálogo
/// de ícones e escolhe um contraste legível para o glifo.
enum BrandColor {

    /// Cor correspondente a `hex` (aceita `RRGGBB` ou `#RRGGBB`).
    static func fill(_ hex: String) -> Color {
        let (r, g, b) = components(hex) ?? (0.5, 0.5, 0.5)
        return Color(red: r, green: g, blue: b)
    }

    /// Branco ou preto, o que tiver melhor leitura sobre `hex`.
    static func glyph(_ hex: String) -> Color {
        luminance(hex) > 0.6 ? .black : .white
    }

    private static func components(_ hex: String) -> (Double, Double, Double)? {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if value.hasPrefix("#") { value.removeFirst() }
        guard value.count == 6, let int = UInt64(value, radix: 16) else { return nil }

        return (
            Double((int >> 16) & 0xFF) / 255,
            Double((int >> 8) & 0xFF) / 255,
            Double(int & 0xFF) / 255
        )
    }

    /// Luminância percebida (0...1).
    private static func luminance(_ hex: String) -> Double {
        guard let (r, g, b) = components(hex) else { return 0 }
        return 0.299 * r + 0.587 * g + 0.114 * b
    }
}
