//
//  StoreService.swift
//  SubCheck
//
//  Compra única (não consumível) que libera os recursos Pro. Usa StoreKit 2,
//  guarda o resultado no aparelho para o app abrir já destravado e revalida
//  as permissões em segundo plano.
//

import Foundation
import Observation
import StoreKit

@Observable
final class StoreService {

    /// Mesmo identificador de `Config/SubCheck.storekit` e do App Store Connect.
    static let proProductID = "com.viniciusmicarelli.subcheck.pro.lifetime"

    /// Assinaturas ativas permitidas na versão gratuita.
    static let freeLimit = 5

    /// Dias de teste liberados a partir da primeira abertura do app. O teste
    /// é local: não existe oferta introdutória em compra única na App Store.
    static let trialDays = ProAccessSnapshot.trialDays

    static let shared = StoreService()

    private static let unlockedKey = ProAccessSnapshot.unlockedKey
    private static let trialStartKey = ProAccessSnapshot.trialStartKey
    private static let lastSeenKey = ProAccessSnapshot.lastSeenKey

    private(set) var product: Product?
    private(set) var isPro: Bool
    /// Primeira abertura do app, que marca o começo do teste.
    private(set) var trialStartDate: Date
    /// Relógio do teste: avança em `refreshClock()` e nunca volta, mesmo que
    /// o usuário atrase a data do aparelho.
    private(set) var now = Date()
    private(set) var isLoading = false
    private(set) var isPurchasing = false
    /// Mensagem para exibir no paywall quando algo falha.
    var errorMessage: String?

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    private init() {
        isPro = UserDefaults.standard.bool(forKey: Self.unlockedKey)
        trialStartDate = Self.startTrialIfNeeded()
        refreshClock()
        updatesTask = observeTransactions()
        Task { await refresh() }
    }

    // MARK: - Teste

    /// Libera os recursos Pro: compra registrada ou teste ainda em curso.
    /// Todos os portões do app devem usar isto, nunca `isPro` direto.
    var hasProAccess: Bool { policy.hasProAccess(isPurchased: isPro, now: now) }

    private var policy: TrialPolicy {
        TrialPolicy(startDate: trialStartDate, days: Self.trialDays)
    }

    var trialEndDate: Date { policy.endDate }

    var isTrialActive: Bool { !isPro && policy.isActive(now: now) }

    /// Dias inteiros que ainda restam do teste. Zero quando expirou ou
    /// quando a compra já foi feita.
    var trialDaysRemaining: Int {
        isPro ? 0 : policy.daysRemaining(now: now)
    }

    /// Atualiza o relógio do teste; chamado ao abrir e ao voltar ao primeiro
    /// plano, para o Pro travar sozinho quando o teste termina.
    func refreshClock() {
        let effective = TrialPolicy.effectiveNow(
            Date(), lastSeen: KeychainStore.date(for: Self.lastSeenKey)
        )
        now = effective
        KeychainStore.set(effective, for: Self.lastSeenKey)
    }

    /// Grava a data da primeira abertura no Keychain (sobrevive à
    /// reinstalação) e espelha no UserDefaults. Vale a data mais antiga.
    private static func startTrialIfNeeded() -> Date {
        let defaults = UserDefaults.standard
        let start = TrialPolicy.startDate(
            from: [
                KeychainStore.date(for: trialStartKey),
                defaults.object(forKey: trialStartKey) as? Date
            ],
            now: Date()
        )
        defaults.set(start, forKey: trialStartKey)
        KeychainStore.set(start, for: trialStartKey)
        return start
    }

    // MARK: - Preço

    /// Preço localizado da loja; `nil` enquanto o produto não carregou.
    var displayPrice: String? { product?.displayPrice }

    // MARK: - Carregamento

    /// Carrega o produto e revalida as permissões.
    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            product = try await Product.products(for: [Self.proProductID]).first
        } catch {
            errorMessage = L.t("Não foi possível carregar a loja.")
        }

        await refreshEntitlements()
    }

    /// Lê as permissões atuais registradas na App Store.
    func refreshEntitlements() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == Self.proProductID, transaction.revocationDate == nil {
                unlocked = true
            }
        }
        setUnlocked(unlocked)
    }

    // MARK: - Compra

    /// Executa a compra. Devolve `true` quando o Pro foi liberado.
    @discardableResult
    func purchase() async -> Bool {
        errorMessage = nil

        guard let product else {
            errorMessage = L.t("Não foi possível carregar a loja.")
            return false
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    errorMessage = L.t("A compra não pôde ser verificada.")
                    return false
                }
                await transaction.finish()
                setUnlocked(true)
                Haptics.success()
                return true

            case .userCancelled:
                return false

            case .pending:
                errorMessage = L.t("A compra está aguardando aprovação.")
                return false

            @unknown default:
                return false
            }
        } catch {
            errorMessage = L.t("Não foi possível concluir a compra.")
            return false
        }
    }

    /// Recupera a compra feita em outro aparelho.
    func restore() async {
        errorMessage = nil
        do {
            try await AppStore.sync()
        } catch {
            errorMessage = L.t("Não foi possível restaurar as compras.")
        }
        await refreshEntitlements()
    }

    // MARK: - Interno

    private func setUnlocked(_ unlocked: Bool) {
        isPro = unlocked
        UserDefaults.standard.set(unlocked, forKey: Self.unlockedKey)
    }

    /// Escuta compras aprovadas fora do fluxo do app (Ask to Buy, outro
    /// aparelho) para destravar sem precisar reabrir.
    private func observeTransactions() -> Task<Void, Never> {
        Task {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await transaction.finish()
                await refreshEntitlements()
            }
        }
    }
}
