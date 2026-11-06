//
//  BillDuePromptSheet.swift
//  SubCheck
//
//  O recado de dentro do app: "a conta de água venceu, quer informar o valor
//  agora ou depois?". Aparece ao abrir o app quando há conta vencida ou
//  vencendo hoje sem pagamento. "Depois" adia até amanhã.
//

import SwiftData
import SwiftUI

struct BillDuePromptSheet: View {

    @Environment(\.dismiss) private var dismiss
    @Query private var entries: [BillEntry]

    private var router = AppRouter.shared

    private var due: [BillEntry] { BillPlanning.dueEntries(entries) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Image(systemName: "bell.badge.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.warning.gradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .accessibilityHidden(true)

                        Text(due.count == 1 ? "Uma conta precisa de você" : "Contas para informar")
                            .font(.title2.weight(.bold))
                        Text("O valor ainda não foi informado. Preencha agora ou deixe para mais tarde.")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    }

                    VStack(spacing: 0) {
                        ForEach(Array(due.enumerated()), id: \.element.id) { index, entry in
                            Button {
                                open(entry)
                            } label: {
                                BillRow(entry: entry, estimate: 0)
                            }
                            .buttonStyle(.plain)

                            if index < due.count - 1 {
                                Divider().padding(.leading, 54)
                            }
                        }
                    }
                    .cardSurface(padding: Spacing.md)

                    VStack(spacing: Spacing.sm) {
                        Button {
                            if let first = due.first { open(first) } else { dismiss() }
                        } label: {
                            Text("Preencher agora")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.lg)
                                .background(Color.brandGradient, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                        }
                        .buttonStyle(PressableStyle())

                        Button {
                            snoozeForToday()
                            dismiss()
                        } label: {
                            Text("Depois")
                                .font(.headline)
                                .foregroundStyle(Color.brand)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.lg)
                                .background(Color.brand.opacity(0.1), in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                        }
                        .buttonStyle(PressableStyle())

                        Text("Se escolher depois, o aviso volta amanhã.")
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                    }
                }
                .padding(Spacing.lg)
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        // Fechar arrastando também adia: não vamos insistir no mesmo dia.
        .onDisappear { snoozeForToday() }
    }

    private func open(_ entry: BillEntry) {
        dismiss()
        router.openBill(entry.billID)
    }

    private func snoozeForToday() {
        UserDefaults.standard.set(BillPrompt.dayNumber(Date()), forKey: BillPrompt.snoozeKey)
    }
}
