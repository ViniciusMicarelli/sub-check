//
//  AppLanguage.swift
//  SubCheck
//
//  Idioma da interface. `system` segue o idioma do aparelho; os demais
//  forçam um idioma sem precisar reiniciar o app.
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case system
    case ptBR = "pt-BR"
    case en

    var id: String { rawValue }

    /// Nome mostrado no seletor — sempre no próprio idioma, como manda a
    /// convenção de apps multilíngues.
    var displayName: String {
        switch self {
        case .system: L.t("language.system")
        case .ptBR:   "Português"
        case .en:     "English"
        }
    }

    /// Região usada para formatar números, datas e moeda. `nil` = do sistema.
    var locale: Locale? {
        switch self {
        case .system: nil
        case .ptBR:   Locale(identifier: "pt_BR")
        case .en:     Locale(identifier: "en_US")
        }
    }

    /// Código gravado em `AppleLanguages` para que o próximo lançamento já
    /// suba no idioma certo (diálogos do sistema, nome do app, etc).
    var appleLanguageCode: String? {
        switch self {
        case .system: nil
        case .ptBR:   "pt-BR"
        case .en:     "en"
        }
    }
}
