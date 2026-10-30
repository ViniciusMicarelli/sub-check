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

                    let context = SharedModelContainer.shared.mainContext
                    SampleDataSeeder.seedIfNeeded(in: context)

                    // Reconstrói o histórico de cobranças a partir do início de cada assinatura.
                    let subscriptions = (try? context.fetch(FetchDescriptor<Subscription>())) ?? []
                    PaymentLedger.reconcile(subscriptions, in: context)

                    // Widgets e Live Activity sempre alinhados na abertura.
                    LiveActivityService.shared.syncAll(with: subscriptions)
                    BudgetService.evaluate(subscriptions)

                    await CurrencyService.shared.refreshIfStale()
                }
        }
        .modelContainer(SharedModelContainer.shared)
    }
}
