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
    
    var body: some Scene {
        WindowGroup {
            RouterStack()
                .environmentObject(router)
        }
        .modelContainer(for: Subscription.self)
    }
}
