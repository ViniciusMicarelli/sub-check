//
//  SubCheckApp.swift
//  SubCheck
//
//  Created by Vinicius Micarelli on 08/10/26.
//

import SwiftUI
import SwiftData

@main
struct SubCheckApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
        }
        .modelContainer(for: Subscription.self)
    }
}
