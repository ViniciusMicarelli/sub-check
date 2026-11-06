//
//  NotificationActionHandler.swift
//  SubCheck
//
//  Responde aos botões da notificação de cobrança sem abrir o app:
//  "Marcar como pago" registra o pagamento e "Lembrar amanhã" repete o aviso.
//

import Foundation
import SwiftData
import UserNotifications

final class NotificationActionHandler: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationActionHandler()

    /// Chamado uma vez, na abertura do app.
    @MainActor
    static func install() {
        UNUserNotificationCenter.current().delegate = shared
        NotificationService.shared.registerCategories()
    }

    /// Mostra o aviso também com o app aberto.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let content = response.notification.request.content
        let idString = content.userInfo[NotificationService.subscriptionIDKey] as? String

        switch response.actionIdentifier {
        case NotificationService.markPaidAction:
            guard let idString else { return }
            await MainActor.run { Self.markPaid(idString) }
        case NotificationService.billEnterAction:
            if let raw = content.userInfo[NotificationService.billIDKey] as? String, let id = UUID(uuidString: raw) {
                await MainActor.run { AppRouter.shared.openBill(id) }
            }
        case NotificationService.billSnoozeAction:
            if let raw = content.userInfo[NotificationService.billIDKey] as? String {
                await MainActor.run { NotificationService.shared.snoozeBill(content, billID: raw) }
            }
        case NotificationService.billMarkPaidAction:
            if let raw = content.userInfo[NotificationService.billIDKey] as? String, let id = UUID(uuidString: raw) {
                await MainActor.run {
                    // Conta de valor fixo: marca com o valor combinado. Sem valor,
                    // abre a tela para digitar.
                    if !Self.markBillPaid(id) { AppRouter.shared.openBill(id) }
                }
            }
        case UNNotificationDefaultActionIdentifier:
            if let raw = content.userInfo[NotificationService.billIDKey] as? String,
               let id = UUID(uuidString: raw) {
                await MainActor.run { AppRouter.shared.openBill(id) }
            }
        case NotificationService.snoozeAction:
            let id = idString ?? response.notification.request.identifier
            await MainActor.run { NotificationService.shared.snooze(content, id: id) }
        default:
            break
        }
    }

    /// Marca a conta pendente como paga com o valor fixo. `false` se não deu.
    @MainActor
    private static func markBillPaid(_ id: UUID) -> Bool {
        let context = SharedModelContainer.shared.mainContext
        let billDescriptor = FetchDescriptor<Bill>(predicate: #Predicate { $0.id == id })
        let entryDescriptor = FetchDescriptor<BillEntry>(
            predicate: #Predicate { $0.billID == id && !$0.isPaid && !$0.isSkipped },
            sortBy: [SortDescriptor(\.dueDate, order: .reverse)]
        )
        guard let bill = try? context.fetch(billDescriptor).first,
              let entry = try? context.fetch(entryDescriptor).first else { return false }
        let amount = entry.amount > 0 ? entry.amount : bill.expectedAmount
        guard amount > 0 else { return false }
        BillLedger.record(entry, amount: amount, paid: true, in: context)
        BillLedger.refreshSurfaces(in: context)
        return true
    }

    @MainActor
    private static func markPaid(_ idString: String) {
        guard let id = UUID(uuidString: idString) else { return }
        let context = SharedModelContainer.shared.mainContext
        let descriptor = FetchDescriptor<Subscription>(predicate: #Predicate { $0.id == id })
        guard let subscription = try? context.fetch(descriptor).first,
              !subscription.isCancelled else { return }
        PaymentLedger.markPaid(subscription, in: context)
    }
}
