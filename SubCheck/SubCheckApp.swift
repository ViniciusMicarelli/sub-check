//
//  SubCheckApp.swift
//  SubCheck
//
//  Main app entry point with integrated router
//

import SwiftUI
import SwiftData

@main
struct SubCheckApp: App {
    @StateObject private var router = NavigationRouter()
    
    @MainActor
    var persistedModelContainer: ModelContainer {
        let schema = [Subscription.schema, Purchase.schema, DeletedSubscription.schema]
        return try! ModelContainer(schema: schema)
    }
    
    var body: some Scene {
        WindowGroup {
            RouterStack()
                .environmentObject(router)
                .modelContainer(modelContainer: persistedModelContainer)
        }
    }
}
