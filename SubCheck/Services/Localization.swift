//
//  Localization.swift
//  SubCheck
//
//  Acesso às strings traduzidas fora do contexto de `Text`, que já resolve
//  `LocalizedStringKey` sozinho. Usado por enums (nomes de categoria,
//  frequência) e por textos com dados interpolados.
//
//  Convenção de chaves:
//  - textos de tela usam a própria frase em português como chave;
//  - chaves com ponto (`category.finance`) agrupam conteúdo de modelo.
//

import Foundation

enum L {

    static let languageKey = "appLanguage"

    /// Armazenamento compartilhado com o widget; o app grava no padrão.
    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: SharedModelContainer.appGroupID) ?? .standard
    }

    /// Idioma escolhido nas configurações.
    static var selected: AppLanguage {
        let raw = UserDefaults.standard.string(forKey: languageKey)
            ?? sharedDefaults.string(forKey: languageKey)
        guard let raw, let language = AppLanguage(rawValue: raw) else { return .system }
        return language
    }

    /// Grava o idioma para o app (padrão) e para o widget (App Group).
    static func store(_ language: AppLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: languageKey)
        sharedDefaults.set(language.rawValue, forKey: languageKey)
    }

    /// Locale usada para localizar e formatar (idioma escolhido ou sistema).
    static var current: Locale {
        selected.locale ?? Locale.current
    }

    /// Traduz uma chave para o idioma selecionado.
    static func t(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .main, locale: current)
    }

    /// Traduz uma chave com argumentos (usa placeholders `%lld` / `%@`).
    static func t(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: t(key), arguments: arguments)
    }
}

// MARK: - Formatos

extension L {

    /// "2 de fev." no idioma escolhido.
    static func shortDate(_ date: Date) -> String {
        date.formatted(
            .dateTime.day().month(.abbreviated).locale(current)
        )
    }

    /// "fev. 2026".
    static func monthYear(_ date: Date) -> String {
        date.formatted(
            .dateTime.month(.abbreviated).year().locale(current)
        )
    }

    /// "2026".
    static func year(_ date: Date) -> String {
        date.formatted(.dateTime.year().locale(current))
    }
}
