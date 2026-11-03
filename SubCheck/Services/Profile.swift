//
//  Profile.swift
//  SubCheck
//
//  Nome informado no onboarding, usado na saudação do resumo e editável nos
//  Ajustes. Fica só no aparelho: não sai daqui.
//

import Foundation

enum Profile {

    /// Chave do `@AppStorage` compartilhada com o onboarding e os Ajustes.
    static let nameKey = "userName"

    /// Nome completo, como o usuário escreveu.
    static var name: String {
        UserDefaults.standard.string(forKey: nameKey) ?? ""
    }

    /// Primeiro nome, para caber na saudação.
    static var firstName: String {
        name.split(separator: " ").first.map(String.init) ?? ""
    }

    /// Saudação pronta quando há nome; `nil` quando o nome está vazio.
    static var greeting: String? {
        let first = firstName
        guard !first.isEmpty else { return nil }
        return L.t("Olá, %@", first)
    }
}
