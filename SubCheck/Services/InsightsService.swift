//
//  InsightsService.swift
//  SubCheck
//
//  Leituras automáticas sobre as assinaturas: concentração de gasto,
//  serviços parecidos, cobranças semanais, ganho com cancelamentos e a
//  conta do dia a dia. Lógica pura, sem SwiftUI. Recurso Pro.
//

import Foundation

struct Insight: Identifiable {

    enum Tone { case info, warning, success }

    let id: String
    let icon: String
    let tone: Tone
    let title: String
    let detail: String
}

enum InsightsService {

    /// Planos anuais costumam custar menos que 12 mensalidades. É uma
    /// estimativa conservadora, apresentada como possibilidade.
    private static let annualDiscountEstimate = 0.15

    /// Insights do mais urgente para o mais informativo.
    static func insights(
        for subscriptions: [Subscription],
        service: CurrencyService = .shared
    ) -> [Insight] {
        let active = subscriptions.filter { !$0.isCancelled }
        let cancelled = subscriptions.filter(\.isCancelled)
        let monthly = active.monthlyTotal(in: service)

        var result: [Insight] = []

        // Cobranças da semana
        let week = upcomingTotal(active, days: 7, service: service)
        if week > 0 {
            result.append(Insight(
                id: "week",
                icon: "bell.badge.fill",
                tone: .warning,
                title: L.t("Próximos 7 dias: %@", Money.format(week)),
                detail: L.t("Deixe saldo disponível para as cobranças da semana.")
            ))
        }

        // Um serviço pesa demais
        if active.count >= 2, monthly > 0,
           let top = active.max(by: { $0.monthlyCost(in: service) < $1.monthlyCost(in: service) }) {
            let share = top.monthlyCost(in: service) / monthly
            if share >= 0.4 {
                result.append(Insight(
                    id: "concentration",
                    icon: "scalemass.fill",
                    tone: .warning,
                    title: L.t("%@ é %@ do seu gasto", top.name, Money.percentPlain(share)),
                    detail: L.t("Vale conferir se ele ainda compensa o uso.")
                ))
            }
        }

        // Serviços parecidos na mesma categoria
        let grouped = Dictionary(grouping: active, by: \.categoryType)
        if let overlap = grouped.filter({ $0.value.count >= 2 })
            .max(by: { $0.value.count < $1.value.count }) {
            let sum = overlap.value.monthlyTotal(in: service)
            result.append(Insight(
                id: "overlap",
                icon: "square.on.square",
                tone: .info,
                title: L.t("%lld serviços em %@: %@/mês", overlap.value.count,
                           overlap.key.displayName, Money.format(sum)),
                detail: L.t("Considere manter só o que você mais usa.")
            ))
        }

        // Cobrança semanal soma rápido
        let weekly = active.filter { $0.frequency == .weekly }
        if !weekly.isEmpty {
            let yearly = weekly.reduce(0) { $0 + $1.yearlyCost(in: service) }
            result.append(Insight(
                id: "weekly",
                icon: "calendar.badge.clock",
                tone: .warning,
                title: L.t("Cobranças semanais somam %@/ano", Money.compact(yearly)),
                detail: L.t("Planos semanais costumam ser os mais caros no ano.")
            ))
        }

        // Plano anual pode sair mais barato
        let monthlyPlans = active.filter { $0.frequency == .monthly }
        if monthlyPlans.count >= 2 {
            let yearly = monthlyPlans.reduce(0) { $0 + $1.yearlyCost(in: service) }
            let possible = yearly * annualDiscountEstimate
            result.append(Insight(
                id: "annual",
                icon: "arrow.triangle.2.circlepath",
                tone: .info,
                title: L.t("Planos anuais podem poupar até %@", Money.compact(possible)),
                detail: L.t("Estimativa de 15%% sobre %lld planos mensais. Confira com cada serviço.",
                            monthlyPlans.count)
            ))
        }

        // Economia que já está acontecendo
        if !cancelled.isEmpty {
            let saved = cancelled.reduce(0) { $0 + $1.yearlyCost(in: service) }
            result.append(Insight(
                id: "saved",
                icon: "leaf.fill",
                tone: .success,
                title: L.t("Você evita %@/ano com cancelamentos", Money.compact(saved)),
                detail: L.t("%lld serviço(s) cancelado(s). Bom trabalho.", cancelled.count)
            ))
        }

        // Conta do dia a dia
        if monthly > 0 {
            result.append(Insight(
                id: "daily",
                icon: "sun.max.fill",
                tone: .info,
                title: L.t("Suas assinaturas custam %@ por dia", Money.format(monthly / 30.44)),
                detail: L.t("Mesmo sem abrir nenhuma delas.")
            ))
        }

        return result
    }

    // MARK: - Cobranças futuras

    /// Soma (na moeda base) das cobranças que caem nos próximos `days` dias,
    /// contando cada ocorrência (semanal rende várias).
    static func upcomingTotal(
        _ subscriptions: [Subscription],
        days: Int,
        service: CurrencyService = .shared
    ) -> Double {
        let horizon = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        var total = 0.0

        for subscription in subscriptions where !subscription.isCancelled {
            let value = service.convert(subscription.cost, from: subscription.currencyCode)
            var due = subscription.nextBillingDate
            while due <= horizon {
                total += value
                let advanced = subscription.advancing(due)
                guard advanced > due else { break }
                due = advanced
            }
        }
        return total
    }
}
