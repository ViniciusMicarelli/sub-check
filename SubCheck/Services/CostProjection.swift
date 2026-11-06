//
//  CostProjection.swift
//  SubCheck
//
//  Conta da simulação "Quanto isso vira?", separada da tela para ser testada.
//

import Foundation

enum CostProjection {

    /// Faixa aceita para o reajuste anual (0% a 50%).
    static let rateRange: ClosedRange<Double> = 0...0.5

    static func clamp(_ rate: Double) -> Double {
        guard rate.isFinite else { return 0 }
        return min(max(rate, rateRange.lowerBound), rateRange.upperBound)
    }

    /// Total gasto em `years` anos. O reajuste `annualRate` (0.08 = 8%) entra
    /// a cada ano completo: o primeiro ano custa o valor atual.
    static func total(monthly: Double, years: Int, annualRate: Double) -> Double {
        guard monthly.isFinite, years > 0 else { return 0 }
        let yearly = monthly * 12
        let rate = clamp(annualRate)
        return (0..<years).reduce(0) { $0 + yearly * pow(1 + rate, Double($1)) }
    }
}

// MARK: - Quanto a economia vira com o tempo

/// Um ponto da curva "se eu cancelar": mês a mês, até 10 anos.
struct SavingsPoint: Identifiable, Equatable {
    /// 0 = hoje; 12 = daqui a um ano.
    let month: Int
    /// O que seguiria sendo gasto sem cancelar (acumulado, com reajuste).
    let spentWithoutCancelling: Double
    /// O que deixa de ser gasto (acumulado, com reajuste).
    let saved: Double
    /// A mesma economia, se cada mês fosse investido a `yield` ao ano.
    let savedInvested: Double

    var id: Int { month }
}

enum SavingsProjection {

    static let maxYears = 10

    /// Faixas aceitas para os percentuais anuais.
    static let percentRange: ClosedRange<Double> = 0...0.5

    static func clampPercent(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, percentRange.lowerBound), percentRange.upperBound)
    }

    /// Curva mensal.
    /// - Parameters:
    ///   - monthlyTotal: gasto mensal atual com tudo.
    ///   - monthlySaved: parte desse gasto que seria cancelada.
    ///   - years: horizonte (1...10).
    ///   - inflation: reajuste anual dos preços (0.05 = 5%), aplicado a cada 12 meses.
    ///   - yield: rendimento anual de investir a economia (0 = não investe).
    static func curve(
        monthlyTotal: Double,
        monthlySaved: Double,
        years: Int,
        inflation: Double,
        yield: Double = 0
    ) -> [SavingsPoint] {
        guard monthlyTotal.isFinite, monthlySaved.isFinite else { return [] }
        let horizon = min(max(years, 1), maxYears) * 12
        let infl = clampPercent(inflation)
        let yld = clampPercent(yield)
        let monthlyYield = pow(1 + yld, 1.0 / 12.0) - 1

        var spent = 0.0, saved = 0.0, invested = 0.0
        var points = [SavingsPoint(month: 0, spentWithoutCancelling: 0, saved: 0, savedInvested: 0)]

        for month in 1...horizon {
            // O reajuste entra a cada ano completo: o primeiro ano custa o valor atual.
            let factor = pow(1 + infl, Double((month - 1) / 12))
            spent += max(monthlyTotal, 0) * factor
            let avoided = max(min(monthlySaved, monthlyTotal), 0) * factor
            saved += avoided
            invested = invested * (1 + monthlyYield) + avoided
            points.append(SavingsPoint(month: month, spentWithoutCancelling: spent, saved: saved, savedInvested: invested))
        }
        return points
    }

    /// Ponto mais próximo de um mês (para o arrastar do gráfico).
    static func point(atMonth month: Double, in curve: [SavingsPoint]) -> SavingsPoint? {
        guard !curve.isEmpty, month.isFinite else { return nil }
        let index = min(max(Int(month.rounded()), 0), curve.count - 1)
        return curve[index]
    }
}
