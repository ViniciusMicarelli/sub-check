//
//  SalarySheet.swift
//  SubCheck
//

import SwiftUI

struct SalarySheet: View {

    @Environment(\.dismiss) private var dismiss

    @AppStorage(SalaryStore.amountKey) private var salary = 0.0
    @AppStorage(SalaryStore.dayKey) private var salaryDay = 5

    @State private var amount: Double?
    @State private var day: Int

    init() {
        let stored = UserDefaults.standard.double(forKey: SalaryStore.amountKey)
        let storedDay = UserDefaults.standard.integer(forKey: SalaryStore.dayKey)
        _amount = State(initialValue: stored > 0 ? stored : nil)
        _day = State(initialValue: storedDay > 0 ? storedDay : 5)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(Money.symbol).foregroundStyle(Color.textSecondary)
                        CurrencyField(
                            "0,00", optional: $amount,
                            textStyle: .title2, weight: .semibold, alignment: .left,
                            autoFocus: amount == nil
                        )
                    }
                } header: {
                    Text("Salário líquido")
                } footer: {
                    Text("Informe o valor que cai na conta, depois dos descontos (INSS, imposto de renda, plano de saúde e outros). Fica só neste aparelho.")
                }

                Section {
                    Stepper(value: $day, in: 1...31) {
                        Text(L.t("Cai todo dia %lld", day))
                    }
                } header: {
                    Text("Dia do pagamento")
                }

                if salary > 0 {
                    Section {
                        Button(role: .destructive) {
                            salary = 0
                            Haptics.warning()
                            dismiss()
                        } label: {
                            Label("Remover salário", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Salário")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        salary = max(amount ?? 0, 0)
                        salaryDay = day
                        Haptics.success()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled((amount ?? 0) <= 0)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
