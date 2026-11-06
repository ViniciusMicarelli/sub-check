//
//  AppRouter.swift
//  SubCheck
//
//  Navegação que vem de fora de uma tela: tocar numa notificação de conta abre
//  a aba Contas já na conta certa; um card do painel leva para a mesma aba.
//

import Foundation
import Observation

enum AppTab: Hashable {
    case dashboard, subscriptions, bills, categories, settings
}

@Observable
@MainActor
final class AppRouter {

    static let shared = AppRouter()
    private init() {}

    var tab: AppTab = .dashboard
    /// Conta cujo valor deve ser informado ao abrir o app (notificação).
    var billToOpen: UUID?

    func openBill(_ id: UUID) {
        tab = .bills
        billToOpen = id
    }
}
