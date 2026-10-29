//
//  PaymentRecord.swift
//  SubCheck
//
//  Cada cobrança que já aconteceu. É a fonte de verdade do histórico: os
//  gráficos de evolução leem daqui, nunca dos valores atuais.
//

import Foundation
import SwiftData

@Model
final class PaymentRecord {
    var id: UUID
    /// Referência solta (não é relationship) para o histórico sobreviver à
    /// exclusão da assinatura.
    var subscriptionID: UUID
    var name: String
    var amount: Double
    var currencyCode: String
    var categoryRaw: String
    var paidAt: Date
    /// `true` quando o registro foi reconstruído a partir da data de início
    /// e da frequência (sem confirmação do usuário).
    var isEstimated: Bool

    init(
        id: UUID = UUID(),
        subscriptionID: UUID,
        name: String,
        amount: Double,
        currencyCode: String = "BRL",
        categoryRaw: String = CategoryType.miscellaneous.rawValue,
        paidAt: Date = Date(),
        isEstimated: Bool = false
    ) {
        self.id = id
        self.subscriptionID = subscriptionID
        self.name = name
        self.amount = amount
        self.currencyCode = currencyCode
        self.categoryRaw = categoryRaw
        self.paidAt = paidAt
        self.isEstimated = isEstimated
    }
}

extension PaymentRecord {

    convenience init(from subscription: Subscription, paidAt: Date, isEstimated: Bool) {
        self.init(
            subscriptionID: subscription.id,
            name: subscription.name,
            amount: subscription.cost,
            currencyCode: subscription.currencyCode,
            categoryRaw: subscription.category,
            paidAt: paidAt,
            isEstimated: isEstimated
        )
    }

    var categoryType: CategoryType {
        CategoryType(rawValue: categoryRaw) ?? .miscellaneous
    }

    /// Mês (primeiro dia) a que a cobrança pertence.
    var month: Date {
        Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: paidAt)
        ) ?? paidAt
    }
}
