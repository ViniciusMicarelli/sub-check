//
//  BillCalendarView.swift
//  SubCheck
//
//  Calendário do mês: cada dia mostra pontinhos do que vence (conta paga,
//  a pagar, atrasada, cobrança de assinatura e salário). Tocar num dia lista
//  o que acontece nele.
//

import SwiftUI

struct BillCalendarView: View {

    let month: Date
    let occurrences: [BillOccurrence]
    let charges: [SubscriptionCharge]
    let salary: Double
    let salaryDay: Int
    let onSelect: (BillOccurrence) -> Void

    @State private var selectedDay: Date?

    private var calendar: Calendar { .current }
    private var weeks: [[Date?]] { BillCalendar.weeks(for: month) }

    private var effectiveSelection: Date {
        if let selectedDay, calendar.isDate(selectedDay, equalTo: month, toGranularity: .month) { return selectedDay }
        let today = Date()
        if calendar.isDate(today, equalTo: month, toGranularity: .month) { return today }
        return BillSchedule.monthStart(of: month)
    }

    private func bills(on day: Date) -> [BillOccurrence] {
        occurrences.filter { calendar.isDate($0.dueDate, inSameDayAs: day) }
    }

    private func subscriptionCharges(on day: Date) -> [SubscriptionCharge] {
        charges.filter { calendar.isDate($0.date, inSameDayAs: day) }
    }

    private func isPayday(_ day: Date) -> Bool {
        guard salary > 0 else { return false }
        return calendar.isDate(
            BillSchedule.dueDate(day: salaryDay, inMonthOf: month), inSameDayAs: day
        )
    }

    /// Cores dos pontinhos de um dia, sem repetir.
    private func dots(for day: Date) -> [Color] {
        var result: [Color] = []
        for item in bills(on: day) {
            let color: Color = switch item.status {
            case .paid: Color.success
            case .overdue: Color.danger
            case .dueToday: Color.warning
            case .upcoming: Color.info
            }
            if !result.contains(color) { result.append(color) }
        }
        if !subscriptionCharges(on: day).isEmpty { result.append(Color.brand) }
        if isPayday(day) { result.append(Color.brandMint) }
        return Array(result.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(spacing: Spacing.sm) {
                HStack(spacing: 0) {
                    ForEach(Array(BillCalendar.weekdaySymbols().enumerated()), id: \.offset) { _, symbol in
                        Text(symbol)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.textTertiary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .accessibilityHidden(true)

                ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                    HStack(spacing: 0) {
                        ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                            cell(day)
                        }
                    }
                }
            }
            .cardSurface(padding: Spacing.md)

            legend

            dayDetail
        }
    }

    // MARK: - Célula

    @ViewBuilder
    private func cell(_ day: Date?) -> some View {
        if let day {
            let selected = calendar.isDate(day, inSameDayAs: effectiveSelection)
            let isToday = calendar.isDateInToday(day)
            Button {
                Haptics.impact(.light)
                withAnimation(.snappy) { selectedDay = day }
            } label: {
                VStack(spacing: 3) {
                    Text("\(calendar.component(.day, from: day))")
                        .font(.subheadline.weight(selected || isToday ? .bold : .regular))
                        .foregroundStyle(selected ? Color.white : (isToday ? Color.brand : Color.textPrimary))
                        .frame(width: 32, height: 32)
                        .background {
                            if selected {
                                Circle().fill(Color.brandGradient)
                            } else if isToday {
                                Circle().stroke(Color.brand, lineWidth: 1.5)
                            }
                        }

                    HStack(spacing: 2) {
                        ForEach(Array(dots(for: day).enumerated()), id: \.offset) { _, color in
                            Circle().fill(color).frame(width: 5, height: 5)
                        }
                    }
                    .frame(height: 5)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityLabel(for: day))
            .accessibilityAddTraits(selected ? .isSelected : [])
        } else {
            Color.clear.frame(maxWidth: .infinity, minHeight: 44)
        }
    }

    private func accessibilityLabel(for day: Date) -> String {
        let date = day.formatted(Date.FormatStyle().weekday(.wide).day().month(.wide).locale(L.current))
        let count = bills(on: day).count + subscriptionCharges(on: day).count
        return count == 0 ? date : L.t("%@, %lld item(ns)", date, count)
    }

    private var legend: some View {
        HStack(spacing: Spacing.md) {
            legendItem(Color.info, L.t("A pagar"))
            legendItem(Color.success, L.t("Paga"))
            legendItem(Color.danger, L.t("Atrasada"))
            legendItem(Color.brand, L.t("Assinatura"))
            if salary > 0 { legendItem(Color.brandMint, L.t("Salário")) }
        }
        .font(.caption2)
        .foregroundStyle(Color.textSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.xs)
    }

    private func legendItem(_ color: Color, _ title: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(title)
        }
    }

    // MARK: - Detalhe do dia

    @ViewBuilder
    private var dayDetail: some View {
        let day = effectiveSelection
        let dayBills = bills(on: day)
        let dayCharges = subscriptionCharges(on: day)
        let payday = isPayday(day)

        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(day.formatted(Date.FormatStyle().weekday(.wide).day().month(.wide).locale(L.current)).capitalizedFirst)
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal, Spacing.xs)

            if dayBills.isEmpty && dayCharges.isEmpty && !payday {
                Text("Nada vence neste dia.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity)
                    .cardSurface()
            } else {
                VStack(spacing: 0) {
                    if payday {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: "banknote.fill")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 42, height: 42)
                                .background(Color.brandMint.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Salário").font(.body.weight(.semibold))
                                Text("Cai na conta").font(.caption).foregroundStyle(Color.textSecondary)
                            }
                            Spacer()
                            Text(Money.format(salary))
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Color.success)
                                .monospacedDigit()
                        }
                        .padding(.vertical, Spacing.xs)
                        if !dayBills.isEmpty || !dayCharges.isEmpty { Divider().padding(.leading, 54) }
                    }

                    ForEach(Array(dayBills.enumerated()), id: \.element.id) { index, item in
                        Button { onSelect(item) } label: { BillRow(occurrence: item) }
                            .buttonStyle(.plain)
                        if index < dayBills.count - 1 || !dayCharges.isEmpty { Divider().padding(.leading, 54) }
                    }

                    ForEach(Array(dayCharges.enumerated()), id: \.element.id) { index, charge in
                        HStack(spacing: Spacing.md) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 42, height: 42)
                                .background(Color.brandGradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(charge.name).font(.body.weight(.semibold))
                                Text("Assinatura").font(.caption).foregroundStyle(Color.textSecondary)
                            }
                            Spacer()
                            Text(Money.format(charge.amount))
                                .font(.body.weight(.semibold))
                                .monospacedDigit()
                        }
                        .padding(.vertical, Spacing.xs)
                        if index < dayCharges.count - 1 { Divider().padding(.leading, 54) }
                    }
                }
                .cardSurface(padding: Spacing.md)
            }
        }
    }
}
