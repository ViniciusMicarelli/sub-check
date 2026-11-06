//
//  BillEntrySheet.swift
//  SubCheck
//
//  O momento principal: a conta venceu e a pessoa digita o valor. Para
//  contas fixas o valor já vem preenchido.
//

import SwiftData
import SwiftUI

struct BillEntrySheet: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let entry: BillEntry

    @Query private var pastEntries: [BillEntry]
    @Query private var matchingBills: [Bill]

    @State private var amount: Double?
    @State private var paid: Bool
    @State private var paidAt: Date
    @FocusState private var amountFocused: Bool

    init(entry: BillEntry) {
        self.entry = entry
        _amount = State(initialValue: entry.amount > 0 ? entry.amount : nil)
        _paid = State(initialValue: true)
        _paidAt = State(initialValue: min(entry.paidAt ?? Date(), Date()))

        let id = entry.billID
        _pastEntries = Query(
            filter: #Predicate<BillEntry> { $0.billID == id && $0.isPaid },
            sort: \.monthStart,
            order: .reverse
        )
        _matchingBills = Query(filter: #Predicate<Bill> { $0.id == id })
    }

    private var bill: Bill? { matchingBills.first }

    /// Meses anteriores pagos (sem o atual), do mais recente para o mais antigo.
    private var previous: [BillEntry] {
        pastEntries.filter { $0.monthStart < entry.monthStart && $0.amount > 0 }
    }

    private var previousAmounts: [Double] { previous.map(\.amount) }

    private var estimate: Double {
        BillMath.estimate(expected: bill?.expectedAmount ?? 0, previous: previousAmounts)
    }

    private var change: Double? {
        BillMath.change(current: amount ?? 0, previous: previousAmounts)
    }

    private var canSave: Bool { (amount ?? 0) > 0 }

    var body: some View {
        NavigationStack {
            Form {
                headerSection
                amountSection
                if paid { paidSection }
                historySection

                if entry.isPaid {
                    Section {
                        Button(role: .destructive) {
                            BillLedger.unpay(entry, in: context)
                            BillLedger.refreshSurfaces(in: context)
                            dismiss()
                        } label: {
                            Label("Desmarcar pagamento", systemImage: "arrow.uturn.backward")
                        }
                    }
                }
            }
            .navigationTitle(entry.billName)
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
            .onAppear { amountFocused = (entry.amount == 0) }
        }
        .presentationDetents([.large])
    }

    // MARK: - Seções

    private var headerSection: some View {
        Section {
            HStack(spacing: Spacing.md) {
                BillBadge(category: entry.category, size: 46)
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.billName)
                        .font(.headline)
                    Text(L.t("Vence em %@", entry.dueDate.formatted(Date.FormatStyle().day().month(.wide).locale(L.current))))
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .padding(.vertical, Spacing.xs)
        }
    }

    private var amountSection: some View {
        Section {
            HStack {
                Text(Money.symbol)
                    .foregroundStyle(Color.textSecondary)
                TextField(
                    estimate > 0 ? Money.plain(estimate) : "0,00",
                    value: $amount,
                    format: .number.precision(.fractionLength(0...2))
                )
                .keyboardType(.decimalPad)
                .font(.title2.weight(.semibold))
                .focused($amountFocused)
            }

            if let change, abs(change) >= 0.03 {
                Label(
                    change > 0
                        ? L.t("%@ acima da média dos últimos meses", Money.percentPlain(abs(change)))
                        : L.t("%@ abaixo da média dos últimos meses", Money.percentPlain(abs(change))),
                    systemImage: change > 0 ? "arrow.up.right" : "arrow.down.right"
                )
                .font(.footnote.weight(.semibold))
                .foregroundStyle(change > 0 ? Color.warning : Color.success)
            }

            Toggle("Já paguei", isOn: $paid)
        } header: {
            Text("Valor da conta")
        } footer: {
            Text(paid
                 ? L.t("Ao salvar, a conta fica como paga neste mês.")
                 : L.t("O valor entra na previsão do mês, mas a conta continua em aberto."))
        }
    }

    private var paidSection: some View {
        Section {
            DatePicker("Pago em", selection: $paidAt, in: ...Date(), displayedComponents: .date)
        }
    }

    @ViewBuilder
    private var historySection: some View {
        if !previous.isEmpty {
            Section("Meses anteriores") {
                ForEach(previous.prefix(3), id: \.id) { past in
                    LabeledContent(
                        past.monthStart.formatted(Date.FormatStyle().month(.wide).year().locale(L.current)).capitalizedFirst,
                        value: Money.format(past.amount)
                    )
                }
                if let bill {
                    NavigationLink {
                        BillDetailView(bill: bill)
                    } label: {
                        Label("Histórico e editar conta", systemImage: "chart.bar.xaxis")
                    }
                }
            }
        } else if let bill {
            Section {
                NavigationLink {
                    BillDetailView(bill: bill)
                } label: {
                    Label("Histórico e editar conta", systemImage: "chart.bar.xaxis")
                }
            }
        }
    }

    // MARK: - Ação

    private func save() {
        guard let amount, amount > 0 else { return }
        BillLedger.record(entry, amount: amount, paid: paid, paidAt: paidAt, in: context)
        BillLedger.refreshSurfaces(in: context)
        Haptics.success()
        dismiss()
    }
}
