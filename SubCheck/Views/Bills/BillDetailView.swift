//
//  BillDetailView.swift
//  SubCheck
//
//  Histórico de uma conta: como o valor evoluiu mês a mês. Serve para
//  perceber quando a luz ou a água subiram.
//

import Charts
import SwiftData
import SwiftUI

struct BillDetailView: View {

    let bill: Bill

    @Query private var entries: [BillEntry]
    @State private var showEdit = false

    init(bill: Bill) {
        self.bill = bill
        let id = bill.id
        _entries = Query(
            filter: #Predicate<BillEntry> { $0.billID == id && !$0.isSkipped },
            sort: \.monthStart,
            order: .reverse
        )
    }

    private var paidEntries: [BillEntry] { entries.filter { $0.isPaid && $0.amount > 0 } }

    /// Últimos meses pagos, do mais antigo para o mais novo (ordem do gráfico).
    private var chartEntries: [BillEntry] { Array(paidEntries.prefix(6).reversed()) }

    private var average: Double {
        guard !paidEntries.isEmpty else { return 0 }
        let recent = paidEntries.prefix(6)
        return recent.reduce(0) { $0 + $1.amount } / Double(recent.count)
    }

    private func monthLabel(_ date: Date, wide: Bool = false) -> String {
        let style = wide
            ? Date.FormatStyle().month(.wide).year()
            : Date.FormatStyle().month(.abbreviated)
        return date.formatted(style.locale(L.current)).capitalizedFirst
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: Spacing.md) {
                    BillBadge(category: bill.category, size: 50)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(bill.name).font(.headline)
                        Text(L.t("Vence todo dia %lld", bill.dueDay))
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                        Text(bill.isFixed ? L.t("Valor fixo") : L.t("Varia todo mês"))
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                    }
                }
                .padding(.vertical, Spacing.xs)
            }

            if chartEntries.count >= 2 {
                Section("Últimos meses") {
                    Chart(chartEntries, id: \.id) { entry in
                        BarMark(
                            x: .value("Mês", monthLabel(entry.monthStart)),
                            y: .value("Valor", entry.amount)
                        )
                        .foregroundStyle(bill.category.color.gradient)
                        .cornerRadius(5)

                        RuleMark(y: .value("Média", average))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .foregroundStyle(Color.textTertiary)
                    }
                    .frame(height: 170)
                    .padding(.vertical, Spacing.xs)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("Últimos meses"))
                    .accessibilityValue(
                        chartEntries.map { "\(monthLabel($0.monthStart)): \(Money.format($0.amount))" }
                            .joined(separator: ", ")
                    )

                    LabeledContent("Média", value: Money.format(average))
                    if let high = paidEntries.map(\.amount).max(), let low = paidEntries.map(\.amount).min() {
                        LabeledContent("Maior", value: Money.format(high))
                        LabeledContent("Menor", value: Money.format(low))
                    }
                }
            }

            Section("Todos os meses") {
                if entries.isEmpty {
                    Text("Ainda sem meses registrados.")
                        .foregroundStyle(Color.textSecondary)
                }
                ForEach(entries, id: \.id) { entry in
                    LabeledContent(monthLabel(entry.monthStart, wide: true)) {
                        if entry.isPaid {
                            Text(Money.format(entry.amount)).monospacedDigit()
                        } else if entry.amount > 0 {
                            Text(L.t("%@ (em aberto)", Money.format(entry.amount))).foregroundStyle(Color.warning)
                        } else {
                            Text("—").foregroundStyle(Color.textTertiary)
                        }
                    }
                }
            }
        }
        .navigationTitle(bill.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Editar") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit) { AddBillView(bill: bill) }
    }
}
