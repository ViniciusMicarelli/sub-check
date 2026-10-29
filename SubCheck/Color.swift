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
