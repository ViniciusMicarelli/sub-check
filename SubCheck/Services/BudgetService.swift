//
//  BudgetService.swift
//  SubCheck
//
//  Orçamento mensal: onde o teto fica guardado e quando vale avisar que ele
//  foi ultrapassado. Recurso Pro.
//

import Foundation

/// Teto mensal escolhido pelo usuário. Zero significa "sem orçamento", e
/// nesse caso nem a barra no resumo nem o aviso aparecem.
enum Budget {

    static let amountKey = "monthlyBudget"

    static var amount: Double {
        UserDefaults.standard.double(forKey: amountKey)
    }

    /// Quanto do teto já foi usado. Zero quando não há orçamento definido.
    static func progress(spent: Double) -> Double {
        guard amount > 0 else { return 0 }
        return spent / amount
    }
}

@MainActor
enum BudgetService {

    /// Compara o gasto mensal com o teto e agenda (ou remove) o aviso de
    /// estouro. Pode ser chamado a cada mudança nas assinaturas.
    static func evaluate(_ subscriptions: [Subscription], service: CurrencyService = .shared) {
        let budget = Budget.amount
        guard budget > 0 else {
            NotificationService.shared.cancelBudgetAlert()
            return
        }

        let spent = subscriptions
            .filter { !$0.isCancelled }
            .monthlyTotal(in: service)

        NotificationService.shared.scheduleBudgetAlert(spent: spent, budget: budget)
    }
}
