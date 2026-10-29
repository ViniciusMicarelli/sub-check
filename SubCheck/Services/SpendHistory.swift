//
//  SpendHistory.swift
//  SubCheck
//
//  Agregações sobre as cobranças registradas: série mensal, comparação de
//  períodos e quebra por categoria. Tudo convertido para a moeda base.
//

import Foundation

/// Ponto da linha do tempo de gastos.
struct SpendPoint: Identifiable, Hashable {
    let month: Date
    let total: Double
    let count: Int
    var id: Date { month }

    var label: String { L.monthYear(month) }
}

enum SpendHistory {

    // MARK: - Série mensal

    /// Totais dos últimos `months` meses, incluindo o mês atual, do mais
    /// antigo para o mais recente. Meses sem cobrança entram zerados para a
    /// linha não "pular" buracos.
    static func monthlyTotals(
        _ records: [PaymentRecord],
        months: Int = 12,
        service: CurrencyService = .shared,
        calendar: Calendar = .current
    ) -> [SpendPoint] {
        let anchor = startOfMonth(Date(), calendar: calendar)

        var buckets: [Date: (total: Double, count: Int)] = [:]
        for offset in stride(from: months - 1, through: 0, by: -1) {
            guard let month = calendar.date(byAdding: .month, value: -offset, to: anchor) else { continue }
            buckets[month] = (0, 0)
        }

        for record in records {
            guard let existing = buckets[record.month] else { continue }
            let value = service.convert(record.amount, from: record.currencyCode)
            buckets[record.month] = (existing.total + value, existing.count + 1)
        }

        return buckets
            .map { SpendPoint(month: $0.key, total: $0.value.total, count: $0.value.count) }
            .sorted { $0.month < $1.month }
    }

    // MARK: - Períodos

    /// Total das cobranças dentro do intervalo, já convertido.
    static func total(
        _ records: [PaymentRecord],
        in interval: DateInterval,
        service: CurrencyService = .shared
    ) -> Double {
        records
            .filter { interval.contains($0.paidAt) }
            .reduce(0) { $0 + service.convert($1.amount, from: $1.currencyCode) }
    }

    static func monthInterval(containing date: Date, calendar: Calendar = .current) -> DateInterval {
        let start = startOfMonth(date, calendar: calendar)
        let end = calendar.date(byAdding: .month, value: 1, to: start) ?? start
        return DateInterval(start: start, end: end)
    }

    static func yearInterval(containing date: Date, calendar: Calendar = .current) -> DateInterval {
        let start = calendar.date(
            from: calendar.dateComponents([.year], from: date)
        ) ?? date
        let end = calendar.date(byAdding: .year, value: 1, to: start) ?? start
        return DateInterval(start: start, end: end)
    }

    /// Totais dos 12 meses de dois anos, para o comparativo lado a lado.
    static func monthlyTotals(
        forYearOf date: Date,
        _ records: [PaymentRecord],
        service: CurrencyService = .shared,
        calendar: Calendar = .current
    ) -> [Int: Double] {
        let interval = yearInterval(containing: date, calendar: calendar)
        var result: [Int: Double] = [:]
        for month in 1...12 { result[month] = 0 }

        for record in records where interval.contains(record.paidAt) {
            let month = calendar.component(.month, from: record.paidAt)
            result[month, default: 0] += service.convert(record.amount, from: record.currencyCode)
        }
        return result
    }

    /// Anos que possuem pelo menos uma cobrança, do mais recente ao mais antigo.
    static func years(in records: [PaymentRecord], calendar: Calendar = .current) -> [Int] {
        let years = Set(records.map { calendar.component(.year, from: $0.paidAt) })
        let current = calendar.component(.year, from: Date())
        return Array(years.union([current])).sorted(by: >)
    }

    // MARK: - Categorias

    /// Quebra por categoria dentro de um intervalo.
    static func byCategory(
        _ records: [PaymentRecord],
        in interval: DateInterval,
        service: CurrencyService = .shared
    ) -> [CategoryTotal] {
        let inRange = records.filter { interval.contains($0.paidAt) }
        return Dictionary(grouping: inRange, by: \.categoryType)
            .map { category, items in
                CategoryTotal(
                    category: category,
                    total: items.reduce(0) { $0 + service.convert($1.amount, from: $1.currencyCode) },
                    count: items.count
                )
            }
            .sorted { $0.total > $1.total }
    }

    /// Série mensal por categoria, para o gráfico empilhado.
    static func monthlyByCategory(
        _ records: [PaymentRecord],
        months: Int = 6,
        service: CurrencyService = .shared,
        calendar: Calendar = .current
    ) -> [(month: Date, category: CategoryType, total: Double)] {
        let anchor = startOfMonth(Date(), calendar: calendar)
        var allowed: Set<Date> = []
        for offset in stride(from: months - 1, through: 0, by: -1) {
            if let month = calendar.date(byAdding: .month, value: -offset, to: anchor) {
                allowed.insert(month)
            }
        }

        var buckets: [Date: [CategoryType: Double]] = [:]
        for record in records where allowed.contains(record.month) {
            let value = service.convert(record.amount, from: record.currencyCode)
            buckets[record.month, default: [:]][record.categoryType, default: 0] += value
        }

        return buckets
            .flatMap { month, categories in
                categories.map { (month: month, category: $0.key, total: $0.value) }
            }
            .sorted { $0.month < $1.month }
    }

    // MARK: - Progressão

    /// Variação percentual entre dois valores. `nil` quando não há base de
    /// comparação (evita "aumento infinito" no primeiro mês).
    static func change(current: Double, previous: Double) -> Double? {
        guard previous > 0 else { return nil }
        return (current - previous) / previous
    }

    static func startOfMonth(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }
}
