//
//  SubCheckApp.swift
//  SubCheck
//
//  App entry point. Uses the App Group backed SwiftData container so the
//  widget extension reads the same data.
//

import SwiftUI
import SwiftData

@main
struct SubCheckApp: App {

    var body: some Scene {
        WindowGroup {
            RootView()
                .task {
                    await NotificationService.shared.requestAuthorization()
                    SampleDataSeeder.seedIfNeeded(in: SharedModelContainer.shared.mainContext)
                }
        }
        .modelContainer(SharedModelContainer.shared)
    }
}
