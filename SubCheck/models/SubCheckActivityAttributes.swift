//
//  SubCheckActivityAttributes.swift
//  SubCheck
//
//  Dados da Live Activity de cobranças. Compartilhado entre o app (que inicia
//  e atualiza a atividade) e a extensão de widgets (que desenha a ilha
//  dinâmica e a tela de bloqueio).
//

import Foundation
import ActivityKit

struct SubCheckActivityAttributes: ActivityAttributes {

    /// Conteúdo que muda enquanto a atividade está na tela.
    struct ContentState: Codable, Hashable {
        /// Identificador da assinatura cobrada em seguida.
        var nextID: String
        /// Nome da assinatura cobrada em seguida.
        var nextName: String
        /// Valor da próxima cobrança, já na moeda base.
        var nextAmount: Double
        /// Quando a próxima cobrança acontece.
        var nextDueDate: Date
        /// Categoria da próxima cobrança, que define cor e símbolo.
        var nextCategory: String
        /// Total mensal previsto das assinaturas ativas.
        var monthlyTotal: Double
        /// Cobranças seguintes, da mais próxima para a mais distante.
        var upcoming: [UpcomingCharge]
        /// `"bill"` quando o próximo item é uma conta da casa; `nil` = assinatura.
        /// Opcional para continuar lendo atividades criadas por versões antigas.
        var nextKind: String? = nil
    }

    /// Uma cobrança futura listada na visão expandida.
    struct UpcomingCharge: Codable, Hashable, Identifiable {
        var id: String
        var name: String
        var amount: Double
        var dueDate: Date
        var category: String
        /// `"bill"` para conta da casa; `nil` = assinatura.
        var kind: String? = nil
    }

    /// Momento em que a atividade foi criada.
    var startedAt: Date
}
