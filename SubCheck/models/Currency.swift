//
//  Currency.swift
//  SubCheck
//
//  Catálogo de moedas. O `rawValue` é persistido no SwiftData (a assinatura
//  guarda o código da moeda), então nunca deve ser renomeado.
//

import Foundation

enum CurrencyCode: String, CaseIterable, Identifiable, Codable, Hashable {
    case brl = "BRL"
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case jpy = "JPY"
    case cny = "CNY"
    case cad = "CAD"
    case aud = "AUD"
    case chf = "CHF"
    case sek = "SEK"
    case nok = "NOK"
    case dkk = "DKK"
    case pln = "PLN"
    case czk = "CZK"
    case huf = "HUF"
    case ron = "RON"
    case bgn = "BGN"
    case isk = "ISK"
    case tryy = "TRY"
    case zar = "ZAR"
    case inr = "INR"
    case krw = "KRW"
    case sgd = "SGD"
    case hkd = "HKD"
    case nzd = "NZD"
    case ils = "ILS"
    case aed = "AED"
    case thb = "THB"
    case idr = "IDR"
    case myr = "MYR"
    case php = "PHP"
    case mxn = "MXN"
    case ars = "ARS"
    case clp = "CLP"
    case cop = "COP"
    case pen = "PEN"
    case uyu = "UYU"

    var id: String { rawValue }

    /// Código ISO 4217.
    var code: String { rawValue }

    /// Símbolo curto usado em chips e no teclado numérico.
    var symbol: String {
        switch self {
        case .brl: "R$"
        case .usd: "$"
        case .eur: "€"
        case .gbp: "£"
        case .jpy: "¥"
        case .cny: "¥"
        case .cad: "C$"
        case .aud: "A$"
        case .chf: "CHF"
        case .sek: "kr"
        case .nok: "kr"
        case .dkk: "kr"
        case .pln: "zł"
        case .czk: "Kč"
        case .huf: "Ft"
        case .ron: "lei"
        case .bgn: "лв"
        case .isk: "kr"
        case .tryy: "₺"
        case .zar: "R"
        case .inr: "₹"
        case .krw: "₩"
        case .sgd: "S$"
        case .hkd: "HK$"
        case .nzd: "NZ$"
        case .ils: "₪"
        case .aed: "د.إ"
        case .thb: "฿"
        case .idr: "Rp"
        case .myr: "RM"
        case .php: "₱"
        case .mxn: "MX$"
        case .ars: "AR$"
        case .clp: "CLP$"
        case .cop: "COL$"
        case .pen: "S/"
        case .uyu: "$U"
        }
    }

    /// Nome da moeda já localizado pelo sistema (ex: "Real brasileiro").
    var localizedName: String {
        L.current.localizedString(forCurrencyCode: rawValue)?.capitalized
            ?? rawValue
    }

    /// Moedas com cotação ao vivo (o provedor cobre o bloco do Banco Central
    /// Europeu). As demais usam a tabela de reserva embutida no app.
    var hasLiveRates: Bool {
        Self.liveRates.contains(self)
    }

    private static let liveRates: Set<CurrencyCode> = [
        .aud, .bgn, .brl, .cad, .chf, .cny, .czk, .dkk, .eur, .gbp, .hkd,
        .huf, .idr, .ils, .inr, .isk, .jpy, .krw, .mxn, .myr, .nok, .nzd,
        .php, .pln, .ron, .sek, .sgd, .thb, .tryy, .usd, .zar
    ]

    /// Moedas usadas com mais frequência, mostradas primeiro no seletor.
    static let featured: [CurrencyCode] = [.brl, .usd, .eur, .gbp]

    /// Moedas mais usadas primeiro, depois o restante em ordem alfabética.
    static var ordered: [CurrencyCode] {
        let rest = allCases
            .filter { !featured.contains($0) }
            .sorted { $0.localizedName < $1.localizedName }
        return featured + rest
    }

    /// Rótulo para seletores: "R$  BRL — Real brasileiro".
    var displayLabel: String { "\(symbol)  \(code) — \(localizedName)" }

    static func from(_ code: String) -> CurrencyCode {
        CurrencyCode(rawValue: code.uppercased()) ?? .brl
    }
}

// MARK: - Fallback rates

extension CurrencyCode {

    /// Unidades por 1 USD. Usada quando não há cotação baixada nem cache.
    /// Valores aproximados, só para o app nunca ficar sem número.
    static let fallbackPerUSD: [String: Double] = [
        "USD": 1.0,
        "BRL": 5.45,
        "EUR": 0.92,
        "GBP": 0.79,
        "JPY": 151.0,
        "CNY": 7.24,
        "CAD": 1.36,
        "AUD": 1.52,
        "CHF": 0.88,
        "SEK": 10.50,
        "NOK": 10.70,
        "DKK": 6.87,
        "PLN": 3.97,
        "CZK": 23.20,
        "HUF": 358.0,
        "RON": 4.58,
        "BGN": 1.80,
        "ISK": 137.0,
        "TRY": 32.50,
        "ZAR": 18.60,
        "INR": 83.30,
        "KRW": 1340.0,
        "SGD": 1.34,
        "HKD": 7.82,
        "NZD": 1.64,
        "ILS": 3.72,
        "AED": 3.67,
        "THB": 36.50,
        "IDR": 15700.0,
        "MYR": 4.72,
        "PHP": 56.30,
        "MXN": 17.10,
        "ARS": 870.0,
        "CLP": 950.0,
        "COP": 3900.0,
        "PEN": 3.72,
        "UYU": 39.0
    ]
}
