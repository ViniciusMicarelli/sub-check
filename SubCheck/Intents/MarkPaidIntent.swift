//
//  MarkPaidIntent.swift
//  SubCheckWidgets
//
//  Ação do widget e da Live Activity: registra a próxima cobrança como paga
//  sem abrir o app. É um `LiveActivityIntent`: o iOS executa no processo do
//  APP (e não da extensão), que enxerga o Pro, o banco e a Live Activity e
//  consegue atualizá-la. Compilado nos dois alvos, como o iOS exige.
//

import AppIntents
import SwiftData
import Foundation

struct MarkPaidIntent: LiveActivityIntent {

    static var title: LocalizedStringResource = "Registrar pagamento"
    static var description = IntentDescription("Marca a próxima cobrança desta assinatura como paga.")
    /// Não aparece em Atalhos; é usado apenas pelos botões do widget.
    static var isDiscoverable: Bool = false

    @Parameter(title: "Assinatura")
    var subscriptionID: String

    init() {}

    init(subscriptionID: UUID) {
        self.subscriptionID = subscriptionID.uuidString
    }

    init(subscriptionID: String) {
        self.subscriptionID = subscriptionID
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: subscriptionID) else { return .result() }

        let context = ModelContext(SharedModelContainer.shared)
        let descriptor = FetchDescriptor<Subscription>(
            predicate: #Predicate { $0.id == id }
        )
        let subscriptions = (try? context.fetch(descriptor)) ?? []
        guard let subscription = subscriptions.first else { return .result() }

        subscription.recordPayment(at: Date(), in: context)

        // Widgets e Live Activity precisam da nova próxima cobrança.
        let all = (try? context.fetch(FetchDescriptor<Subscription>())) ?? []
        // Primeiro mostra "Pago ✓" na própria atividade, para a pessoa ver que
        // o toque funcionou; alguns segundos depois ela passa para a próxima.
        await LiveActivityService.shared.confirmPaid(name: subscription.name, subscriptions: all)
        LiveActivityService.shared.syncAll(with: all)

        return .result()
    }
}
