//
//  NotificationService.swift
//  SubCheck
//
//  Schedules local reminders for upcoming subscription charges.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationService {

    static let shared = NotificationService()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    /// Requests permission once. Safe to call repeatedly.
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    /// Schedules (or reschedules) the reminder for a subscription.
    func scheduleNotification(for subscription: Subscription) {
        scheduleTrialAlert(for: subscription)
        guard subscription.enableReminders, !subscription.isCancelled else {
            cancelNotification(for: subscription)
            return
        }

        let identifier = Self.identifier(for: subscription)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let fireDate = Calendar.current.date(
            byAdding: .day,
            value: -subscription.daysNoticeBefore,
            to: subscription.nextBillingDate
        ) ?? subscription.nextBillingDate

        guard fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Cobrança próxima"
        content.body = "\(subscription.name) será cobrado em \(subscription.daysNoticeBefore) dia(s)."
        content.sound = .default

        var components = Calendar.current.dateComponents([.year, .month, .day], from: fireDate)
        components.hour = 9
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    func cancelNotification(for subscription: Subscription) {
        center.removePendingNotificationRequests(withIdentifiers: [
            Self.identifier(for: subscription),
            Self.trialIdentifier(for: subscription)
        ])
    }

    // MARK: - Teste gratuito

    /// Avisa na véspera do fim do teste, antes de a cobrança começar.
    func scheduleTrialAlert(for subscription: Subscription) {
        let identifier = Self.trialIdentifier(for: subscription)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard !subscription.isCancelled, let end = subscription.trialEndsAt else { return }
        let eve = Calendar.current.date(byAdding: .day, value: -1, to: end) ?? end
        var components = Calendar.current.dateComponents([.year, .month, .day], from: eve)
        components.hour = 9
        guard let fireDate = Calendar.current.date(from: components), fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = L.t("Teste gratuito acabando")
        content.body = L.t(
            "O teste de %@ termina amanhã e depois cobra %@. Cancele agora se não quiser continuar.",
            subscription.name,
            Money.format(subscription.cost, code: subscription.currencyCode)
        )
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    private static func trialIdentifier(for subscription: Subscription) -> String {
        "trial-\(subscription.id.uuidString)"
    }

    // MARK: - Orçamento

    /// Identificador único do aviso de orçamento estourado.
    private static let budgetIdentifier = "budget-overflow"

    /// Avisa que o gasto mensal passou do teto definido. Substitui o aviso
    /// anterior, para não acumular notificações repetidas.
    func scheduleBudgetAlert(spent: Double, budget: Double) {
        cancelBudgetAlert()
        guard budget > 0, spent > budget else { return }

        let content = UNMutableNotificationContent()
        content.title = L.t("Orçamento estourado")
        content.body = L.t("Você gastou %@ e seu orçamento é %@.", Money.format(spent), Money.format(budget))
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        center.add(UNNotificationRequest(identifier: Self.budgetIdentifier, content: content, trigger: trigger))
    }

    func cancelBudgetAlert() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.budgetIdentifier])
    }

    private static func identifier(for subscription: Subscription) -> String {
        "subscription-\(subscription.id.uuidString)"
    }
}
