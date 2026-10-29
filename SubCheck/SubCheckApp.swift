//
//  SubCheckApp.swift
//  SubCheck
//
//  App entry point. Uses the App Group backed SwiftData container so the
//  widget extension reads the same data.
//

import SwiftUI
import SwiftData
import WidgetKit

@main
struct SubCheckApp: App {

    var body: some Scene {
        WindowGroup {
            RootView()
                .task {
                    await NotificationService.shared.requestAuthorization()

                    let context = SharedModelContainer.shared.mainContext
                    SampleDataSeeder.seedIfNeeded(in: context)

                    // Reconstrói o histórico de cobranças a partir do início de cada assinatura.
                    let subscriptions = (try? context.fetch(FetchDescriptor<Subscription>())) ?? []
                    if PaymentLedger.reconcile(subscriptions, in: context) > 0 {
                        WidgetCenter.shared.reloadAllTimelines()
                    }

                    await CurrencyService.shared.refreshIfStale()
                }
        }
        .modelContainer(SharedModelContainer.shared)
    }
}
