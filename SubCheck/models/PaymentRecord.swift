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
    // CloudKit exige valor padrão em toda propriedade (iCloud em Ajustes).
    var id: UUID = UUID()
    /// Referência solta (não é relationship) para o histórico sobreviver à
    /// exclusão da assinatura.
    var subscriptionID: UUID = UUID()
    var name: String = ""
    var amount: Double = 0
    var currencyCode: String = "BRL"
    var categoryRaw: String = CategoryType.miscellaneous.rawValue
    var paidAt: Date = Date()
    /// `true` quando o registro foi reconstruído a partir da data de início
    /// e da frequência (sem confirmação do usuário).
    var isEstimated: Bool = false
    /// Quantas unidades da moeda base valiam 1 unidade de `currencyCode` no
    /// dia do pagamento. 0 = cotação da época desconhecida.
    var rateToBase: Double = 0
    /// Moeda base em que `rateToBase` foi calculada.
    var baseCodeAtPayment: String = ""

    init(
        id: UUID = UUID(),
        subscriptionID: UUID,
        name: String,
        amount: Double,
        currencyCode: String = "BRL",
        categoryRaw: String = CategoryType.miscellaneous.rawValue,
        paidAt: Date = Date(),
        isEstimated: Bool = false,
        rateToBase: Double = 0,
        baseCodeAtPayment: String = ""
    ) {
        self.id = id
        self.subscriptionID = subscriptionID
        self.name = name
        self.amount = amount
        self.currencyCode = currencyCode
        self.categoryRaw = categoryRaw
        self.paidAt = paidAt
        self.isEstimated = isEstimated
        self.rateToBase = rateToBase
        self.baseCodeAtPayment = baseCodeAtPayment
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

// MARK: - Cotação da época

extension PaymentRecord {

    /// Congela a cotação do dia do pagamento. Usa a foto do histórico mais
    /// próxima; só recorre à cotação atual quando o pagamento é de hoje.
    func stampRate(using service: CurrencyService) {
        let base = service.baseCode
        baseCodeAtPayment = base
        rateToBase = service.historicalRate(from: currencyCode, to: base, on: paidAt) ?? 0
    }

    /// Valor pago na moeda base, na cotação da época.
    var paidInBaseAtTheTime: Double? {
        rateToBase > 0 ? amount * rateToBase : nil
    }

    /// Diferença entre o que custou e o que custaria hoje, na moeda base
    /// atual. `nil` se a cotação da época não foi registrada.
    func impact(using service: CurrencyService) -> ExchangeImpact? {
        guard rateToBase > 0 else { return nil }
        let base = service.baseCode

        // Se o usuário trocou a moeda base depois, leva a cotação antiga para
        // a base nova com a taxa de hoje (aproximação razoável).
        var rateInCurrentBase = rateToBase
        if !baseCodeAtPayment.isEmpty, baseCodeAtPayment.uppercased() != base.uppercased() {
            rateInCurrentBase = service.convert(rateToBase, from: baseCodeAtPayment, to: base)
        }

        return ExchangeImpact(
            amount: amount,
            rateAtPayment: rateInCurrentBase,
            currentRate: service.convert(1, from: currencyCode, to: base)
        )
    }
}
