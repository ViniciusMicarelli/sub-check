//
//  OneOffCard.swift
//  SubCheck
//
//  Resumo dos pagamentos avulsos do mês, com atalho para registrar um novo.
//

import SwiftUI

struct OneOffCard: View {

    let payments: [OneOffPayment]
    var onAdd: () -> Void

    private var service: CurrencyService { .shared }

    private var monthTotal: Double {
        OneOffPayments.total(payments, inMonthOf: Date(), service: service)
    }

    private var monthCount: Int {
        payments.filter { Calendar.current.isDate($0.paidAt, equalTo: Date(), toGranularity: .month) }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "bag.fill")
                    .foregroundStyle(Color.brand)
                Text("Pagamentos avulsos")
                    .font(.headline)
                Spacer()
                Button(action: onAdd) {
                    Label("Registrar", systemImage: "plus")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if monthCount == 0 {
                Text("Nada avulso neste mês. Pagou algo uma vez só? Registre para ver o custo real.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            } else {
                HStack(alignment: .firstTextBaseline) {
                    Text(Money.format(monthTotal))
                        .font(.title2.weight(.bold))
                        .monospacedDigit()
                    Text(L.t("em %lld pagamento(s) neste mês", monthCount))
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            NavigationLink {
                OneOffListView()
            } label: {
                HStack {
                    Text(payments.isEmpty ? L.t("Ver tela") : L.t("Ver todos (%lld)", payments.count))
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                }
                .foregroundStyle(Color.brand)
            }
        }
        .padding(Spacing.lg)
        .cardSurface(padding: 0)
    }
}
