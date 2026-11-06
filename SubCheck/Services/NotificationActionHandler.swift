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
