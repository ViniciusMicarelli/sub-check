//
//  Formatters.swift
//  SubCheck
//
//  Shared number formatting helpers.
//

import Foundation

enum Money {
    /// Formats a value as, e.g. "R$ 55,90".
    static func format(_ value: Double, code: String = "BRL") -> String {
        value.formatted(.currency(code: code).locale(Locale(identifier: "pt_BR")))
    }

    /// Compact form used inside tight KPI cards, e.g. "R$ 1,2 mil".
    static func compact(_ value: Double, code: String = "BRL") -> String {
        value.formatted(
            .currency(code: code)
            .locale(Locale(identifier: "pt_BR"))
            .precision(.fractionLength(0))
        )
    }
}
