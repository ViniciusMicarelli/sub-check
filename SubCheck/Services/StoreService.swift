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

    /// Contas recorrentes ativas permitidas na versão gratuita.
    static let freeBillLimit = 5

    /// Dias de teste liberados a partir da primeira abertura do app. O teste
    /// é local: não existe oferta introdutória em compra única na App Store.
    static let trialDays = ProAccessSnapshot.trialDays

    static let shared = StoreService()

    private static let unlockedKey = ProAccessSnapshot.unlockedKey
    private static let trialStartKey = ProAccessSnapshot.trialStartKey
    private static let lastSeenKey = ProAccessSnapshot.lastSeenKey

    private(set) var product: Product?
    private(set) var isPro: Bool
    /// Quando a pessoa ativou o teste. `nil` = ainda não ativou (o Pro fica
    /// trancado até ela escolher testar ou comprar).
    private(set) var trialStartDate: Date?
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
        trialStartDate = Self.storedTrialStart()
        refreshClock()
        updatesTask = observeTransactions()
        Task { await refresh() }
    }

    // MARK: - Teste

    /// Libera os recursos Pro: compra registrada ou teste ainda em curso.
    /// Todos os portões do app devem usar isto, nunca `isPro` direto.
    var hasProAccess: Bool {
        guard let policy else { return isPro }
        return policy.hasProAccess(isPurchased: isPro, now: now)
    }

    private var policy: TrialPolicy? {
        trialStartDate.map { TrialPolicy(startDate: $0, days: Self.trialDays) }
    }

    var trialEndDate: Date? { policy?.endDate }

    /// Não ativou o teste e não comprou: pode escolher "testar 7 dias".
    var canStartTrial: Bool { !isPro && trialStartDate == nil }

    var trialState: TrialState {
        TrialPolicy.state(start: trialStartDate, days: Self.trialDays, now: now)
    }

    var isTrialActive: Bool { !isPro && policy?.isActive(now: now) == true }

    /// Dias inteiros que ainda restam do teste. Zero quando não começou,
    /// expirou ou quando a compra já foi feita.
    var trialDaysRemaining: Int {
        guard !isPro, let policy else { return 0 }
        return policy.daysRemaining(now: now)
    }

    /// A pessoa escolheu testar o Pro: o relógio de 7 dias começa agora.
    /// Só vale uma vez; o Keychain mantém a data mesmo se o app for reinstalado.
    func startTrial() {
        guard canStartTrial else { return }
        refreshClock()
        let start = now
        let defaults = UserDefaults.standard
        defaults.set(start, forKey: Self.trialStartKey)
        KeychainStore.set(start, for: Self.trialStartKey)
        trialStartDate = start
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

    /// Data em que o teste foi ativado, se foi. Lê o Keychain (sobrevive à
    /// reinstalação) e o UserDefaults; vale a mais antiga.
    private static func storedTrialStart() -> Date? {
        let defaults = UserDefaults.standard
        return TrialPolicy.earliestStart(from: [
            KeychainStore.date(for: trialStartKey),
            defaults.object(forKey: trialStartKey) as? Date
        ])
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
                await recordExpense(for: transaction)
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

    /// O que a pessoa pagou pelo Pro vira uma despesa avulsa, com o valor e a
    /// moeda reais da transação. Idempotente por id da transação.
    @MainActor
    private func recordExpense(for transaction: Transaction) {
        let context = SharedModelContainer.shared.mainContext
        OneOffPayments.recordProPurchase(
            price: transaction.price ?? product?.price ?? 0,
            currencyCode: transaction.currency?.identifier ?? product?.priceFormatStyle.currencyCode ?? "BRL",
            date: transaction.purchaseDate,
            transactionID: String(transaction.id),
            in: context
        )
    }

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
                // Compra aprovada fora do app (Ask to Buy): também é uma despesa,
                // mas restaurações antigas não são relançadas.
                if transaction.productID == Self.proProductID,
                   transaction.revocationDate == nil,
                   Date().timeIntervalSince(transaction.purchaseDate) < 3 * 86_400 {
                    await recordExpense(for: transaction)
                }
                await refreshEntitlements()
            }
        }
    }
}
