//
//  SubscriptionDetailView.swift
//  SubCheck
//

import SwiftUI
import SwiftData

struct SubscriptionDetailView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var subscription: Subscription

    @State private var showDeleteConfirmation = false

    var body: some View {
        Form {
            headerSection
            detailsSection
            billingSection
            reminderSection
            actionsSection
        }
        .navigationTitle(subscription.name)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: subscription.enableReminders) { _, _ in
            NotificationService.shared.scheduleNotification(for: subscription)
            try? context.save()
        }
        .onChange(of: subscription.daysNoticeBefore) { _, _ in
            NotificationService.shared.scheduleNotification(for: subscription)
            try? context.save()
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
                ZStack {
                    Circle()
                        .fill(subscription.categoryColor.opacity(0.16))
                        .frame(width: 60, height: 60)
                    Image(systemName: subscription.categoryIcon)
                        .font(.title2)
                        .foregroundStyle(subscription.categoryColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(Money.format(subscription.cost, code: subscription.currencyCode))
                        .font(.title2.weight(.bold))
                        .contentTransition(.numericText())
                    Text("\(Money.format(subscription.monthlyCost))/mês · \(Money.compact(subscription.yearlyCost))/ano")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .padding(.vertical, Spacing.xs)
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
                    Text(frequency.rawValue).tag(frequency)
                }
            }

            DatePicker("Início", selection: $subscription.startDate, displayedComponents: .date)

            LabeledContent("Valor") {
                TextField("0,00", value: $subscription.cost, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
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
                     ? "Hoje"
                     : "\(subscription.daysUntilNextBilling) dias")
                    .foregroundStyle(subscription.daysUntilNextBilling <= 3 ? Color.danger : Color.textPrimary)
            }
        }
    }

    private var reminderSection: some View {
        Section("Lembrete") {
            Toggle("Notificar antes da cobrança", isOn: $subscription.enableReminders)

            if subscription.enableReminders {
                Stepper(value: $subscription.daysNoticeBefore, in: 1...7) {
                    Text("Avisar \(subscription.daysNoticeBefore) dia(s) antes")
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
