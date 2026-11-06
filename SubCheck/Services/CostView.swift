//
//  CostView.swift
//  SubCheck
//
//  "Hoje" × "Futuro". Um teste grátis em curso não cobra nada hoje, mas vai
//  cobrar quando acabar. Misturar os dois faz o custo parecer maior do que a
//  pessoa paga agora (ou menor do que vai pagar). Aqui eles ficam separados.
//

import Foundation

enum CostView: String, CaseIterable, Identifiable {
    /// O que é cobrado agora: testes grátis em curso não entram.
    case today
    /// O que será cobrado quando os testes terminarem.
    case future

    var id: String { rawValue }

    static let storageKey = "costView"
}

extension Subscription {

    /// Teste grátis ainda em curso (a primeira cobrança ainda não aconteceu).
    var isInTrial: Bool { trialDaysLeft != nil }
}

extension Array where Element == Subscription {

    /// Total mensal (minha parte) na visão escolhida.
    func monthlyTotal(in service: CurrencyService, view: CostView) -> Double {
        switch view {
        case .future:
            return monthlyTotal(in: service)
        case .today:
            return filter { !$0.isInTrial }.monthlyTotal(in: service)
        }
    }

    /// Quanto passa a ser cobrado por mês quando os testes em curso terminarem.
    func trialMonthlyTotal(in service: CurrencyService) -> Double {
        filter(\.isInTrial).monthlyTotal(in: service)
    }

    /// Há algum teste grátis em curso?
    var hasActiveTrials: Bool { contains(where: \.isInTrial) }
}
