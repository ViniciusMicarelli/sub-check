import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}
    
    /// Solicita permissão de notificações ao usuário
    func requestAuthorization() async -> Bool {
        do {
            let center = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Erro ao solicitar permissão de notificação: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Agenda uma notificação local antes da próxima cobrança
    func scheduleNotification(for subscription: Subscription) {
        // Remove agendamentos antigos para evitar duplicatas
        cancelNotification(for: subscription)
        
        guard subscription.enableReminders else { return }
        
        let center = UNUserNotificationCenter.current()
        let nextBilling = subscription.nextBillingDate
        
        // Data do alarme (Ex: 2 dias antes da cobrança às 09:00 AM)
        guard let reminderDate = Calendar.current.date(
            byAdding: .day,
            value: -subscription.daysNoticeBefore,
            to: nextBilling
        ) else { return }
        
        // Garante que o alarme esteja no futuro
        guard reminderDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Lembrete de Assinatura: \(subscription.name)"
        content.body = "Sua assinatura de \(subscription.cost.formatted(.currency(code: subscription.currencyCode))) vence em \(subscription.daysNoticeBefore) dias."
        content.sound = .default
        
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: reminderDate)
        dateComponents.hour = 9 // Horário fixo: 09:00 AM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: subscription.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Erro ao agendar notificação: \(error.localizedDescription)")
            }
        }
    }
    
    /// Cancela as notificações vinculadas a uma assinatura específica
    func cancelNotification(for subscription: Subscription) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [subscription.id.uuidString])
    }
}