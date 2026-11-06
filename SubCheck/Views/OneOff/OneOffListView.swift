//
//  OneOffListView.swift
//  SubCheck
//
//  Pagamentos avulsos agrupados por mês, com o total de cada um.
//

import SwiftUI
import SwiftData

struct OneOffListView: View {

    @Environment(\.modelContext) private var context
    @Query(sort: \OneOffPayment.paidAt, order: .reverse) private var payments: [OneOffPayment]

    @State private var showAdd = false
    @State private var editing: OneOffPayment?

    private var service: CurrencyService { .shared }

    private var months: [(month: Date, items: [OneOffPayment])] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: payments) {
            cal.date(from: cal.dateComponents([.year, .month], from: $0.paidAt)) ?? $0.paidAt
        }
        return grouped.keys.sorted(by: >).map { ($0, grouped[$0] ?? []) }
    }

    var body: some View {
        List {
            if payments.isEmpty {
                EmptyStateView(
                    icon: "bag",
                    title: L.t("Nenhum pagamento avulso"),
                    message: L.t("Registre o que você pagou uma vez só, como um mês de um app que você não usou mais."),
                    actionTitle: L.t("Registrar pagamento")
                ) { showAdd = true }
                .listRowBackground(Color.clear)
            }

            ForEach(months, id: \.month) { group in
                Section {
                    ForEach(group.items) { payment in
                        row(payment)
                            .contentShape(Rectangle())
                            .onTapGesture { editing = payment }
                    }
                    .onDelete { offsets in
                        for index in offsets { context.delete(group.items[index]) }
                        context.saveReporting()
                    }
                } header: {
                    HStack {
                        Text(group.month.formatted(.dateTime.month(.wide).year()).capitalizedFirst)
                        Spacer()
                        Text(Money.format(group.items.reduce(0) { $0 + $1.baseAmount(in: service) }))
                            .monospacedDigit()
                    }
                }
            }
        }
        .navigationTitle("Pagamentos avulsos")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: { Label("Registrar", systemImage: "plus") }
            }
        }
        .sheet(isPresented: $showAdd) { AddOneOffView() }
        .sheet(item: $editing) { AddOneOffView(editing: $0) }
    }

    private func row(_ payment: OneOffPayment) -> some View {
        HStack(spacing: Spacing.md) {
            SubscriptionIconView(
                icon: payment.iconRaw.flatMap(SubscriptionIcon.init(rawValue:))
                    ?? BrandIconCatalog.match(name: payment.name)?.icon
                    ?? .symbol(payment.categoryType.icon),
                fallbackColor: payment.categoryType.color,
                size: 38
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(payment.name).font(.subheadline.weight(.semibold))
                Text(payment.paidAt.formatted(date: .abbreviated, time: .omitted)
                     + (payment.note.isEmpty ? "" : " · " + payment.note))
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 2) {
                Text(Money.format(payment.amount, code: payment.currencyCode))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                if payment.currencyCode.uppercased() != service.baseCode.uppercased() {
                    Text("≈ " + Money.format(payment.baseAmount(in: service)))
                        .font(.caption2)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }
}
