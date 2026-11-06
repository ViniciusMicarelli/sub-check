//
//  AddOneOffView.swift
//  SubCheck
//
//  Registra um pagamento avulso ("paguei o Trae uma vez, US$ 8"). Em moeda
//  estrangeira a cotação é opcional e nunca depende de internet: usa a do dia
//  guardada no app, uma que a pessoa digita, ou só o valor aproximado em reais.
//

import SwiftUI
import SwiftData

struct AddOneOffView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// Quando preenchido, edita um pagamento existente.
    var editing: OneOffPayment?

    enum RateMode: String, CaseIterable, Identifiable {
        case automatic, rate, approx
        var id: String { rawValue }
    }

    @State private var name = ""
    @State private var amount: Double?
    @State private var currencyCode = CurrencyService.shared.baseCode
    @State private var paidAt = Date()
    @State private var note = ""
    @State private var mode: RateMode = .automatic
    @State private var manualRate = 0.0
    @State private var approxBase = 0.0
    @State private var loaded = false

    private var service: CurrencyService { .shared }
    private var base: String { service.baseCode }
    private var isForeign: Bool { currencyCode.uppercased() != base.uppercased() }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && (amount ?? 0) > 0 }

    /// Quanto vale na moeda base, com o modo de cotação escolhido.
    private var preview: Double? {
        guard let amount, amount > 0 else { return nil }
        guard isForeign else { return amount }
        switch mode {
        case .automatic: return service.convert(amount, from: currencyCode)
        case .rate: return manualRate > 0 ? amount * manualRate : nil
        case .approx: return approxBase > 0 ? approxBase : nil
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(L.t("O que foi? (ex.: Trae)"), text: $name)
                        .textInputAutocapitalization(.words)

                    LabeledContent("Valor") {
                        CurrencyField("0,00", optional: $amount)
                    }

                    Picker("Moeda", selection: $currencyCode) {
                        ForEach(CurrencyCode.ordered) { code in
                            Text(code.displayLabel).tag(code.code)
                        }
                    }

                    DatePicker("Data", selection: $paidAt, in: ...Date(), displayedComponents: .date)
                } footer: {
                    Text("Pagamento único: entra nos gastos do mês e não cria cobrança futura.")
                }

                if isForeign { rateSection }

                Section {
                    TextField(L.t("Anotação (opcional)"), text: $note, axis: .vertical)
                        .lineLimit(1...4)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(editing == nil ? L.t("Pagamento avulso") : L.t("Editar pagamento"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar", action: save).disabled(!canSave)
                }
            }
            .onAppear(perform: load)
        }
    }

    private var rateSection: some View {
        Section {
            Picker("Cotação", selection: $mode) {
                Text("Do dia").tag(RateMode.automatic)
                Text("Digitar").tag(RateMode.rate)
                Text(L.t("Em %@", base)).tag(RateMode.approx)
            }
            .pickerStyle(.segmented)

            switch mode {
            case .automatic:
                EmptyView()
            case .rate:
                LabeledContent(L.t("1 %@ =", currencyCode)) {
                    HStack(spacing: 4) {
                        CurrencyField("0,0000", value: $manualRate, fractionDigits: 4)
                        Text(base).foregroundStyle(Color.textSecondary)
                    }
                }
            case .approx:
                LabeledContent(L.t("Aproximadamente")) {
                    HStack(spacing: 4) {
                        Text(Money.symbol).foregroundStyle(Color.textSecondary)
                        CurrencyField("0,00", value: $approxBase)
                    }
                }
            }

            if let preview {
                LabeledContent("Vale na moeda base") {
                    Text(Money.format(preview)).fontWeight(.semibold)
                }
            }
        } header: {
            Text("Cotação")
        } footer: {
            Text(mode == .automatic
                 ? L.t("Usa a cotação guardada no app. Sem internet, usa a última que o app conhece.")
                 : L.t("Use quando souber quanto realmente pagou. Não depende de internet."))
        }
    }

    // MARK: Ações

    private func load() {
        guard !loaded else { return }
        loaded = true
        guard let editing else { return }
        name = editing.name
        amount = editing.amount
        currencyCode = editing.currencyCode
        paidAt = editing.paidAt
        note = editing.note
        if editing.approxBase > 0 {
            mode = .approx
            approxBase = editing.approxBase
        } else if editing.rateIsManual {
            mode = .rate
            manualRate = editing.rateToBase
        }
    }

    private func save() {
        guard let amount, amount > 0 else { return }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let payment = editing ?? OneOffPayment(name: trimmed, amount: amount)
        payment.name = trimmed
        payment.amount = amount
        payment.currencyCode = currencyCode
        payment.paidAt = paidAt
        payment.note = note
        payment.categoryRaw = SubscriptionCategorizer.categorize(name: trimmed).rawValue

        // Zera a cotação antiga e aplica a escolhida.
        payment.approxBase = 0
        payment.rateIsManual = false
        payment.rateToBase = 0
        if !isForeign {
            payment.baseCodeAtPayment = base
            payment.rateToBase = 1
        } else {
            switch mode {
            case .automatic: payment.stampRate(using: service)
            case .rate: payment.setManualRate(manualRate, base: base)
            case .approx: payment.setApproximateBase(approxBase, base: base)
            }
            if payment.rateToBase == 0 { payment.stampRate(using: service) }
        }

        if editing == nil { context.insert(payment) }
        context.saveReporting()
        Haptics.success()
        dismiss()
    }
}
