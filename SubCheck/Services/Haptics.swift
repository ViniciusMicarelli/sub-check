//
//  Haptics.swift
//  SubCheck
//
//  Small helper for imperative haptic feedback.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

enum Haptics {

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: style).impactOccurred()
        #endif
    }

    static func success() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    static func warning() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
    }
}
