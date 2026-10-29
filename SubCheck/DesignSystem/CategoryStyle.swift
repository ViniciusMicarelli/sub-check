//
//  CategoryStyle.swift
//  SubCheck
//
//  Icon + color mapping for each subscription category. Kept out of the
//  model layer so the models stay UI-free.
//

import SwiftUI

extension CategoryType {

    /// SF Symbol shown for the category.
    var icon: String {
        switch self {
        case .finance:       "banknote.fill"
        case .subscriptions: "repeat.circle.fill"
        case .transport:     "car.fill"
        case .health:        "heart.fill"
        case .education:     "graduationcap.fill"
        case .utilities:     "bolt.fill"
        case .entertainment: "play.tv.fill"
        case .news:          "newspaper.fill"
        case .productivity:  "hammer.fill"
        case .miscellaneous: "square.grid.2x2.fill"
        }
    }

    /// Distinct accent color per category.
    var color: Color {
        switch self {
        case .finance:       Color(red: 0.16, green: 0.72, blue: 0.48)
        case .subscriptions: Color(red: 0.33, green: 0.34, blue: 0.86)
        case .transport:     Color(red: 0.20, green: 0.60, blue: 0.94)
        case .health:        Color(red: 0.93, green: 0.30, blue: 0.45)
        case .education:     Color(red: 0.55, green: 0.36, blue: 0.96)
        case .utilities:     Color(red: 0.96, green: 0.62, blue: 0.13)
        case .entertainment: Color(red: 0.61, green: 0.29, blue: 0.94)
        case .news:          Color(red: 0.75, green: 0.35, blue: 0.20)
        case .productivity:  Color(red: 0.10, green: 0.66, blue: 0.62)
        case .miscellaneous: Color(red: 0.52, green: 0.55, blue: 0.60)
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.65)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension Subscription {
    /// Styling helpers derived from the stored category string.
    var categoryIcon: String { categoryType.icon }
    var categoryColor: Color { categoryType.color }
}
