//
//  AddBillView.swift
//  SubCheck
//
//  Cria ou edita uma conta recorrente.
//

import SwiftData
import SwiftUI

struct AddBillView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// `nil` cria uma conta nova.
    let bill: Bill?

    @State private var name: String
    @State private var category: BillCategory
    @State private var dueDay: Int
    @State private var isFixed: Bool
    @State private var amount: Double?
    @State private var remindersEnabled: Bool
    @State private var reminderDaysBefore: Int
    @State private var isActive: Bool
    @State private var showDeleteConfirmation = false
    /// Depois de mexer no nome, trocar a categoria não sobrescreve mais.
    @State private var nameEdited = false
    @FocusState private var nameFocused: Bool

    init(bill: Bill? = nil, preset: BillCategory? = nil) {
        self.bill = bill
        let category = bill?.category ?? preset ?? .other
        _name = State(initialValue: bill?.name ?? (preset?.displayName ?? ""))
        _category = State(initialValue: category)
        _dueDay = State(initialValue: bill?.dueDay ?? min(Calendar.current.component(.day, from: Date()), 28))
        _isFixed = State(initialValue: bill?.isFixed ?? !category.isUsuallyVariable)
        _amount = State(initialValue: (bill?.expectedAmount ?? 0) > 0 ? bill?.expectedAmount : nil)
        _remindersEnabled = State(initialValue: bill?.remindersEnabled ?? true)
        _reminderDaysBefore = State(initialValue: bill?.reminderDaysBefore ?? 1)
        _isActive = State(initialValue: bill?.isActive ?? true)
        _nameEdited = State(initialValue: bill != nil || preset != nil)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && (!isFixed || (amount ?? 0) > 0)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Conta") {
                    TextField("Nome (ex.: Conta de luz)", text: $name)
                        .focused($nameFocused)
                        .onChange(of: name) { _, _ in
                            if nameFocused { nameEdited = true }
                        }

                    Picker("Categoria", selection: $category) {
                        ForEach(BillCategory.allCases) { item in
                            Label(item.displayName, systemImage: item.icon).tag(item)
                        }
                    }
                    .onChange(of: category) { _, new in
                        guard bill == nil else { return }
                        if !nameEdited { name = new.displayName }
                        isFixed = !new.isUsuallyVariable
                    }
                }

                Section {
                    Stepper(value: $dueDay, in: 1...31) {
                        Text(L.t("Vence todo dia %lld", dueDay))
                    }
                } header: {
                    Text("Vencimento")
                } footer: {
                    if dueDay > 28 {
                        Text("Em meses mais curtos, vence no último dia.")
                    }
                }

                Section {
                    Picker("Tipo de valor", selection: $isFixed) {
                        Text("Varia todo mês").tag(false)
                        Text("Valor fixo").tag(true)
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text(Money.symbol).foregroundStyle(Color.textSecondary)
                        TextField(
                            isFixed ? L.t("Valor") : L.t("Estimativa (opcional)"),
                            value: $amount,
                            format: .number.precision(.fractionLength(0...2))
                        )
                        .keyboardType(.decimalPad)
                    }
                } header: {
                    Text("Valor")
                } footer: {
                    Text(isFixed
                         ? L.t("O valor já vem preenchido todo mês. Você só confirma.")
                         : L.t("Você informa o valor real no vencimento. A estimativa só aparece até lá."))
                }

                Section {
                    Toggle("Avisar", isOn: $remindersEnabled)
                    if remindersEnabled {
                        Stepper(value: $reminderDaysBefore, in: 0...7) {
                            Text(reminderDaysBefore == 0
                                 ? L.t("No dia do vencimento")
                                 : L.t("%lld dia(s) antes", reminderDaysBefore))
                        }
                    }
                } header: {
                    Text("Lembrete")
                }

                if bill != nil {
                    Section {
                        Toggle("Conta ativa", isOn: $isActive)
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Excluir conta", systemImage: "trash")
                        }
                    } footer: {
                        Text("Os meses já pagos continuam no histórico.")
                    }
                }
            }
            .navigationTitle(bill == nil ? L.t("Nova conta") : L.t("Editar conta"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar", action: save)
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .confirmationDialog(
                "Excluir esta conta?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Excluir", role: .destructive) {
                    if let bill {
                        BillLedger.delete(bill, in: context)
                        BillLedger.rescheduleNotifications(in: context)
                    }
                    Haptics.warning()
                    dismiss()
                }
                Button("Cancelar", role: .cancel) {}
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let expected = max(amount ?? 0, 0)

        if let bill {
            bill.name = trimmed
            bill.category = category
            bill.dueDay = dueDay
            bill.isFixed = isFixed
            bill.expectedAmount = expected
            bill.remindersEnabled = remindersEnabled
            bill.reminderDaysBefore = reminderDaysBefore
            bill.isActive = isActive
            context.saveReporting()
            BillLedger.ensureEntries(for: [bill], in: context)
            BillLedger.syncCurrentEntry(for: bill, in: context)
        } else {
            let new = Bill(
                name: trimmed,
                category: category,
                dueDay: dueDay,
                isFixed: isFixed,
                expectedAmount: expected,
                remindersEnabled: remindersEnabled,
                reminderDaysBefore: reminderDaysBefore
            )
            context.insert(new)
            context.saveReporting()
            BillLedger.ensureEntries(for: [new], in: context)
        }

        BillLedger.rescheduleNotifications(in: context)
        Haptics.success()
        dismiss()
    }
}
