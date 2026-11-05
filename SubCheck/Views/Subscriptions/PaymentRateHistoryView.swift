//
//  PaymentRateHistoryView.swift
//  SubCheck
//
//  Histórico de pagamentos de uma assinatura em moeda estrangeira: cada
//  cobrança guarda a cotação do dia, e a tela mostra quanto o câmbio mudou
//  o custo desde então (pagou US$ 10 a R$ 5,00, hoje seria R$ 4,00).
//

import Charts
import SwiftData
import SwiftUI

struct PaymentRateHistoryView: View {

    let subscription: Subscription

    @Query private var records: [PaymentRecord]

    private var service: CurrencyService { .shared }

    init(subscription: Subscription) {
        self.subscription = subscription
        let id = subscription.id
        _records = Query(
            filter: #Predicate<PaymentRecord> { $0.subscriptionID == id },
            sort: \.paidAt,
            order: .reverse
        )
    }

    private var base: String { service.baseCode }
    private var code: String { subscription.currencyCode }

    private var impacts: [ExchangeImpact] {
        records.compactMap { $0.impact(using: service) }
    }

    private var series: [(date: Date, rate: Double)] {
        service.history.series(from: code, to: base)
    }

    var body: some View {
        List {
            summarySection
            if series.count >= 2 { chartSection }
            paymentsSection
        }
        .navigationTitle("Histórico e cotação")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Resumo

    private var summarySection: some View {
        Section {
            LabeledContent("Cotação hoje") {
                Text(rateText(service.convert(1, from: code, to: base)))
            }

            let total = ExchangeImpact.total(impacts)
            if !impacts.isEmpty {
                LabeledContent("Pago (cotação da época)") {
                    Text(Money.format(total.paid, code: base))
                }
                LabeledContent("Custaria hoje") {
                    Text(Money.format(total.current, code: base))
                }
                LabeledContent("Diferença") {
                    deltaLabel(total.current - total.paid, fraction: total.paid > 0 ? (total.current - total.paid) / total.paid : 0)
                }
            }
        } footer: {
            Text(impacts.isEmpty
                 ? "Ainda não há cotação registrada. Cada novo pagamento guarda a cotação do dia."
                 : "A cotação da época é a que o app baixou no dia de cada pagamento.")
        }
    }

    // MARK: - Gráfico

    private var chartSection: some View {
        Section("Cotação ao longo do tempo") {
            Chart(series, id: \.date) { point in
                LineMark(
                    x: .value("Dia", point.date),
                    y: .value("Cotação", point.rate)
                )
                .foregroundStyle(Color.brand)
                .interpolationMethod(.monotone)

                // Marca no gráfico os dias em que houve pagamento.
                ForEach(records.filter { $0.rateToBase > 0 }, id: \.id) { record in
                    PointMark(
                        x: .value("Dia", record.paidAt),
                        y: .value("Cotação", record.rateToBase)
                    )
                    .foregroundStyle(Color.warning)
                }
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(height: 160)
            .padding(.vertical, Spacing.xs)
        }
    }

    // MARK: - Pagamentos

    private var paymentsSection: some View {
        Section("Pagamentos") {
            if records.isEmpty {
                Text("Nenhum pagamento registrado ainda.")
                    .foregroundStyle(Color.textSecondary)
            }
            ForEach(records) { record in
                row(record)
            }
        }
    }

    private func row(_ record: PaymentRecord) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.paidAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline.weight(.semibold))
                Text(Money.format(record.amount, code: record.currencyCode))
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                if record.rateToBase > 0 {
                    Text(L.t("Cotação da época: %@", rateText(record.rateToBase, code: record.baseCodeAtPayment)))
                        .font(.caption2)
                        .foregroundStyle(Color.textTertiary)
                } else {
                    Text("Sem cotação registrada")
                        .font(.caption2)
                        .foregroundStyle(Color.textTertiary)
                }
            }

            Spacer(minLength: Spacing.sm)

            if let impact = record.impact(using: service) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Money.format(impact.paidInBase, code: base))
                        .font(.subheadline.weight(.semibold))
                    deltaLabel(impact.difference, fraction: impact.fraction)
                        .font(.caption2)
                }
            }
        }
    }

    // MARK: - Auxiliares

    /// Verde quando hoje sairia mais barato, laranja quando mais caro.
    private func deltaLabel(_ difference: Double, fraction: Double) -> some View {
        let color: Color = abs(difference) < 0.005
            ? Color.textSecondary
            : (difference < 0 ? Color.success : Color.warning)
        return Text("\(Money.signed(difference, code: base)) (\(Money.percent(fraction)))")
            .foregroundStyle(color)
            .monospacedDigit()
    }

    private func rateText(_ rate: Double, code baseCode: String? = nil) -> String {
        let target = (baseCode?.isEmpty == false ? baseCode! : base)
        let value = rate.formatted(
            .currency(code: target).locale(L.current).precision(.fractionLength(2...4))
        )
        return "1 \(code) = \(value)"
    }
}
