//
//  HistoryView.swift
//  SubCheck
//
//  Everything the user has deleted, so cancellations are traceable.
//

import SwiftUI
import SwiftData

struct HistoryView: View {

    @Environment(\.modelContext) private var context
    @Query(sort: \DeletedSubscription.deletedDate, order: .reverse)
    private var records: [DeletedSubscription]

    @State private var showClearConfirmation = false

    private var totalEnded: Double {
        records.reduce(0) { $0 + $1.cost }
    }

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    ScrollView {
                        EmptyStateView(
                            icon: "clock.arrow.circlepath",
                            title: L.t("Histórico vazio"),
                            message: L.t("Assinaturas excluídas aparecem aqui para referência.")
                        )
                        .cardSurface()
                        .padding(Spacing.lg)
                    }
                    .background(Color.appBackground)
                } else {
                    List {
                        Section {
                            LabeledContent("Assinaturas encerradas", value: "\(records.count)")
                            LabeledContent("Valor encerrado", value: Money.format(totalEnded))
                        }

                        Section("Registros") {
                            ForEach(records) { record in
                                HistoryRow(record: record)
                            }
                            .onDelete(perform: delete)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Histórico")
            .toolbar {
                if !records.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            showClearConfirmation = true
                        } label: {
                            Label("Limpar", systemImage: "trash")
                        }
                    }
                }
            }
            .confirmationDialog(
                "Limpar todo o histórico?",
                isPresented: $showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Limpar", role: .destructive) {
                    Haptics.warning()
                    try? context.delete(model: DeletedSubscription.self)
                    try? context.save()
                }
                Button("Cancelar", role: .cancel) {}
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(records[index])
        }
        try? context.save()
    }
}

private struct HistoryRow: View {

    let record: DeletedSubscription

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "xmark.circle.fill")
                .font(.title3)
                .foregroundStyle(Color.danger.opacity(0.8))

            VStack(alignment: .leading, spacing: 2) {
                Text(record.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                Text(record.deletedDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer(minLength: 0)

            Text(Money.format(record.cost, code: record.currencyCode))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.vertical, 4)
    }
}
