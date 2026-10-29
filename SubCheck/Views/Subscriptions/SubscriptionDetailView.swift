//
//  SubscriptionDetailView.swift
//  SubCheck
//

import SwiftUI
import SwiftData
import WidgetKit

struct SubscriptionDetailView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var subscription: Subscription

    @State private var showDeleteConfirmation = false
    @State private var showIconPicker = false
    @State private var showPaymentConfirmation = false

    var body: some View {
        Form {
            headerSection
            iconSection
            detailsSection
            billingSection
            paymentsSection
            reminderSection
            actionsSection
        }
        .navigationTitle(subscription.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showIconPicker) {
            IconPickerView(
                serviceName: subscription.name,
                fallbackColor: subscription.categoryColor,
                automaticIcon: subscription.automaticIcon,
                current: subscription.iconRaw.flatMap(SubscriptionIcon.init(rawValue:))
            ) { icon in
                subscription.iconRaw = icon?.rawValue
                try? context.save()
            }
        }
        .onChange(of: subscription.currencyCode) { _, _ in
            try? context.save()
        }
        .onChange(of: subscription.enableReminders) { _, _ in
            NotificationService.shared.scheduleNotification(for: subscription)
            try? context.save()
        }
        .onChange(of: subscription.daysNoticeBefore) { _, _ in
            NotificationService.shared.scheduleNotification(for: subscription)
            try? context.save()
        }
        .alert("Pagamento registrado", isPresented: $showPaymentConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("A próxima cobrança foi movida para o próximo ciclo.")
        }
        .confirmationDialog(
            "Excluir assinatura?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Excluir", role: .destructive) {
                SubscriptionStore.delete(subscription, in: context)
                Haptics.warning()
                dismiss()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("A assinatura será movida para o histórico.")
        }
    }

    private var headerSection: some View {
        Section {
            HStack(spacing: Spacing.lg) {
                SubscriptionIconView(
                    icon: subscription.resolvedIcon,
                    fallbackColor: subscription.categoryColor,
                    size: 60
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(Money.format(subscription.cost, code: subscription.currencyCode))
                        .font(.title2.weight(.bold))
                        .contentTransition(.numericText())
                    Text(L.t("subscription.perMonthYear",
                             Money.format(subscription.monthlyCost(in: .shared)),
                             Money.compact(subscription.yearlyCost(in: .shared))))
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)

                    if subscription.isForeignCurrency(base: CurrencyService.shared.baseCode) {
                        Text(L.t("Convertido para %@", CurrencyService.shared.baseCode))
                            .font(.caption2)
                            .foregroundStyle(Color.textTertiary)
                    }
                }
            }
            .padding(.vertical, Spacing.xs)
        }
    }

    private var iconSection: some View {
        Section("Ícone") {
            Button {
                showIconPicker = true
            } label: {
                HStack(spacing: Spacing.md) {
                    SubscriptionIconView(
                        icon: subscription.resolvedIcon,
                        fallbackColor: subscription.categoryColor,
                        size: 40
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(subscription.resolvedIcon.displayName)
                            .foregroundStyle(Color.textPrimary)
                        Text(subscription.iconRaw == nil ? L.t("Automático") : L.t("Personalizado"))
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

    private var detailsSection: some View {
        Section("Detalhes") {
            TextField("Nome", text: $subscription.name)

            Picker("Categoria", selection: categoryBinding) {
                ForEach(CategoryType.allCases, id: \.self) { category in
                    Label(category.displayName, systemImage: category.icon)
                        .tag(category)
                }
            }

            Picker("Frequência", selection: $subscription.frequency) {
                ForEach(RecurrenceFrequency.allCases) { frequency in
                    Text(frequency.displayName).tag(frequency)
                }
            }

            DatePicker("Início", selection: $subscription.startDate, displayedComponents: .date)

            LabeledContent("Valor") {
                TextField("0,00", value: $subscription.cost, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }

            Picker("Moeda", selection: $subscription.currencyCode) {
                ForEach(CurrencyCode.ordered) { code in
                    Text(code.displayLabel).tag(code.code)
                }
            }
        }
    }

    private var billingSection: some View {
        Section("Próxima cobrança") {
            LabeledContent("Data") {
                Text(subscription.nextBillingDate.formatted(date: .long, time: .omitted))
            }
            LabeledContent("Faltam") {
                Text(subscription.daysUntilNextBilling == 0
                     ? L.t("Hoje")
                     : L.t("due.days", subscription.daysUntilNextBilling))
                    .foregroundStyle(subscription.daysUntilNextBilling <= 3 ? Color.danger : Color.textPrimary)
            }
        }
    }

    private var paymentsSection: some View {
        Section("Pagamentos") {
            Button {
                PaymentLedger.markPaid(subscription, in: context)
                WidgetCenter.shared.reloadAllTimelines()
                Haptics.success()
                showPaymentConfirmation = true
            } label: {
                Label("Registrar pagamento", systemImage: "checkmark.circle")
            }

            if let last = subscription.lastPaymentDate {
                LabeledContent("Último pagamento") {
                    Text(last.formatted(date: .abbreviated, time: .omitted))
                }
            }
        }
    }

    private var reminderSection: some View {
        Section("Lembrete") {
            Toggle("Notificar antes da cobrança", isOn: $subscription.enableReminders)

            if subscription.enableReminders {
                Stepper(value: $subscription.daysNoticeBefore, in: 1...7) {
                    Text(L.t("reminder.stepper", subscription.daysNoticeBefore))
                }
            }
        }
    }

    private var actionsSection: some View {
        Section {
            Button {
                Haptics.impact()
                SubscriptionStore.toggleCancelled(subscription, in: context)
            } label: {
                Label(
                    subscription.isCancelled ? "Reativar assinatura" : "Cancelar assinatura",
                    systemImage: subscription.isCancelled ? "arrow.uturn.backward.circle" : "xmark.circle"
                )
                .foregroundStyle(subscription.isCancelled ? Color.success : Color.warning)
            }

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Excluir assinatura", systemImage: "trash")
            }
        }
    }

    private var categoryBinding: Binding<CategoryType> {
        Binding(
            get: { subscription.categoryType },
            set: { subscription.category = $0.rawValue }
        )
    }
}
