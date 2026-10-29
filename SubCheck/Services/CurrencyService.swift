//
//  CurrencyService.swift
//  SubCheck
//
//  Cotação de moedas com conversão para uma moeda base. Busca as taxas do
//  dia em um provedor público sem chave, guarda em cache no App Group (para
//  o widget reaproveitar) e cai para a tabela embutida quando está offline.
//

import Foundation
import Observation

@Observable
final class CurrencyService {

    static let shared = CurrencyService()

    private static let baseKey = "baseCurrencyCode"
    private static let ratesKey = "exchangeRatesPerUSD"
    private static let updatedKey = "exchangeRatesUpdatedAt"

    /// Considera a cotação velha depois disso.
    private static let staleInterval: TimeInterval = 12 * 60 * 60

    private let defaults: UserDefaults

    /// Moeda na qual todos os totais são exibidos.
    var baseCode: String {
        didSet {
            guard baseCode != oldValue else { return }
            defaults.set(baseCode, forKey: Self.baseKey)
        }
    }

    /// Unidades de cada moeda por 1 USD — a fonte de verdade da conversão.
    private(set) var usdRates: [String: Double]

    private(set) var lastUpdated: Date?
    private(set) var isRefreshing = false
    private(set) var lastError: String?

    init(defaults: UserDefaults = CurrencyService.sharedDefaults) {
        self.defaults = defaults
        self.baseCode = defaults.string(forKey: Self.baseKey) ?? CurrencyCode.brl.code

        let cached = defaults.dictionary(forKey: Self.ratesKey) as? [String: Double]
        self.usdRates = (cached?.isEmpty == false) ? cached! : CurrencyCode.fallbackPerUSD
        self.usdRates["USD"] = 1

        if let stamp = defaults.object(forKey: Self.updatedKey) as? Date {
            self.lastUpdated = stamp
        }
    }

    // MARK: - Conversão

    /// Quantas unidades de `code` valem 1 unidade da moeda base.
    func rate(for code: String) -> Double {
        let target = usdRates[code.uppercased()] ?? 1
        let base = usdRates[baseCode.uppercased()] ?? 1
        guard base != 0 else { return 1 }
        return target / base
    }

    /// Converte `value` de `from` para `to` (padrão: moeda base).
    func convert(_ value: Double, from: String, to: String? = nil) -> Double {
        let target = (to ?? baseCode).uppercased()
        let origin = from.uppercased()
        guard origin != target else { return value }

        let originRate = usdRates[origin] ?? 1
        let targetRate = usdRates[target] ?? 1
        guard originRate != 0 else { return value }
        return value / originRate * targetRate
    }

    /// A cotação está defasada ou nunca foi baixada.
    var needsRefresh: Bool {
        guard let lastUpdated else { return true }
        return Date().timeIntervalSince(lastUpdated) > Self.staleInterval
    }

    var baseCurrency: CurrencyCode { CurrencyCode.from(baseCode) }

    // MARK: - Rede

    /// Baixa as taxas do dia, se ainda não estiver baixando.
    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        let targets = CurrencyCode.allCases
            .filter { $0 != .usd && $0.hasLiveRates }
            .map(\.code)

        var components = URLComponents(string: "https://api.frankfurter.app/latest")
        components?.queryItems = [
            URLQueryItem(name: "from", value: "USD"),
            URLQueryItem(name: "to", value: targets.joined(separator: ","))
        ]

        guard let url = components?.url else { return }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 15
            request.cachePolicy = .reloadIgnoringLocalCacheData

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode < 400 else {
                throw URLError(.badServerResponse)
            }

            let payload = try JSONDecoder().decode(RatesPayload.self, from: data)
            var merged = usdRates
            merged["USD"] = 1
            for (code, value) in payload.rates where value > 0 {
                merged[code.uppercased()] = value
            }

            usdRates = merged
            lastUpdated = Date()
            lastError = nil
            persist()
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Baixa só quando o cache passou do prazo.
    func refreshIfStale() async {
        guard needsRefresh else { return }
        await refresh()
    }

    // MARK: - Persistência

    private func persist() {
        defaults.set(usdRates, forKey: Self.ratesKey)
        defaults.set(lastUpdated, forKey: Self.updatedKey)
        defaults.set(baseCode, forKey: Self.baseKey)
    }

    /// UserDefaults compartilhado com o widget; usa o padrão se o App Group
    /// não estiver disponível (builds sem assinatura).
    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: SharedModelContainer.appGroupID) ?? .standard
    }

    private struct RatesPayload: Decodable {
        let base: String
        let date: String
        let rates: [String: Double]
    }
}
