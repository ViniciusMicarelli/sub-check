//
//  StatementImport.swift
//  SubCheck
//
//  Lê o CSV de um extrato (cartão ou conta) e descobre quais lançamentos se
//  repetem como assinatura. Tudo é lógica pura e roda no aparelho: o arquivo
//  nunca sai do celular.
//

import Foundation

// MARK: - Lançamento

struct StatementTransaction: Equatable {
    var date: Date
    var description: String
    /// Sempre positivo: quanto saiu da conta.
    var amount: Double
}

// MARK: - Leitura do CSV

enum StatementParser {

    static func parse(_ text: String, calendar: Calendar = .current) -> [StatementTransaction] {
        let normalized = text
            .replacingOccurrences(of: "\u{FEFF}", with: "")
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let lines = normalized.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
        guard let first = lines.first else { return [] }

        let delimiter = detectDelimiter(first)
        let rows = lines.map { splitRow($0, delimiter: delimiter) }

        // Cabeçalho = primeira linha sem nenhuma data.
        let hasHeader = !(rows[0].contains { parseDate($0, calendar: calendar) != nil })
        let header = hasHeader ? rows[0].map(fold) : []
        let body = hasHeader ? Array(rows.dropFirst()) : rows
        guard !body.isEmpty else { return [] }

        guard let columns = mapColumns(header: header, body: body, calendar: calendar) else { return [] }

        var parsed: [(Date, String, Double)] = []
        for row in body {
            guard row.indices.contains(columns.date),
                  row.indices.contains(columns.description),
                  row.indices.contains(columns.amount),
                  let date = parseDate(row[columns.date], calendar: calendar),
                  let value = parseNumber(row[columns.amount]) else { continue }
            let text = row[columns.description].trimmingCharacters(in: .whitespaces)
            guard !text.isEmpty, value != 0 else { continue }
            parsed.append((date, text, value))
        }

        // Cartão costuma trazer gastos positivos; conta traz gastos negativos.
        // O sinal que domina é o dos gastos; o outro (estorno, pagamento da
        // fatura, salário) é ignorado.
        let negatives = parsed.filter { $0.2 < 0 }.count
        let spendIsNegative = negatives > parsed.count - negatives

        return parsed
            .filter { spendIsNegative ? $0.2 < 0 : $0.2 > 0 }
            .map { StatementTransaction(date: $0.0, description: $0.1, amount: abs($0.2)) }
    }

    // MARK: Colunas

    private struct Columns { let date: Int; let description: Int; let amount: Int }

    private static func mapColumns(
        header: [String], body: [[String]], calendar: Calendar
    ) -> Columns? {
        func index(_ keys: [String]) -> Int? {
            header.firstIndex { h in keys.contains { h.contains($0) } }
        }

        var date = index(["data", "date"])
        var description = index(["descri", "hist", "lanca", "estabelec", "title", "titulo", "memo", "merchant", "name", "nome", "detalhe"])
        var amount = index(["valor", "amount", "value", "quantia"])

        let width = body.map(\.count).max() ?? 0
        func score(_ column: Int, _ test: (String) -> Bool) -> Int {
            body.filter { $0.indices.contains(column) && test($0[column]) }.count
        }

        if date == nil {
            date = (0..<width).max { score($0) { parseDate($0, calendar: calendar) != nil } < score($1) { parseDate($0, calendar: calendar) != nil } }
        }
        if amount == nil {
            let candidates = (0..<width).filter { $0 != date }
            amount = candidates.max { score($0) { parseNumber($0) != nil && parseDate($0, calendar: calendar) == nil } < score($1) { parseNumber($0) != nil && parseDate($0, calendar: calendar) == nil } }
        }
        if description == nil {
            let candidates = (0..<width).filter { $0 != date && $0 != amount }
            description = candidates.max { avgLength($0, body) < avgLength($1, body) }
        }

        guard let date, let description, let amount, date != amount, description != amount, description != date,
              score(date, { parseDate($0, calendar: calendar) != nil }) > 0 else { return nil }
        return Columns(date: date, description: description, amount: amount)
    }

    private static func avgLength(_ column: Int, _ body: [[String]]) -> Double {
        let values = body.compactMap { $0.indices.contains(column) ? Double($0[column].count) : nil }
        return values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
    }

    // MARK: Células

    private static func detectDelimiter(_ line: String) -> Character {
        var counts: [Character: Int] = [";": 0, ",": 0, "\t": 0]
        var inQuotes = false
        for ch in line {
            if ch == "\"" { inQuotes.toggle() }
            else if !inQuotes, counts[ch] != nil { counts[ch]! += 1 }
        }
        // Em extrato brasileiro o ";" separa campos e a vírgula é decimal.
        if counts[";"]! > 0, counts[";"]! >= counts[","]! { return ";" }
        if counts["\t"]! > counts[","]! { return "\t" }
        return ","
    }

    static func splitRow(_ line: String, delimiter: Character) -> [String] {
        var cells: [String] = []
        var current = ""
        var inQuotes = false
        var iterator = line.makeIterator()
        var pending: Character? = iterator.next()

        while let ch = pending {
            pending = iterator.next()
            if ch == "\"" {
                if inQuotes, pending == "\"" { current.append("\""); pending = iterator.next() }
                else { inQuotes.toggle() }
            } else if ch == delimiter && !inQuotes {
                cells.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(ch)
            }
        }
        cells.append(current.trimmingCharacters(in: .whitespaces))
        return cells
    }

    /// Minúsculas e sem acento, para casar cabeçalhos.
    static func fold(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
    }

    /// Aceita dd/MM/yyyy, dd/MM/yy, dd-MM-yyyy, dd.MM.yyyy e yyyy-MM-dd
    /// (com ou sem hora). Entre dia e mês, assume dia primeiro (formato BR).
    static func parseDate(_ text: String, calendar: Calendar = .current) -> Date? {
        let value = text.trimmingCharacters(in: .whitespaces)
        let parts = value.split(whereSeparator: { "-/. T".contains($0) }).map(String.init)
        guard parts.count >= 3, parts.prefix(3).allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isNumber) }) else { return nil }

        var year: Int, month: Int, day: Int
        if parts[0].count == 4 {
            year = Int(parts[0])!; month = Int(parts[1])!; day = Int(parts[2])!
        } else {
            day = Int(parts[0])!; month = Int(parts[1])!; year = Int(parts[2])!
            if parts[2].count == 2 { year += 2000 }
        }
        guard (1...12).contains(month), (1...31).contains(day), (1990...2100).contains(year) else { return nil }
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))
    }

    /// Aceita "1.234,56", "1,234.56", "-39,90", "R$ 39,90", "(39,90)", "39.90".
    static func parseNumber(_ text: String) -> Double? {
        var value = text.trimmingCharacters(in: .whitespaces)
        guard !value.isEmpty else { return nil }

        var negative = false
        if value.hasPrefix("(") && value.hasSuffix(")") { negative = true }
        value = value.filter { $0.isNumber || $0 == "," || $0 == "." || $0 == "-" }
        if value.contains("-") { negative = true; value = value.replacingOccurrences(of: "-", with: "") }
        guard value.contains(where: \.isNumber) else { return nil }

        let lastComma = value.lastIndex(of: ",")
        let lastDot = value.lastIndex(of: ".")
        switch (lastComma, lastDot) {
        case let (comma?, dot?):
            if comma > dot { value = value.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".") }
            else { value = value.replacingOccurrences(of: ",", with: "") }
        case (_?, nil):
            value = value.replacingOccurrences(of: ",", with: ".")
        case (nil, _?):
            if value.filter({ $0 == "." }).count > 1 { value = value.replacingOccurrences(of: ".", with: "") }
        case (nil, nil):
            break
        }

        guard let number = Double(value), number.isFinite else { return nil }
        return negative ? -number : number
    }
}

// MARK: - Detecção de recorrência

struct DetectedSubscription: Identifiable, Equatable {
    enum Confidence { case high, medium }

    var id: String { key }
    let key: String
    let name: String
    /// Valor da cobrança mais recente.
    let amount: Double
    let frequency: RecurrenceFrequency
    let firstDate: Date
    let lastDate: Date
    let occurrences: Int
    let confidence: Confidence
    /// `false` quando a última cobrança é velha demais: provavelmente foi cancelada.
    let isLikelyActive: Bool
}

enum RecurrenceDetector {

    /// Palavras que aparecem em quase todo lançamento e não identificam o comércio.
    private static let noise: Set<String> = [
        "compra", "cartao", "debito", "credito", "pagamento", "pgto", "pag", "parcela",
        "pix", "ltda", "sa", "me", "br", "www", "com", "mp", "pg", "em", "de", "do", "da",
        "no", "na", "transferencia", "enviada", "recebida", "visa", "master", "elo", "internacional", "int"
    ]

    /// Marcas que vendem vários serviços: aqui a segunda palavra decide
    /// ("Google One" não é "Google Play").
    private static let umbrella: Set<String> = [
        "google", "apple", "amazon", "microsoft", "mercado", "paypal", "adobe", "uber", "meta"
    ]

    /// Palavras que identificam o comércio. Cidade e códigos que vêm depois
    /// ("NETFLIX SP") variam de uma cobrança para outra e ficam de fora.
    private static func identity(_ description: String) -> [String] {
        let words = tokens(description)
        guard let first = words.first else { return [] }
        return umbrella.contains(first) ? Array(words.prefix(2)) : [first]
    }

    /// Chave estável do comércio.
    static func merchantKey(_ description: String) -> String {
        identity(description).joined(separator: " ")
    }

    static func displayName(_ description: String) -> String {
        identity(description).map { $0.capitalized }.joined(separator: " ")
    }

    private static func tokens(_ description: String) -> [String] {
        StatementParser.fold(description)
            .map { $0.isLetter ? $0 : " " }
            .reduce(into: "") { $0.append($1) }
            .split(separator: " ")
            .map(String.init)
            .filter { $0.count > 1 && !noise.contains($0) }
    }

    static func detect(
        _ transactions: [StatementTransaction],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [DetectedSubscription] {
        let groups = Dictionary(grouping: transactions) { merchantKey($0.description) }
        var result: [DetectedSubscription] = []

        for (key, items) in groups where !key.isEmpty {
            guard let detected = analyze(key: key, items: items, now: now, calendar: calendar) else { continue }
            result.append(detected)
        }
        // Mais caras primeiro; o mais importante aparece no topo.
        return result.sorted { $0.amount > $1.amount }
    }

    private static func analyze(
        key: String, items: [StatementTransaction], now: Date, calendar: Calendar
    ) -> DetectedSubscription? {
        // Um lançamento por dia (mesma compra duplicada no extrato não conta).
        var byDay: [Date: StatementTransaction] = [:]
        for item in items { byDay[calendar.startOfDay(for: item.date)] = item }
        let sorted = byDay.values.sorted { $0.date < $1.date }
        guard sorted.count >= 2 else { return nil }

        // Valores parecidos: descarta o que foge muito da mediana (compras avulsas).
        let amounts = sorted.map(\.amount).sorted()
        let median = amounts[amounts.count / 2]
        let consistent = sorted.filter { abs($0.amount - median) <= median * 0.2 }
        guard consistent.count >= 2 else { return nil }

        let days = consistent.map { calendar.startOfDay(for: $0.date) }
        let intervals = zip(days, days.dropFirst()).map {
            calendar.dateComponents([.day], from: $0, to: $1).day ?? 0
        }

        guard let frequency = frequency(for: intervals) else { return nil }

        // Poucas ocorrências só valem se o valor é praticamente idêntico.
        let spread = (amounts.last! - amounts.first!) / max(median, 0.01)
        if consistent.count == 2 && spread > 0.01 { return nil }
        if frequency == .weekly && consistent.count < 3 { return nil }

        let last = consistent.last!
        let first = consistent.first!
        let period: Double = switch frequency {
        case .weekly: 7
        case .monthly: 31
        case .yearly: 366
        }
        let sinceLast = Double(calendar.dateComponents([.day], from: last.date, to: now).day ?? 0)

        let tight = consistent.count >= 3 && spread <= 0.05
        return DetectedSubscription(
            key: key,
            name: displayName(last.description),
            amount: last.amount,
            frequency: frequency,
            firstDate: first.date,
            lastDate: last.date,
            occurrences: consistent.count,
            confidence: tight ? .high : .medium,
            isLikelyActive: sinceLast <= period * 1.6
        )
    }

    /// Frequência pela maioria dos intervalos entre cobranças.
    static func frequency(for intervals: [Int]) -> RecurrenceFrequency? {
        guard !intervals.isEmpty else { return nil }
        func share(_ range: ClosedRange<Int>) -> Double {
            Double(intervals.filter(range.contains).count) / Double(intervals.count)
        }
        if share(6...8) >= 0.7 { return .weekly }
        if share(26...35) >= 0.7 { return .monthly }
        if share(350...380) >= 0.7 { return .yearly }
        return nil
    }
}
