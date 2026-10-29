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
    /// Moeda da cobrança; começa na moeda base do app.
    @State private var currencyCode = CurrencyService.shared.baseCode

    /// `nil` mantém o ícone automático (marca detectada pelo nome).
    @State private var icon: SubscriptionIcon?
    @State private var showIconPicker = false

    /// Becomes true once the user picks a category manually, which stops the
    /// automatic detection from overwriting their choice.
    @State private var categoryLocked = false

    @FocusState private var nameFocused: Bool

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && (cost ?? 0) > 0
    }

    private var automaticIcon: SubscriptionIcon {
        if let brand = BrandIconCatalog.match(name: name) { return .brand(brand.id) }
        return .symbol(category.icon)
    }

    private var previewIcon: SubscriptionIcon { icon ?? automaticIcon }

    /// A cobrança está em moeda diferente da base do app.
    private var isForeignCurrency: Bool {
        currencyCode.uppercased() != CurrencyService.shared.baseCode.uppercased()
    }

    /// Valor digitado já convertido para a moeda base.
    private var convertedValue: Double {
        CurrencyService.shared.convert(cost ?? 0, from: currencyCode)
    }

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                iconSection
                categorySection
                reminderSection
            }
            .navigationTitle("Nova assinatura")
            .navigationBarTitleDisplayMode(.inline)
            .animation(.snappy, value: cost)
            .animation(.snappy, value: currencyCode)
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
            .sheet(isPresented: $showIconPicker) {
                IconPickerView(
                    serviceName: name,
                    fallbackColor: category.color,
                    automaticIcon: automaticIcon,
                    current: icon
                ) { selection in
                    icon = selection
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

            Picker("Moeda", selection: $currencyCode) {
                ForEach(CurrencyCode.ordered) { code in
                    Text(code.displayLabel).tag(code.code)
                }
            }

            // Atalho de conversão: só aparece quando a cobrança está em moeda
            // diferente da base, para o usuário conferir o impacto no total.
            if isForeignCurrency {
                Text(L.t("Equivale a %@", Money.compact(convertedValue)))
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
                    .contentTransition(.numericText())
                    .transition(.opacity)
            }

            Picker("Frequência", selection: $frequency) {
                ForEach(RecurrenceFrequency.allCases) { frequency in
                    Text(frequency.displayName).tag(frequency)
                }
            }

            DatePicker("Primeira cobrança", selection: $startDate, displayedComponents: .date)
        }
    }

    private var iconSection: some View {
        Section("Ícone") {
            Button {
                nameFocused = false
                showIconPicker = true
            } label: {
                HStack(spacing: Spacing.md) {
                    SubscriptionIconView(
                        icon: previewIcon,
                        fallbackColor: category.color,
                        size: 40
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(previewIcon.displayName)
                            .foregroundStyle(Color.textPrimary)
                        Text(icon == nil ? L.t("Detectado automaticamente") : L.t("Personalizado"))
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.textTertiary)
                }
            }
            .buttonStyle(.plain)
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
                    Text(L.t("reminder.stepper", daysNoticeBefore))
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
            currencyCode: currencyCode,
            startDate: startDate,
            frequency: frequency,
            category: category.rawValue,
            enableReminders: enableReminders,
            daysNoticeBefore: daysNoticeBefore,
            iconRaw: icon?.rawValue
        )

        context.insert(subscription)
        try? context.save()

        NotificationService.shared.scheduleNotification(for: subscription)
        Haptics.success()
        dismiss()
    }
}
