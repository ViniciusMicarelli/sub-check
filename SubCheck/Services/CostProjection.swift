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
