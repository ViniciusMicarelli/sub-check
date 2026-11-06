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

    // MARK: - Ações na notificação

    static let chargeCategory = "subscription.charge"
    static let markPaidAction = "subscription.markPaid"
    static let snoozeAction = "subscription.snooze"
    static let subscriptionIDKey = "subscriptionID"

    /// Registra os botões "Marcar como pago" e "Lembrar amanhã" que aparecem
    /// ao segurar a notificação de cobrança.
    func registerCategories() {
        let paid = UNNotificationAction(
            identifier: Self.markPaidAction,
            title: L.t("Marcar como pago"),
            options: []
        )
        let snooze = UNNotificationAction(
            identifier: Self.snoozeAction,
            title: L.t("Lembrar amanhã"),
            options: []
        )
        let category = UNNotificationCategory(
            identifier: Self.chargeCategory,
            actions: [paid, snooze],
            intentIdentifiers: []
        )
        center.setNotificationCategories([category])
    }

    /// Repete a mesma notificação amanhã às 9h.
    func snooze(_ original: UNNotificationContent, id: String, now: Date = Date()) {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)),
              let content = original.mutableCopy() as? UNMutableNotificationContent else { return }

        var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        components.hour = 9
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        center.add(UNNotificationRequest(identifier: "snooze-\(id)", content: content, trigger: trigger))
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
        content.title = L.t("Cobrança próxima")
        content.body = L.t(
            "%@ será cobrado em %lld dia(s).",
            subscription.name,
            subscription.daysNoticeBefore
        )
        content.sound = .default
        content.categoryIdentifier = Self.chargeCategory
        content.userInfo = [Self.subscriptionIDKey: subscription.id.uuidString]

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

    // MARK: - Contas do mês

    static let billIDKey = "billID"
    private static let billPrefix = "bill-"

    /// Reagenda os avisos das contas: os próximos dois vencimentos de cada
    /// conta com lembrete. Meses já pagos ou pulados não avisam. Idempotente.
    func scheduleBills(
        _ bills: [Bill],
        entries: [BillEntry],
        now: Date = Date(),
        calendar: Calendar = .current
    ) async {
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(
            withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(Self.billPrefix) }
        )

        func monthKey(_ date: Date) -> String {
            let c = calendar.dateComponents([.year, .month], from: date)
            return "\(c.year ?? 0)-\(c.month ?? 0)"
        }
        let settled = Set(entries.filter { $0.isPaid || $0.isSkipped }.map { "\($0.billID.uuidString)-\(monthKey($0.monthStart))" })

        for bill in bills where bill.isActive && bill.remindersEnabled {
            for due in BillSchedule.upcomingDueDates(day: bill.dueDay, from: now, count: 2, calendar: calendar) {
                if settled.contains("\(bill.id.uuidString)-\(monthKey(due))") { continue }

                let fireDay = calendar.date(byAdding: .day, value: -bill.reminderDaysBefore, to: due) ?? due
                var parts = calendar.dateComponents([.year, .month, .day], from: fireDay)
                parts.hour = 9
                guard let fire = calendar.date(from: parts), fire > now else { continue }

                let content = UNMutableNotificationContent()
                content.sound = .default
                content.userInfo = [Self.billIDKey: bill.id.uuidString]
                let amount = Money.format(bill.expectedAmount)
                if bill.reminderDaysBefore == 0 {
                    content.title = L.t("Conta vence hoje")
                    content.body = (bill.isFixed && bill.expectedAmount > 0)
                        ? L.t("%@ vence hoje: %@.", bill.name, amount)
                        : L.t("%@ vence hoje. Toque para informar o valor.", bill.name)
                } else {
                    content.title = L.t("Conta próxima")
                    content.body = (bill.isFixed && bill.expectedAmount > 0)
                        ? L.t("%@ vence em %lld dia(s): %@.", bill.name, bill.reminderDaysBefore, amount)
                        : L.t("%@ vence em %lld dia(s).", bill.name, bill.reminderDaysBefore)
                }

                let dayKey = calendar.dateComponents([.year, .month, .day], from: due)
                let identifier = "\(Self.billPrefix)\(bill.id.uuidString)-\(dayKey.year ?? 0)\(dayKey.month ?? 0)\(dayKey.day ?? 0)"
                let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
                try? await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
            }
        }
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
