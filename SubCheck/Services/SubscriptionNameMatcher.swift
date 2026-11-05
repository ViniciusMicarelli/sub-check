//
//  SubscriptionNameMatcher.swift
//  SubCheck
//
//  Resolve o nome falado ("netflix", "o spotify") para uma assinatura. Ignora
//  maiúsculas e acentos e ordena do casamento mais exato para o mais frouxo.
//  Lógica pura, usada pela Siri e testada à parte.
//

import Foundation

enum SubscriptionNameMatcher {

    /// Índices de `names` que casam com `query`, melhores primeiro. Consulta
    /// vazia devolve todos, na ordem original (sugestões da Siri).
    static func rank(_ query: String, in names: [String]) -> [Int] {
        let needle = normalize(query)
        guard !needle.isEmpty else { return Array(names.indices) }

        var scored: [(index: Int, score: Int)] = []
        for (index, name) in names.enumerated() {
            let candidate = normalize(name)
            guard !candidate.isEmpty else { continue }

            let score: Int?
            if candidate == needle { score = 0 }
            else if candidate.hasPrefix(needle) { score = 1 }
            else if candidate.split(separator: " ").contains(where: { $0.hasPrefix(needle) }) { score = 2 }
            else if candidate.contains(needle) { score = 3 }
            // "netflix premium" dito para a assinatura "Netflix".
            else if needle.contains(candidate) { score = 4 }
            else { score = nil }

            if let score { scored.append((index, score)) }
        }
        return scored.sorted { ($0.score, $0.index) < ($1.score, $1.index) }.map(\.index)
    }

    /// Minúsculas, sem acento e sem artigos soltos ("o", "a", "do", "da").
    static func normalize(_ text: String) -> String {
        let articles: Set<String> = ["o", "a", "os", "as", "do", "da", "de", "the"]
        return StatementParser.fold(text)
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
            .filter { !articles.contains($0) }
            .joined(separator: " ")
    }
}
