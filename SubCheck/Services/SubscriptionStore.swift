//
//  SubscriptionStore.swift
//  SubCheck
//
//  Mutations that touch more than one model (deleting keeps a history record,
//  cancelling keeps notifications in sync).
//

import Foundation
import SwiftData

@MainActor
enum SubscriptionStore {

    /// Deletes a subscription but keeps a record in the history tab.
    static func delete(
        _ subscription: Subscription,
        reason: String = "Removida pelo usuário",
        in context: ModelContext
    ) {
        NotificationService.shared.cancelNotification(for: subscription)

        let record = DeletedSubscription(
            name: subscription.name,
            cost: subscription.cost,
            currencyCode: subscription.currencyCode,
            startDate: subscription.startDate,
            deletedDate: Date(),
            deleteReason: reason
        )
        context.insert(record)
        context.delete(subscription)
        try? context.save()
    }

    /// Marks a subscription as cancelled (or reactivates it).
    static func toggleCancelled(_ subscription: Subscription, in context: ModelContext) {
        subscription.isCancelled.toggle()

        if subscription.isCancelled {
            NotificationService.shared.cancelNotification(for: subscription)
        } else {
            NotificationService.shared.scheduleNotification(for: subscription)
        }
        try? context.save()
    }
}
