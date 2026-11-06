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
        LiveActivityAutoEnd.install()
    }

    /// Em builds de depuração, `-seedSampleData` evita o diálogo do sistema
    /// para os testes visuais no simulador.
    private static var skipsNotificationPrompt: Bool {
        #if DEBUG
        CommandLine.arguments.contains("-seedSampleData")
        #else
        false
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .task {
                    // Durante a introdução o app ainda não explicou nada: a
                    // permissão é pedida só depois que ela termina.
                    // Roda à parte: se esperasse a resposta, todo o resto da
                    // abertura (histórico, Ilha, cotações) ficaria parado até o
                    // usuário tocar em "Permitir".
                    if UserDefaults.standard.bool(forKey: OnboardingView.doneKey),
                       !Self.skipsNotificationPrompt {
                        Task { await NotificationService.shared.requestAuthorization() }
                    }

                    let context = SharedModelContainer.shared.mainContext

                    #if DEBUG
                    // `-seedSampleData` ao lançar no simulador: abre já com dados.
                    if CommandLine.arguments.contains("-seedSampleData") {
                        SampleDataSeeder.seedIfNeeded(in: context)
                    }
                    #endif

                    // Reconstrói o histórico de cobranças a partir do início de cada assinatura.
                    let subscriptions = (try? context.fetch(FetchDescriptor<Subscription>())) ?? []
                    PaymentLedger.removeDuplicates(in: context)
                    PaymentLedger.reconcile(subscriptions, in: context)

                    // Contas da casa: dedupe do iCloud, linha do mês e avisos.
                    BillLedger.removeDuplicates(in: context)
                    let bills = (try? context.fetch(FetchDescriptor<Bill>())) ?? []
                    BillLedger.ensureEntries(for: bills, in: context)
                    BillLedger.rescheduleNotifications(in: context)

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
