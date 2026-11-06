//
//  TrialPolicy.swift
//  SubCheck
//
//  Regra do teste gratuito, sem estado e sem dependência de relógio: tudo
//  recebe `now` por parâmetro, então os testes simulam dias passando.
//

import Foundation

/// O teste grátis é uma escolha: começa quando a pessoa ativa, não sozinho.
enum TrialState: Equatable {
    case notStarted
    case active(daysLeft: Int)
    case expired
}

struct TrialPolicy: Equatable {

    static let defaultDays = 7

    let startDate: Date
    let days: Int
    var calendar: Calendar = .current

    init(startDate: Date, days: Int = TrialPolicy.defaultDays, calendar: Calendar = .current) {
        self.startDate = startDate
        self.days = days
        self.calendar = calendar
    }

    var endDate: Date {
        calendar.date(byAdding: .day, value: days, to: startDate) ?? startDate
    }

    /// O teste vale até o instante exato do fim (exclusivo).
    func isActive(now: Date) -> Bool { now < endDate }

    /// Dias inteiros que restam; zero depois do fim.
    func daysRemaining(now: Date) -> Int {
        guard isActive(now: now) else { return 0 }
        return max(1, Int(ceil(endDate.timeIntervalSince(now) / 86_400)))
    }

    /// Libera o Pro: compra feita ou teste em curso.
    func hasProAccess(isPurchased: Bool, now: Date) -> Bool {
        isPurchased || isActive(now: now)
    }

    // MARK: - Anti-fraude simples

    /// Entre cópias da data de início (Keychain, UserDefaults) vale a mais
    /// antiga. Sem nenhuma, o teste **ainda não começou**: ele só começa quando
    /// a pessoa escolhe ativar.
    static func earliestStart(from stored: [Date?]) -> Date? {
        stored.compactMap { $0 }.min()
    }

    /// Situação do teste para mostrar na tela.
    static func state(
        start: Date?, days: Int = defaultDays, now: Date, calendar: Calendar = .current
    ) -> TrialState {
        guard let start else { return .notStarted }
        let policy = TrialPolicy(startDate: start, days: days, calendar: calendar)
        return policy.isActive(now: now) ? .active(daysLeft: policy.daysRemaining(now: now)) : .expired
    }

    /// Voltar o relógio do aparelho não pode reabrir o teste: o "agora"
    /// nunca é anterior ao último instante já observado.
    static func effectiveNow(_ now: Date, lastSeen: Date?) -> Date {
        guard let lastSeen else { return now }
        return max(now, lastSeen)
    }
}
