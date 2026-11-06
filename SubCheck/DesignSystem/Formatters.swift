//
//  Formatters.swift
//  SubCheck
//
//  Formatação de valores monetários. Segue o idioma escolhido no app e,
//  por padrão, exibe na moeda base definida pelo usuário.
//

import Foundation

enum Money {

    /// Formata como "R$ 55,90" / "$55.90".
    static func format(
        _ value: Double,
        code: String = CurrencyService.shared.baseCode,
        locale: Locale = L.current
    ) -> String {
        value.formatted(.currency(code: code).locale(locale))
    }

    /// Forma compacta usada em cards apertados, sem centavos.
    static func compact(
        _ value: Double,
        code: String = CurrencyService.shared.baseCode,
        locale: Locale = L.current
    ) -> String {
        value.formatted(
            .currency(code: code)
            .locale(locale)
            .precision(.fractionLength(0))
        )
    }

    /// Valor com sinal explícito, para deltas ("+R$ 12,00").
    static func signed(
        _ value: Double,
        code: String = CurrencyService.shared.baseCode,
        locale: Locale = L.current
    ) -> String {
        let formatted = value.formatted(
            .currency(code: code).locale(locale).precision(.fractionLength(0))
        )
        return value > 0 ? "+\(formatted)" : formatted
    }

    /// Símbolo da moeda base ("R$", "$").
    static var symbol: String {
        let code = CurrencyService.shared.baseCode
        return Locale(identifier: Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: code]))
            .currencySymbol ?? code
    }

    /// Número sem símbolo, com até duas casas ("182,4").
    static func plain(_ value: Double, locale: Locale = L.current) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)).locale(locale))
    }

    /// Variação percentual com sinal ("+12%").
    static func percent(_ fraction: Double, locale: Locale = L.current) -> String {
        let formatted = fraction.formatted(
            .percent.locale(locale).precision(.fractionLength(0)).sign(strategy: .always())
        )
        return formatted
    }

    /// Percentual sem sinal ("42%").
    static func percentPlain(_ fraction: Double, locale: Locale = L.current) -> String {
        fraction.formatted(.percent.locale(locale).precision(.fractionLength(0)))
    }
}


extension String {

    /// Só a primeira letra em maiúscula ("novembro de 2026" → "Novembro de 2026").
    /// `capitalized` também maiusculiza o "de".
    var capitalizedFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
}
