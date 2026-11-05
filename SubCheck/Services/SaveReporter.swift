//
//  SaveReporter.swift
//  SubCheck
//
//  Um salvamento que falha não pode passar em silêncio: o usuário acharia que
//  o dado foi gravado. `saveReporting()` grava e, se falhar, avisa a tela.
//

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class SaveReporter {

    static let shared = SaveReporter()
    private init() {}

    /// Mensagem técnica do último erro; `nil` quando não há nada a mostrar.
    var failure: String?

    func report(_ error: Error) {
        failure = error.localizedDescription
    }
}

extension ModelContext {

    /// Grava as mudanças. Devolve `false` e avisa o usuário se não conseguir.
    @discardableResult
    nonisolated func saveReporting() -> Bool {
        do {
            try save()
            return true
        } catch {
            let message = error.localizedDescription
            Task { @MainActor in SaveReporter.shared.failure = message }
            return false
        }
    }
}
