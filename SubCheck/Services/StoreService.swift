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
    static let proProductID = "github.com-ViniciusMicarelli.SubCheck.pro.lifetime"

    /// Assinaturas ativas permitidas na versão gratuita.
    static let freeLimit = 5

    /// Dias de teste liberados a partir da primeira abertura do app. O teste
    /// é local: não existe oferta introdutória em compra única na App Store.
    static let trialDays = 7

    static let shared = StoreService()

    private static let unlockedKey = "proUnlocked"
    private static let trialStartKey = "proTrialStart"

    private(set) var product: Product?
    private(set) var isPro: Bool
    /// Primeira abertura do app, que marca o começo do teste.
    private(set) var trialStartDate: Date
    private(set) var isLoading = false
    private(set) var isPurchasing = false
    /// Mensagem para exibir no paywall quando algo falha.
    var errorMessage: String?

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    private init() {
        isPro = UserDefaults.standard.bool(forKey: Self.unlockedKey)
        trialStartDate = Self.startTrialIfNeeded()
        updatesTask = observeTransactions()
        Task { await refresh() }
    }

    // MARK: - Teste

    /// Libera os recursos Pro: compra registrada ou teste ainda em curso.
    /// Todos os portões do app devem usar isto, nunca `isPro` direto.
    var hasProAccess: Bool { isPro || isTrialActive }

    var trialEndDate: Date {
        Calendar.current.date(
            byAdding: .day,
            value: Self.trialDays,
            to: trialStartDate
        ) ?? trialStartDate
    }

    var isTrialActive: Bool { !isPro && Date() < trialEndDate }

    /// Dias inteiros que ainda restam do teste. Zero quando expirou ou
    /// quando a compra já foi feita.
    var trialDaysRemaining: Int {
        guard isTrialActive else { return 0 }
        let seconds = trialEndDate.timeIntervalSinceNow
        return max(1, Int(ceil(seconds / 86_400)))
    }

    /// Grava a data da primeira abertura. Fica no aparelho, então reinstalar
    /// o app reinicia a contagem do teste.
    private static func startTrialIfNeeded() -> Date {
        let defaults = UserDefaults.standard
        if let stored = defaults.object(forKey: trialStartKey) as? Date {
            return stored
        }
        let now = Date()
        defaults.set(now, forKey: trialStartKey)
        return now
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
