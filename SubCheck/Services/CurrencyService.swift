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

    /// Fotos diárias das cotações, para mostrar quanto o câmbio mudou.
    private(set) var history: RateHistory

    init(defaults: UserDefaults = CurrencyService.sharedDefaults) {
        self.defaults = defaults
        self.history = Self.loadHistory()
        self.baseCode = defaults.string(forKey: Self.baseKey) ?? CurrencyCode.brl.code

        let cached = defaults.dictionary(forKey: Self.ratesKey) as? [String: Double]
        self.usdRates = (cached?.isEmpty == false) ? cached! : CurrencyCode.fallbackPerUSD
        self.usdRates["USD"] = 1

        if let stamp = defaults.object(forKey: Self.updatedKey) as? Date {
            self.lastUpdated = stamp
        }

    }

    // MARK: - Histórico

    /// Cotação de `from` em `to` na data do pagamento. Sem foto próxima no
    /// histórico, só aceita a cotação atual se a data for hoje.
    func historicalRate(from: String, to: String, on date: Date) -> Double? {
        if from.uppercased() == to.uppercased() { return 1 }
        if let rate = history.rate(from: from, to: to, on: date) { return rate }
        guard Calendar.current.isDateInToday(date) else { return nil }
        return convert(1, from: from, to: to)
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
            history.record(merged, at: Date())
            persist()
            Self.saveHistory(history)
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

    // O histórico é um arquivo (não UserDefaults): um ano de cotações passa
    // de 300 KB. Fica no App Group para o widget também enxergar.
    private static var historyURL: URL? {
        let base = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: SharedModelContainer.appGroupID)
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        return base?.appendingPathComponent("exchange-history.json")
    }

    private static func loadHistory() -> RateHistory {
        guard let url = historyURL,
              let data = try? Data(contentsOf: url),
              let snapshots = try? JSONDecoder().decode([RateSnapshot].self, from: data)
        else { return RateHistory() }
        return RateHistory(snapshots: snapshots)
    }

    private static func saveHistory(_ history: RateHistory) {
        guard let url = historyURL,
              let data = try? JSONEncoder().encode(history.snapshots) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private struct RatesPayload: Decodable {
        let base: String
        let date: String
        let rates: [String: Double]
    }
}
