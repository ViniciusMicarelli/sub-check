//
//  BillEvolutionView.swift
//  SubCheck
//
//  Como as contas evoluíram mês a mês: total por categoria, comparação com o
//  mês anterior e as contas que mais subiram ou caíram.
//

import Charts
import SwiftUI

struct BillEvolutionView: View {

    let month: Date
    let totals: [BillMonthTotal]
    let changes: [BillChange]
    let salary: Double

    private func label(_ date: Date) -> String {
        date.formatted(Date.FormatStyle().month(.abbreviated).locale(L.current)).capitalizedFirst
    }

    private var current: BillMonthTotal? { totals.last }
    private var previous: BillMonthTotal? { totals.dropLast().last }

    /// Média dos meses anteriores que têm algum valor.
    private var average: Double {
        let past = totals.dropLast().map(\.total).filter { $0 > 0 }
        return past.isEmpty ? 0 : past.reduce(0, +) / Double(past.count)
    }

    private var variation: Double? {
        guard let current, let previous, previous.total > 0 else { return nil }
        return current.total / previous.total - 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            chartCard
            summaryCard
            if !changes.isEmpty { changesCard }
        }
    }

    // MARK: - Gráfico

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Contas por mês")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)

            if totals.allSatisfy({ $0.total == 0 }) {
                Text("Ainda não há valores informados para mostrar a evolução.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            } else {
                Chart {
                    ForEach(totals) { total in
                        ForEach(total.byCategory, id: \.category) { part in
                            BarMark(
                                x: .value("Mês", label(total.month)),
                                y: .value("Valor", part.amount)
                            )
                            .foregroundStyle(part.category.color)
                            .opacity(total.isProjected ? 0.55 : 1)
                            .cornerRadius(3)
                        }
                    }

                    if average > 0 {
                        RuleMark(y: .value("Média", average))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .foregroundStyle(Color.textTertiary)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) { Text(Money.compact(v)) }
                        }
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Contas por mês"))
                .accessibilityValue(
                    totals.map { "\(label($0.month)): \(Money.format($0.total))" }.joined(separator: ", ")
                )

                if totals.contains(where: \.isProjected) {
                    Label("Barras claras são previsão com a média dos meses anteriores.", systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    // MARK: - Resumo

    private var summaryCard: some View {
        VStack(spacing: 0) {
            if let current {
                row(L.t("Total do mês"), Money.format(current.total))
                Divider()
            }
            if let variation, let current, let previous {
                HStack {
                    Text("Contra o mês anterior")
                        .foregroundStyle(Color.textSecondary)
                    Spacer()
                    Label(
                        "\(Money.signed(current.total - previous.total)) (\(Money.percent(variation)))",
                        systemImage: variation > 0 ? "arrow.up.right" : "arrow.down.right"
                    )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(variation > 0 ? Color.warning : Color.success)
                    .monospacedDigit()
                }
                .padding(.vertical, Spacing.sm)
                Divider()
            }
            if average > 0 {
                row(L.t("Média dos meses anteriores"), Money.format(average))
                Divider()
            }
            if salary > 0, let current, current.total > 0 {
                row(L.t("Do seu salário"), Money.percentPlain(current.total / salary))
            }
        }
        .font(.subheadline)
        .cardSurface(padding: Spacing.md)
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(Color.textSecondary)
            Spacer()
            Text(value).font(.subheadline.weight(.semibold)).foregroundStyle(Color.textPrimary).monospacedDigit()
        }
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Quem mudou

    private var changesCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("O que mudou")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal, Spacing.xs)

            VStack(spacing: 0) {
                ForEach(Array(changes.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: Spacing.md) {
                        BillBadge(category: item.category, size: 38)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name).font(.body.weight(.semibold))
                            Text(L.t("Média %@ → %@", Money.format(item.average), Money.format(item.current)))
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }
                        Spacer()
                        Label(Money.percent(item.change), systemImage: item.change > 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(item.change > 0 ? Color.warning : Color.success)
                    }
                    .padding(.vertical, Spacing.xs)
                    .accessibilityElement(children: .combine)

                    if index < changes.count - 1 { Divider().padding(.leading, 50) }
                }
            }
            .cardSurface(padding: Spacing.md)
        }
    }
}
