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

    /// Variação percentual com sinal ("+12%").
    static func percent(_ fraction: Double, locale: Locale = L.current) -> String {
        let formatted = fraction.formatted(
            .percent.locale(locale).precision(.fractionLength(0)).sign(strategy: .always())
        )
        return formatted
    }
}
