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

    init() {
        NotificationActionHandler.install()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .task {
                    // Durante a introdução o app ainda não explicou nada: a
                    // permissão é pedida só depois que ela termina.
                    if UserDefaults.standard.bool(forKey: OnboardingView.doneKey) {
                        await NotificationService.shared.requestAuthorization()
                    }

                    let context = SharedModelContainer.shared.mainContext

                    // Reconstrói o histórico de cobranças a partir do início de cada assinatura.
                    let subscriptions = (try? context.fetch(FetchDescriptor<Subscription>())) ?? []
                    PaymentLedger.removeDuplicates(in: context)
                    PaymentLedger.reconcile(subscriptions, in: context)

                    // Assinaturas vindas de outro aparelho (iCloud) ainda não
                    // têm lembrete neste; reagendar é idempotente.
                    for subscription in subscriptions where !subscription.isCancelled {
                        NotificationService.shared.scheduleNotification(for: subscription)
                    }

                    // Widgets e Live Activity sempre alinhados na abertura.
                    LiveActivityService.shared.syncAll(with: subscriptions)
                    BudgetService.evaluate(subscriptions)

                    await CurrencyService.shared.refreshIfStale()
                }
        }
        .modelContainer(SharedModelContainer.shared)
    }
}
