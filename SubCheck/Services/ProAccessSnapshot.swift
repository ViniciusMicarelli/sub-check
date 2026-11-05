//
//  ProAccessSnapshot.swift
//  SubCheck
//
//  Leitura rápida e síncrona de "este aparelho tem acesso Pro?". O banco de
//  dados abre antes de o `StoreService` existir, então recursos que dependem
//  do Pro e são decididos na abertura (como o iCloud) consultam isto.
//  `StoreService` usa as mesmas chaves, então os dois sempre concordam.
//

import Foundation

enum ProAccessSnapshot {

    static let unlockedKey = "proUnlocked"
    static let trialStartKey = "proTrialStart"
    static let lastSeenKey = "proTrialLastSeen"

    /// Dias de teste liberados a partir da primeira abertura.
    static let trialDays = 7

    /// Regra pura, para teste: compra registrada ou teste ainda em curso.
    static func hasAccess(
        purchased: Bool,
        trialStart: [Date?],
        lastSeen: Date?,
        now: Date
    ) -> Bool {
        let start = TrialPolicy.startDate(from: trialStart, now: now)
        let effective = TrialPolicy.effectiveNow(now, lastSeen: lastSeen)
        return TrialPolicy(startDate: start, days: trialDays)
            .hasProAccess(isPurchased: purchased, now: effective)
    }

    /// Lê o estado gravado no aparelho (UserDefaults + Keychain).
    static func current(now: Date = Date()) -> Bool {
        let defaults = UserDefaults.standard
        return hasAccess(
            purchased: defaults.bool(forKey: unlockedKey),
            trialStart: [
                KeychainStore.date(for: trialStartKey),
                defaults.object(forKey: trialStartKey) as? Date
            ],
            lastSeen: KeychainStore.date(for: lastSeenKey),
            now: now
        )
    }
}
