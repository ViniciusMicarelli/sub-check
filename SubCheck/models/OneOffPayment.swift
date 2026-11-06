//
//  OneOffPayment.swift
//  SubCheck
//
//  Pagamento avulso: algo que você pagou uma vez (ou de vez em quando) e que
//  não é uma assinatura. Ex.: "Trae, US$ 8, uma vez, e nunca mais usei" ou a
//  compra do próprio SubCheck Pro. Entra nos gastos do mês, mas não cria
//  cobrança futura.
//

import Foundation
import SwiftData

@Model
final class OneOffPayment {
    // CloudKit exige valor padrão em toda propriedade.
    var id: UUID = UUID()
    var name: String = ""
    /// Valor pago, na moeda `currencyCode`.
    var amount: Double = 0
    var currencyCode: String = "BRL"
    var paidAt: Date = Date()
    var note: String = ""
    var categoryRaw: String = CategoryType.subscriptions.rawValue
    /// Ícone escolhido (ver `SubscriptionIcon`). `nil` = automático.
    var iconRaw: String?
    /// Cotação da época (unidades da moeda base por 1 unidade de `currencyCode`).
    /// 0 = desconhecida.
    var rateToBase: Double = 0
    var baseCodeAtPayment: String = ""
    /// `true` quando a cotação foi digitada pela pessoa.
    var rateIsManual: Bool = false
    /// Valor aproximado já na moeda base, digitado quando a pessoa não sabe a
    /// cotação ("foi uns R$ 40"). 0 = não informado. Tem prioridade sobre a cotação.
    var approxBase: Double = 0
    /// Identificador de origem para não registrar duas vezes (ex.: id da
    /// transação do StoreKit). Vazio = lançamento manual.
    var sourceID: String = ""

    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        currencyCode: String = "BRL",
        paidAt: Date = Date(),
        note: String = "",
        categoryRaw: String = CategoryType.subscriptions.rawValue,
        iconRaw: String? = nil,
        rateToBase: Double = 0,
        baseCodeAtPayment: String = "",
        rateIsManual: Bool = false,
        approxBase: Double = 0,
        sourceID: String = ""
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.currencyCode = currencyCode
        self.paidAt = paidAt
        self.note = note
        self.categoryRaw = categoryRaw
        self.iconRaw = iconRaw
        self.rateToBase = rateToBase
        self.baseCodeAtPayment = baseCodeAtPayment
        self.rateIsManual = rateIsManual
        self.approxBase = approxBase
        self.sourceID = sourceID
    }
}

// MARK: - Valor na moeda base

extension OneOffPayment {

    var categoryType: CategoryType {
        CategoryType(rawValue: categoryRaw) ?? .subscriptions
    }

    /// Quanto custou na moeda base, **sem nunca falhar** (funciona sem internet):
    /// 1. valor aproximado digitado; 2. cotação guardada (digitada ou da época);
    /// 3. a última cotação que o app tem em cache.
    func baseAmount(in service: CurrencyService) -> Double {
        let base = service.baseCode
        if approxBase > 0 { return approxBase }
        if rateToBase > 0, baseCodeAtPayment.uppercased() == base.uppercased() || baseCodeAtPayment.isEmpty {
            return amount * rateToBase
        }
        return service.convert(amount, from: currencyCode)
    }

    /// Guarda a cotação do dia (do histórico, ou a atual se for de hoje). Não
    /// mexe numa cotação que a pessoa digitou.
    func stampRate(using service: CurrencyService) {
        guard !rateIsManual else { return }
        baseCodeAtPayment = service.baseCode
        rateToBase = service.historicalRate(from: currencyCode, to: service.baseCode, on: paidAt) ?? 0
    }

    /// A pessoa digitou a cotação do dia.
    func setManualRate(_ rate: Double, base: String) {
        guard rate > 0 else { return }
        rateToBase = rate
        baseCodeAtPayment = base
        rateIsManual = true
        approxBase = 0
    }

    /// A pessoa só sabe o valor aproximado em reais (ou na moeda base).
    func setApproximateBase(_ value: Double, base: String) {
        guard value > 0 else { return }
        approxBase = value
        baseCodeAtPayment = base
        rateToBase = amount > 0 ? value / amount : 0
        rateIsManual = true
    }
}

// MARK: - Totais

enum OneOffPayments {

    /// Soma, na moeda base, dos pagamentos avulsos de um mês.
    static func total(
        _ payments: [OneOffPayment],
        inMonthOf date: Date,
        service: CurrencyService,
        calendar: Calendar = .current
    ) -> Double {
        payments
            .filter { calendar.isDate($0.paidAt, equalTo: date, toGranularity: .month) }
            .reduce(0) { $0 + $1.baseAmount(in: service) }
    }

    /// Registra a compra do SubCheck Pro como despesa, uma única vez por
    /// transação. Devolve o registro criado, ou `nil` se já existia.
    @discardableResult
    static func recordProPurchase(
        price: Decimal,
        currencyCode: String,
        date: Date,
        transactionID: String,
        in context: ModelContext,
        service: CurrencyService = .shared
    ) -> OneOffPayment? {
        let existing = (try? context.fetch(FetchDescriptor<OneOffPayment>())) ?? []
        guard !existing.contains(where: { $0.sourceID == transactionID }) else { return nil }

        let payment = OneOffPayment(
            name: "SubCheck Pro",
            amount: NSDecimalNumber(decimal: price).doubleValue,
            currencyCode: currencyCode,
            paidAt: date,
            note: L.t("Compra única do SubCheck Pro"),
            categoryRaw: CategoryType.productivity.rawValue,
            sourceID: transactionID
        )
        payment.stampRate(using: service)
        context.insert(payment)
        context.saveReporting()
        return payment
    }
}
