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
        let billMark = UNNotificationAction(identifier: Self.billMarkPaidAction, title: L.t("Marcar como paga"), options: [])
        let billEnter = UNNotificationAction(identifier: Self.billEnterAction, title: L.t("Informar valor"), options: [.foreground])
        let billSnooze = UNNotificationAction(identifier: Self.billSnoozeAction, title: L.t("Lembrar em 3 h"), options: [])
        let fixed = UNNotificationCategory(identifier: Self.billFixedCategory, actions: [billMark, billSnooze], intentIdentifiers: [])
        let variable = UNNotificationCategory(identifier: Self.billVariableCategory, actions: [billEnter, billSnooze], intentIdentifiers: [])
        center.setNotificationCategories([category, fixed, variable])
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

    /// Categorias dos avisos de conta: a de valor fixo tem "Marcar como paga";
    /// a de valor variável tem "Informar valor" (abre o app para digitar).
    static let billFixedCategory = "bill.fixed"
    static let billVariableCategory = "bill.variable"
    static let billMarkPaidAction = "bill.markPaid"
    static let billEnterAction = "bill.enter"
    static let billSnoozeAction = "bill.snooze"
    private static let billSnoozePrefix = "billsnooze-"
    /// O iOS guarda no máximo 64 avisos pendentes; deixamos folga para os demais.
    private static let billReminderBudget = 36

    /// Reagenda os avisos de todas as contas com lembrete. Meses já pagos ou
    /// pulados não avisam. Idempotente: apaga os avisos de conta antigos e
    /// recria a partir do que está salvo agora.
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

        var planned: [(bill: Bill, reminder: PlannedBillReminder)] = []
        for bill in bills where bill.isActive && bill.remindersEnabled {
            let needsAmount = !bill.isFixed || bill.expectedAmount <= 0
            // Mês passado (para o aviso de atraso), este e os dois próximos.
            for offset in -1...2 {
                guard let ref = calendar.date(byAdding: .month, value: offset, to: now) else { continue }
                let due = BillSchedule.dueDate(day: bill.dueDay, inMonthOf: ref, calendar: calendar)
                if settled.contains("\(bill.id.uuidString)-\(monthKey(due))") { continue }
                for reminder in BillReminderPlanner.plan(
                    dueDate: due, advanceDays: bill.reminderDaysBefore,
                    needsAmount: needsAmount, now: now, calendar: calendar
                ) {
                    planned.append((bill, reminder))
                }
            }
        }

        for item in planned.sorted(by: { $0.reminder.fireDate < $1.reminder.fireDate }).prefix(Self.billReminderBudget) {
            let content = billContent(for: item.bill, kind: item.reminder.kind)
            let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: item.reminder.fireDate)
            let due = calendar.dateComponents([.year, .month, .day], from: item.reminder.dueDate)
            let identifier = "\(Self.billPrefix)\(item.bill.id.uuidString)-\(due.year ?? 0)\(due.month ?? 0)\(due.day ?? 0)-\(item.reminder.kind.rawValue)"
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
        }
    }

    private func billContent(for bill: Bill, kind: PlannedBillReminder.Kind) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.sound = .default
        content.userInfo = [Self.billIDKey: bill.id.uuidString]
        let fixedWithAmount = bill.isFixed && bill.expectedAmount > 0
        content.categoryIdentifier = fixedWithAmount ? Self.billFixedCategory : Self.billVariableCategory
        let amount = Money.format(bill.expectedAmount)

        switch kind {
        case .advance:
            let days = bill.reminderDaysBefore
            content.title = L.t("Conta próxima")
            content.body = fixedWithAmount
                ? L.t("%@ vence em %lld dia(s): %@.", bill.name, days, amount)
                : L.t("%@ vence em %lld dia(s).", bill.name, days)
        case .dueDay:
            content.title = L.t("Conta vence hoje")
            content.body = fixedWithAmount
                ? L.t("%@ vence hoje: %@.", bill.name, amount)
                : L.t("%@ vence hoje. Toque para informar o valor.", bill.name)
        case .evening:
            content.title = L.t("Falta informar o valor")
            content.body = L.t("%@ venceu hoje. Quer informar o valor agora?", bill.name)
        case .overdue:
            content.title = L.t("Conta atrasada")
            content.body = L.t("%@ venceu ontem. Informe o valor para manter o mês em dia.", bill.name)
        }
        return content
    }

    /// "Lembrar daqui a 3 horas": repete o mesmo aviso. Usa outro prefixo para
    /// não ser apagado quando os avisos de conta são recriados.
    func snoozeBill(_ original: UNNotificationContent, billID: String, hours: Double = 3) {
        guard let content = original.mutableCopy() as? UNMutableNotificationContent else { return }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: hours * 3600, repeats: false)
        center.add(UNNotificationRequest(identifier: "\(Self.billSnoozePrefix)\(billID)", content: content, trigger: trigger))
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
