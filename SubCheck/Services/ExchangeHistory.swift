//
//  ExchangeHistory.swift
//  SubCheck
//
//  Histórico de cotações e o cálculo de quanto o câmbio mudou o custo de um
//  pagamento. Lógica pura (sem SwiftData nem rede) para poder ser testada.
//
//  Exemplo: pagou US$ 10 quando o dólar valia R$ 5,00 (R$ 50). Hoje vale
//  R$ 4,00 (R$ 40): a diferença é -R$ 10 (-20%).
//

import Foundation

/// Fotografia das cotações em um dia (unidades de cada moeda por 1 USD).
struct RateSnapshot: Codable, Equatable {
    var date: Date
    var usdRates: [String: Double]
}

struct RateHistory: Equatable {

    /// Teto de segurança: um ano de fotos diárias.
    static let maxSnapshots = 365

    /// Ordenadas da mais antiga para a mais nova, uma por dia.
    private(set) var snapshots: [RateSnapshot]

    init(snapshots: [RateSnapshot] = []) {
        self.snapshots = snapshots.sorted { $0.date < $1.date }
    }

    /// Guarda a cotação do dia. Uma segunda baixada no mesmo dia substitui a
    /// primeira, então o histórico tem no máximo um ponto por dia.
    mutating func record(_ usdRates: [String: Double], at date: Date, calendar: Calendar = .current) {
        guard !usdRates.isEmpty else { return }
        snapshots.removeAll { calendar.isDate($0.date, inSameDayAs: date) }
        snapshots.append(RateSnapshot(date: date, usdRates: usdRates))
        snapshots.sort { $0.date < $1.date }
        if snapshots.count > Self.maxSnapshots {
            snapshots.removeFirst(snapshots.count - Self.maxSnapshots)
        }
    }

    /// Cotação mais recente até o fim do dia de `date`. Se a última foto for
    /// mais velha que `maxAgeDays`, devolve `nil`: melhor "sem cotação" do que
    /// um número inventado.
    func usdRates(on date: Date, maxAgeDays: Int = 3, calendar: Calendar = .current) -> [String: Double]? {
        guard let endOfDay = calendar.date(
            byAdding: .day, value: 1, to: calendar.startOfDay(for: date)
        ) else { return nil }

        guard let snapshot = snapshots.last(where: { $0.date < endOfDay }) else { return nil }

        let age = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: snapshot.date),
            to: calendar.startOfDay(for: date)
        ).day ?? 0
        return age <= maxAgeDays ? snapshot.usdRates : nil
    }

    /// Quantas unidades de `to` valem 1 unidade de `from` em `date`.
    func rate(from: String, to: String, on date: Date, maxAgeDays: Int = 3, calendar: Calendar = .current) -> Double? {
        guard let rates = usdRates(on: date, maxAgeDays: maxAgeDays, calendar: calendar) else { return nil }
        return Self.rate(from: from, to: to, usdRates: rates)
    }

    /// Série para o gráfico: a cotação de `from` em `to` ao longo dos dias.
    func series(from: String, to: String) -> [(date: Date, rate: Double)] {
        snapshots.compactMap { snapshot in
            Self.rate(from: from, to: to, usdRates: snapshot.usdRates)
                .map { (snapshot.date, $0) }
        }
    }

    static func rate(from: String, to: String, usdRates: [String: Double]) -> Double? {
        let origin = from.uppercased()
        let target = to.uppercased()
        if origin == target { return 1 }
        guard let originRate = usdRates[origin], originRate > 0,
              let targetRate = usdRates[target], targetRate > 0 else { return nil }
        return targetRate / originRate
    }
}

/// Quanto o câmbio mudou o custo de um pagamento, em moeda base.
struct ExchangeImpact: Equatable {

    /// O que o pagamento custou na moeda base, na cotação da época.
    let paidInBase: Double
    /// O que o mesmo valor custaria hoje.
    let currentInBase: Double

    /// Positivo: hoje sairia mais caro. Negativo: ficou mais barato.
    var difference: Double { currentInBase - paidInBase }

    /// Variação relativa (0,25 = +25%).
    var fraction: Double { paidInBase > 0 ? difference / paidInBase : 0 }

    /// `nil` quando a cotação da época é desconhecida (0).
    init?(amount: Double, rateAtPayment: Double, currentRate: Double) {
        guard rateAtPayment > 0, currentRate > 0, amount.isFinite else { return nil }
        self.paidInBase = amount * rateAtPayment
        self.currentInBase = amount * currentRate
    }

    /// Soma vários pagamentos (todos na mesma moeda base).
    static func total(_ impacts: [ExchangeImpact]) -> (paid: Double, current: Double) {
        impacts.reduce((0, 0)) { ($0.0 + $1.paidInBase, $0.1 + $1.currentInBase) }
    }
}
