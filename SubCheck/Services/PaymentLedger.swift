//
//  PaymentLedger.swift
//  SubCheck
//
//  Mantém o histórico de cobranças em dia. Reconstrói o passado a partir da
//  data de início + frequência e registra os pagamentos confirmados daqui
//  para frente.
//

import Foundation
import SwiftData

@MainActor
enum PaymentLedger {

    /// Teto de segurança: uma assinatura semanal antiga não pode gerar
    /// milhares de linhas se a data de início estiver errada.
    private static let maxIterations = 800

    /// Registra toda cobrança que já venceu e ainda não está no histórico.
    /// Idempotente — pode rodar a cada abertura do app.
    @discardableResult
    static func reconcile(_ subscriptions: [Subscription], in context: ModelContext) -> Int {
        let now = Date()
        var inserted = 0

        for subscription in subscriptions where !subscription.isCancelled {
            var due = subscription.lastPaymentDate ?? subscription.startDate
            guard due <= now else { continue }

            var iterations = 0
            while due <= now && iterations < maxIterations {
                context.insert(
                    PaymentRecord(from: subscription, paidAt: due, isEstimated: true)
                )
                subscription.lastPaymentDate = due
                due = subscription.advancing(due)
                iterations += 1
                inserted += 1
            }
        }

        if inserted > 0 { try? context.save() }
        return inserted
    }

    /// Marca a próxima cobrança como paga e empurra o ciclo para frente,
    /// preservando o dia original do vencimento.
    @discardableResult
    static func markPaid(
        _ subscription: Subscription,
        in context: ModelContext,
        at date: Date = Date()
    ) -> PaymentRecord {
        let record = subscription.recordPayment(at: date, in: context)
        NotificationService.shared.scheduleNotification(for: subscription)
        return record
    }

    /// Quantas cobranças já foram registradas para uma assinatura.
    static func records(for subscription: Subscription, in context: ModelContext) -> [PaymentRecord] {
        let id = subscription.id
        let descriptor = FetchDescriptor<PaymentRecord>(
            predicate: #Predicate { $0.subscriptionID == id },
            sortBy: [SortDescriptor(\.paidAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
