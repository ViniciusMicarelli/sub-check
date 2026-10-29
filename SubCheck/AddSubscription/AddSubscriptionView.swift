//
//  AddSubscriptionView.swift
//  SubCheck
//

import SwiftUI
import SwiftData

struct AddSubscriptionView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var cost: Double?
    @State private var frequency: RecurrenceFrequency = .monthly
    @State private var category: CategoryType = .miscellaneous
    @State private var startDate = Date()
    @State private var enableReminders = true
    @State private var daysNoticeBefore = 2

    /// Becomes true once the user picks a category manually, which stops the
    /// automatic detection from overwriting their choice.
    @State private var categoryLocked = false

    @FocusState private var nameFocused: Bool

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && (cost ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                categorySection
                reminderSection
            }
            .navigationTitle("Nova assinatura")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar", action: save)
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            .onChange(of: name) { _, newValue in
                guard !categoryLocked else { return }
                category = SubscriptionCategorizer.categorize(name: newValue)
            }
            .onAppear { nameFocused = true }
        }
    }

    private var detailsSection: some View {
        Section("Detalhes") {
            TextField("Nome do serviço (ex: Netflix)", text: $name)
                .focused($nameFocused)
                .textInputAutocapitalization(.words)

            LabeledContent("Valor") {
                TextField("0,00", value: $cost, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }

            Picker("Frequência", selection: $frequency) {
                ForEach(RecurrenceFrequency.allCases) { frequency in
                    Text(frequency.rawValue).tag(frequency)
                }
            }

            DatePicker("Primeira cobrança", selection: $startDate, displayedComponents: .date)
        }
    }

    private var categorySection: some View {
        Section("Categoria") {
            Picker("Categoria", selection: categorySelection) {
                ForEach(CategoryType.allCases, id: \.self) { category in
                    Label(category.displayName, systemImage: category.icon)
                        .tag(category)
                }
            }

            Button {
                categoryLocked = false
                withAnimation(.snappy) {
                    category = SubscriptionCategorizer.categorize(name: name)
                }
            } label: {
                Label("Detectar automaticamente", systemImage: "sparkles")
            }
            .disabled(name.isEmpty)
        }
    }

    private var reminderSection: some View {
        Section("Lembrete") {
            Toggle("Notificar antes da cobrança", isOn: $enableReminders)

            if enableReminders {
                Stepper(value: $daysNoticeBefore, in: 1...7) {
                    Text("Avisar \(daysNoticeBefore) dia(s) antes")
                }
            }
        }
    }

    private var categorySelection: Binding<CategoryType> {
        Binding(
            get: { category },
            set: {
                categoryLocked = true
                category = $0
            }
        )
    }

    private func save() {
        guard let costValue = cost, canSave else { return }

        let subscription = Subscription(
            name: name.trimmingCharacters(in: .whitespaces),
            cost: costValue,
            startDate: startDate,
            frequency: frequency,
            category: category.rawValue,
            enableReminders: enableReminders,
            daysNoticeBefore: daysNoticeBefore
        )

        context.insert(subscription)
        try? context.save()

        NotificationService.shared.scheduleNotification(for: subscription)
        Haptics.success()
        dismiss()
    }
}
