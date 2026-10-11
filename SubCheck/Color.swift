//
//  Color.swift
//  SubCheck
//
//  Custom color extensions for the app theme
//

import SwiftUI

// MARK: - Theme Colors

// MARK: - Color Names

extension Color {
    // Custom named colors
    static let ultraDark = Color(red: 0.05, green: 0.05, blue: 0.05, opacity: 1.0)
    static let darkBackground = Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 1.0)
    static let cardBackground = Color(red: 0.12, green: 0.12, blue: 0.12, opacity: 1.0)
    static let secondarySystemGroupedBackground = Color(red: 0.18, green: 0.18, blue: 0.18, opacity: 1.0)
    static let tertiaryBackground = Color(red: 0.25, green: 0.25, blue: 0.25, opacity: 1.0)
    
    // Primary text
    static let primaryText = Color(red: 0.95, green: 0.95, blue: 0.95, opacity: 1.0)
    static let secondaryText = Color(red: 0.7, green: 0.7, blue: 0.7, opacity: 1.0)
    static let tertiaryText = Color(red: 0.5, green: 0.5, blue: 0.5, opacity: 1.0)
    
    // Accent colors
    static let accentBlue = Color(red: 0.0, green: 0.5, blue: 1.0, opacity: 1.0)
    static let accentPurple = Color(red: 0.6, green: 0.2, blue: 1.0, opacity: 1.0)
    static let accentGreen = Color(red: 0.0, green: 0.8, blue: 0.4, opacity: 1.0)
    static let accentOrange = Color(red: 1.0, green: 0.6, blue: 0.2, opacity: 1.0)
    static let accentRed = Color(red: 1.0, green: 0.2, blue: 0.2, opacity: 1.0)
    static let accentPink = Color(red: 1.0, green: 0.0, blue: 0.6, opacity: 1.0)
    static let accentTeal = Color(red: 0.0, green: 0.6, blue: 0.5, opacity: 1.0)
    static let accentLime = Color(red: 0.0, green: 1.0, blue: 0.0, opacity: 1.0)
    static let accentCyan = Color(red: 0.0, green: 1.0, blue: 1.0, opacity: 1.0)
    
    // Status colors
    static let success = Color(red: 0.0, green: 0.95, blue: 0.5, opacity: 1.0)
    static let warning = Color(red: 1.0, green: 0.8, blue: 0.0, opacity: 1.0)
    static let error = Color(red: 1.0, green: 0.2, blue: 0.2, opacity: 1.0)
    static let info = Color(red: 0.0, green: 0.5, blue: 1.0, opacity: 1.0)
    
    // Category colors for subscriptions
    static let entertainment = Color(red: 0.6, green: 0.2, blue: 1.0, opacity: 1.0) // Purple
    static let work = Color(red: 0.0, green: 0.5, blue: 1.0, opacity: 1.0)      // Blue
    static let health = Color(red: 0.0, green: 0.8, blue: 0.4, opacity: 1.0)     // Green
    static let utilities = Color(red: 1.0, green: 0.6, blue: 0.2, opacity: 1.0) // Orange
    static let defaultCategory = Color(red: 0.5, green: 0.5, blue: 0.5, opacity: 1.0) // Gray
    
    // Currency colors
    static let currencyPositive = Color(red: 0.0, green: 0.8, blue: 0.4, opacity: 1.0)
    static let currencyNegative = Color(red: 1.0, green: 0.2, blue: 0.2, opacity: 1.0)
    
    // Widget background colors
    static let widgetSystemBackground = Color(red: 0.9, green: 0.9, blue: 0.9, opacity: 0.95)
    static let widgetDarkBackground = Color(red: 0.05, green: 0.05, blue: 0.05, opacity: 0.95)
}