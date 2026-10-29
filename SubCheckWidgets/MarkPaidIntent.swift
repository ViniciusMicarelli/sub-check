//
//  MarkPaidIntent.swift
//  SubCheckWidgets
//
//  Ação do widget: registra a próxima cobrança como paga sem abrir o app.
//  Roda dentro da extensão e grava no mesmo banco do App Group.
//

import AppIntents
import SwiftData
import WidgetKit
import Foundation

struct MarkPaidIntent: AppIntent {

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
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
