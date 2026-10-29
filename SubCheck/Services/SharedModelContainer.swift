//
//  SharedModelContainer.swift
//  SubCheck
//
//  Single source of truth for the SwiftData stack. The store lives inside an
//  App Group so the widget extension can read the same data as the app.
//  When the App Group is unavailable (unsigned/dev builds) it falls back to
//  the app's private store so the app still runs.
//

import Foundation
import SwiftData

enum SharedModelContainer {

    /// Must match the App Group declared in both entitlements files.
    static let appGroupID = "group.github.com-ViniciusMicarelli.SubCheck"

    static let schema = Schema([
        Subscription.self,
        DeletedSubscription.self,
        User.self,
        PaymentMethod.self
    ])

    static let shared: ModelContainer = makeContainer()

    private static func makeContainer() -> ModelContainer {
        let groupConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(appGroupID)
        )

        if let container = try? ModelContainer(for: schema, configurations: groupConfig) {
            return container
        }

        // Fallback: private store (App Group entitlement missing).
        let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: localConfig)
        } catch {
            // Last resort so the app never crashes on launch.
            let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: memoryConfig)
        }
    }
}
