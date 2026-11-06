//
//  PaymentAmountSheet.swift
//  SubCheck
//
//  Registra uma cobrança de assinatura "por uso": a pessoa digita o valor
//  real do mês. Em moeda estrangeira também pode digitar a cotação que valeu
//  naquele dia, sem depender de internet.
//

import SwiftUI

struct PaymentAmountSheet: View {

    let subscription: Subscription
    var onConfirm: (Double, Double?) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var amount: Double?
    @State private var useManualRate = false
    @State private var rate = 0.0

    private var service: CurrencyService { .shared }
    private var isForeign: Bool { subscription.isForeignCurrency(base: service.baseCode) }
    private var canSave: Bool { (amount ?? 0) > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent(L.t("Valor (%@)", subscription.currencyCode)) {
                        CurrencyField("0,00", optional: $amount, textStyle: .title3, weight: .semibold, autoFocus: true)
                    }
                } footer: {
                    Text(L.t("Última cobrança registrada: %@. Informe o valor real deste mês.",
                             Money.format(subscription.cost, code: subscription.currencyCode)))
                }

                if isForeign {
                    Section {
                        Toggle("Digitar a cotação", isOn: $useManualRate.animation(.snappy))
                        if useManualRate {
                            LabeledContent(L.t("1 %@ =", subscription.currencyCode)) {
                                HStack(spacing: 4) {
                                    CurrencyField("0,0000", value: $rate, fractionDigits: 4)
                                    Text(service.baseCode).foregroundStyle(Color.textSecondary)
                                }
                            }
                        }
                        if let amount, amount > 0 {
                            LabeledContent("Vale na moeda base") {
                                Text(Money.format(useManualRate && rate > 0
                                                  ? amount * rate
                                                  : service.convert(amount, from: subscription.currencyCode)))
                                    .fontWeight(.semibold)
                            }
                        }
                    } footer: {
                        Text("Sem digitar, usa a cotação guardada no app (funciona sem internet).")
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(subscription.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Registrar") {
                        onConfirm(amount ?? 0, useManualRate && rate > 0 ? rate : nil)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
