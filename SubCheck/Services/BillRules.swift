//
//  BillRules.swift
//  SubCheck
//
//  Regras de contas recorrentes, sem SwiftData nem tela, para poderem ser
//  testadas: calendário de vencimentos, situação de cada conta, estimativas e
//  o quanto do salário já está comprometido no mês.
//

import Foundation

// MARK: - Calendário

enum BillSchedule {

    /// Primeiro dia do mês de `date`.
    static func monthStart(of date: Date, calendar: Calendar = .current) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    /// Vencimento no mês de `date`. Dia 31 em fevereiro vira o último dia do
    /// mês (28 ou 29), em vez de pular para março.
    static func dueDate(day: Int, inMonthOf date: Date, calendar: Calendar = .current) -> Date {
        let start = monthStart(of: date, calendar: calendar)
        let length = calendar.range(of: .day, in: .month, for: start)?.count ?? 28
        var parts = calendar.dateComponents([.year, .month], from: start)
        parts.day = min(max(day, 1), length)
        parts.hour = 12   // meio-dia: imune a mudanças de horário de verão
        return calendar.date(from: parts) ?? start
    }

    /// Próximos vencimentos a partir de `from` (hoje conta), em ordem.
    static func upcomingDueDates(
        day: Int, from: Date, count: Int, calendar: Calendar = .current
    ) -> [Date] {
        var result: [Date] = []
        var cursor = from
        let today = calendar.startOfDay(for: from)
        for _ in 0..<(count + 2) where result.count < count {
            let due = dueDate(day: day, inMonthOf: cursor, calendar: calendar)
            if calendar.startOfDay(for: due) >= today { result.append(due) }
            cursor = calendar.date(byAdding: .month, value: 1, to: monthStart(of: cursor, calendar: calendar)) ?? cursor
        }
        return result
    }
}

// MARK: - Situação e estimativas

enum BillStatus: Equatable {
    /// Ainda não venceu.
    case upcoming
    /// Vence hoje e não foi paga.
    case dueToday
    /// Venceu e não foi paga.
    case overdue
    case paid
}

enum BillMath {

    static func status(
        isPaid: Bool, dueDate: Date, now: Date = Date(), calendar: Calendar = .current
    ) -> BillStatus {
        if isPaid { return .paid }
        let days = daysUntil(dueDate, now: now, calendar: calendar)
        if days > 0 { return .upcoming }
        return days == 0 ? .dueToday : .overdue
    }

    /// Dias inteiros até o vencimento (negativo se já passou).
    static func daysUntil(_ dueDate: Date, now: Date = Date(), calendar: Calendar = .current) -> Int {
        calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: dueDate)
        ).day ?? 0
    }

    /// Valor esperado de uma conta: o fixo/estimado, ou a média dos últimos
    /// meses pagos. `previous` vem do mais recente para o mais antigo.
    static func estimate(expected: Double, previous: [Double]) -> Double {
        if expected > 0 { return expected }
        let recent = previous.filter { $0 > 0 }.prefix(3)
        guard !recent.isEmpty else { return 0 }
        return recent.reduce(0, +) / Double(recent.count)
    }

    /// Quanto o mês atual variou em relação à média dos anteriores
    /// (0,18 = +18%). `nil` com menos de dois meses de histórico.
    static func change(current: Double, previous: [Double]) -> Double? {
        let base = previous.filter { $0 > 0 }.prefix(3)
        guard current > 0, base.count >= 2 else { return nil }
        let average = base.reduce(0, +) / Double(base.count)
        guard average > 0 else { return nil }
        return current / average - 1
    }
}

// MARK: - Plano do mês

/// Salário líquido (já com descontos) contra o que está comprometido.
struct MonthPlan: Equatable {
    var salary: Double
    /// Total mensal das assinaturas ativas.
    var subscriptions: Double
    /// Contas do mês já pagas.
    var billsPaid: Double
    /// Contas do mês ainda por pagar (valor informado ou estimativa).
    var billsPending: Double

    var bills: Double { billsPaid + billsPending }
    var committed: Double { subscriptions + bills }
    /// Quanto sobra do salário. Negativo = o mês fecha no vermelho.
    var remaining: Double { salary - committed }
    var isOver: Bool { salary > 0 && remaining < 0 }
    var hasSalary: Bool { salary > 0 }

    /// Parte comprometida do salário, entre 0 e 1 (para a barra).
    var committedFraction: Double {
        guard salary > 0 else { return 0 }
        return min(max(committed / salary, 0), 1)
    }

    /// Fatias da barra, como fração do salário (ou do total, sem salário).
    func share(_ part: Double) -> Double {
        let base = salary > 0 ? max(salary, committed) : max(committed, 1)
        return min(max(part / base, 0), 1)
    }
}
