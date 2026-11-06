//
//  BillCalendar.swift
//  SubCheck
//
//  O "mês" das contas: o que vence em qualquer mês (passado, atual ou
//  futuro), as cobranças das assinaturas no mesmo mês, a grade do calendário e
//  a evolução dos totais. Sem telas, para poder ser testado.
//

import Foundation

// MARK: - Ocorrência de uma conta num mês

/// Uma conta num mês: vem da linha salva (`entry`) ou, em mês futuro sem
/// linha ainda, é uma previsão feita com o valor fixo ou a média.
struct BillOccurrence: Identifiable {
    let billID: UUID
    let name: String
    let category: BillCategory
    let dueDate: Date
    /// Valor informado ou, sem ele, a estimativa.
    let amount: Double
    let isEstimate: Bool
    let status: BillStatus
    let paidAt: Date?
    let entry: BillEntry?

    var id: String { "\(billID.uuidString)-\(Int(dueDate.timeIntervalSince1970))" }
    /// Mês futuro que ainda não tem linha: só previsão.
    var isProjected: Bool { entry == nil }
}

enum BillCalendar {

    /// Contas do mês de `month`. Meses passados mostram só o que foi
    /// registrado; o atual e os futuros também mostram as contas ativas que
    /// ainda não têm linha (previstas).
    static func occurrences(
        bills: [Bill],
        entries: [BillEntry],
        month: Date,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [BillOccurrence] {
        let start = BillSchedule.monthStart(of: month, calendar: calendar)
        let currentStart = BillSchedule.monthStart(of: now, calendar: calendar)
        let history = BillPlanning.history(of: entries, before: start)
        let byID = Dictionary(bills.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        var result: [BillOccurrence] = []
        let inMonth = entries.filter { $0.monthStart == start }

        for entry in inMonth where !entry.isSkipped {
            let estimate = BillMath.estimate(
                expected: byID[entry.billID]?.expectedAmount ?? 0,
                previous: history[entry.billID] ?? []
            )
            result.append(BillOccurrence(
                billID: entry.billID, name: entry.billName, category: entry.category,
                dueDate: entry.dueDate,
                amount: entry.amount > 0 ? entry.amount : estimate,
                isEstimate: entry.amount <= 0,
                status: BillMath.status(isPaid: entry.isPaid, dueDate: entry.dueDate, now: now, calendar: calendar),
                paidAt: entry.paidAt, entry: entry
            ))
        }

        if start >= currentStart {
            let have = Set(inMonth.map(\.billID))   // inclui as puladas: não reaparecem
            for bill in bills where bill.isActive && !have.contains(bill.id) {
                let due = BillSchedule.dueDate(day: bill.dueDay, inMonthOf: start, calendar: calendar)
                let estimate = BillMath.estimate(expected: bill.expectedAmount, previous: history[bill.id] ?? [])
                result.append(BillOccurrence(
                    billID: bill.id, name: bill.name, category: bill.category, dueDate: due,
                    amount: estimate, isEstimate: true,
                    status: BillMath.status(isPaid: false, dueDate: due, now: now, calendar: calendar),
                    paidAt: nil, entry: nil
                ))
            }
        }
        return result.sorted { $0.dueDate < $1.dueDate }
    }

    // MARK: Grade do calendário

    /// Semanas do mês, de 7 posições cada; `nil` são os dias de fora do mês.
    static func weeks(for month: Date, calendar: Calendar = .current) -> [[Date?]] {
        let start = BillSchedule.monthStart(of: month, calendar: calendar)
        guard let length = calendar.range(of: .day, in: .month, for: start)?.count else { return [] }
        let weekday = calendar.component(.weekday, from: start)
        let leading = (weekday - calendar.firstWeekday + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: leading)
        for offset in 0..<length {
            days.append(calendar.date(byAdding: .day, value: offset, to: start))
        }
        while days.count % 7 != 0 { days.append(nil) }
        return stride(from: 0, to: days.count, by: 7).map { Array(days[$0..<$0 + 7]) }
    }

    /// Iniciais dos dias da semana na ordem do calendário do usuário.
    static func weekdaySymbols(calendar: Calendar = .current) -> [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }
}

// MARK: - Assinaturas no calendário

struct SubscriptionCharge: Identifiable, Equatable {
    let id: String
    let name: String
    let amount: Double
    let date: Date
}

enum SubscriptionCalendar {

    /// Cobranças das assinaturas ativas dentro do mês. Segue a mesma regra do
    /// restante do app (`advancing` a partir da data de início).
    static func charges(
        of subscriptions: [Subscription],
        inMonth month: Date,
        calendar: Calendar = .current,
        service: CurrencyService = .shared
    ) -> [SubscriptionCharge] {
        let start = BillSchedule.monthStart(of: month, calendar: calendar)
        guard let end = calendar.date(byAdding: .month, value: 1, to: start) else { return [] }

        var result: [SubscriptionCharge] = []
        for subscription in subscriptions where !subscription.isCancelled {
            var due = subscription.startDate
            var guardCount = 0
            while due < end && guardCount < 1_000 {
                if due >= start {
                    result.append(SubscriptionCharge(
                        id: "\(subscription.id.uuidString)-\(Int(due.timeIntervalSince1970))",
                        name: subscription.name,
                        amount: subscription.cost(in: service),
                        date: due
                    ))
                }
                let next = subscription.advancing(due)
                if next <= due { break }
                due = next
                guardCount += 1
            }
        }
        return result.sorted { $0.date < $1.date }
    }
}

// MARK: - Evolução

struct BillMonthTotal: Identifiable {
    let month: Date
    let byCategory: [(category: BillCategory, amount: Double)]
    /// Mês atual ou futuro: inclui estimativas.
    let isProjected: Bool

    var id: Date { month }
    var total: Double { byCategory.reduce(0) { $0 + $1.amount } }
}

struct BillChange: Identifiable {
    let billID: UUID
    let name: String
    let category: BillCategory
    let current: Double
    let average: Double
    /// 0,18 = +18% sobre a média dos meses anteriores.
    let change: Double

    var id: UUID { billID }
}

enum BillEvolution {

    /// Total de contas dos últimos `count` meses até `month`. Meses passados
    /// contam só valores informados; o atual e os futuros incluem estimativas.
    static func totals(
        bills: [Bill],
        entries: [BillEntry],
        endingAt month: Date,
        count: Int = 6,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [BillMonthTotal] {
        let end = BillSchedule.monthStart(of: month, calendar: calendar)
        let currentStart = BillSchedule.monthStart(of: now, calendar: calendar)
        var result: [BillMonthTotal] = []

        for back in stride(from: count - 1, through: 0, by: -1) {
            guard let start = calendar.date(byAdding: .month, value: -back, to: end) else { continue }
            let projected = start >= currentStart
            let occurrences = BillCalendar.occurrences(
                bills: bills, entries: entries, month: start, now: now, calendar: calendar
            ).filter { projected || !$0.isEstimate }

            var sums: [BillCategory: Double] = [:]
            for item in occurrences { sums[item.category, default: 0] += item.amount }
            let ordered = sums.sorted { $0.value > $1.value }.map { (category: $0.key, amount: $0.value) }
            result.append(BillMonthTotal(month: start, byCategory: ordered, isProjected: projected))
        }
        return result
    }

    /// Contas do mês cujo valor informado ficou diferente da média dos meses
    /// anteriores, da maior variação para a menor.
    static func changes(
        occurrences: [BillOccurrence],
        entries: [BillEntry],
        month: Date,
        calendar: Calendar = .current,
        threshold: Double = 0.03
    ) -> [BillChange] {
        let start = BillSchedule.monthStart(of: month, calendar: calendar)
        let history = BillPlanning.history(of: entries, before: start)

        return occurrences.compactMap { item -> BillChange? in
            guard !item.isEstimate, item.amount > 0,
                  let previous = history[item.billID],
                  let change = BillMath.change(current: item.amount, previous: previous),
                  abs(change) >= threshold else { return nil }
            let base = previous.filter { $0 > 0 }.prefix(3)
            let average = base.reduce(0, +) / Double(base.count)
            return BillChange(billID: item.billID, name: item.name, category: item.category,
                              current: item.amount, average: average, change: change)
        }
        .sorted { abs($0.change) > abs($1.change) }
    }
}
