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
                let record = PaymentRecord(from: subscription, paidAt: due, isEstimated: true)
                record.stampRate(using: .shared)
                context.insert(record)
                subscription.lastPaymentDate = due
                due = subscription.advancing(due)
                iterations += 1
                inserted += 1
            }
        }

        if inserted > 0 { context.saveReporting() }
        return inserted
    }

    /// Remove cobranças repetidas (mesma assinatura e mesmo dia). Com iCloud,
    /// dois aparelhos podem reconstruir o mesmo histórico antes de sincronizar.
    /// Mantém o registro confirmado pelo usuário em vez do estimado.
    @discardableResult
    static func removeDuplicates(in context: ModelContext) -> Int {
        let records = (try? context.fetch(FetchDescriptor<PaymentRecord>())) ?? []
        let calendar = Calendar.current

        var kept: [String: PaymentRecord] = [:]
        var removed = 0
        for record in records {
            let day = calendar.startOfDay(for: record.paidAt).timeIntervalSince1970
            let key = "\(record.subscriptionID.uuidString)-\(day)"
            if let existing = kept[key] {
                let loser = existing.isEstimated && !record.isEstimated ? existing : record
                if loser === existing { kept[key] = record }
                context.delete(loser)
                removed += 1
            } else {
                kept[key] = record
            }
        }
        if removed > 0 { context.saveReporting() }
        return removed
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

        // A próxima cobrança mudou: widgets e Live Activity precisam seguir.
        let all = (try? context.fetch(FetchDescriptor<Subscription>())) ?? []
        LiveActivityService.shared.syncAll(with: all)
        BudgetService.evaluate(all)
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
