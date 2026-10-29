//
//  ExportService.swift
//  SubCheck
//
//  Gera um CSV com todas as assinaturas para compartilhar. Recurso Pro.
//

import Foundation
import SwiftData

enum ExportService {

    /// Cabeçalho do arquivo, no idioma escolhido no app.
    private static var header: [String] {
        [
            L.t("Nome"),
            L.t("Categoria"),
            L.t("Valor"),
            L.t("Moeda"),
            L.t("Frequência"),
            L.t("Início"),
            L.t("Próxima cobrança"),
            L.t("Situação"),
            L.t("Média mensal")
        ]
    }

    /// Arquivo temporário pronto para o `ShareLink`. `nil` se não houver nada
    /// para exportar.
    static func subscriptionsCSV(_ subscriptions: [Subscription]) -> URL? {
        guard !subscriptions.isEmpty else { return nil }

        var rows: [String] = [row(header)]
        for subscription in subscriptions {
            rows.append(row([
                subscription.name,
                subscription.categoryType.displayName,
                decimal(subscription.cost),
                subscription.currencyCode,
                subscription.frequency.displayName,
                day(subscription.startDate),
                day(subscription.nextBillingDate),
                subscription.isCancelled ? L.t("Cancelada") : L.t("Ativa"),
                decimal(subscription.monthlyCost)
            ]))
        }

        // Uma linha por registro; vírgula como separador.
        let csv = rows.joined(separator: "\r\n") + "\r\n"

        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("subcheck-assinaturas.csv")

        do {
            try csv.write(to: file, atomically: true, encoding: .utf8)
            return file
        } catch {
            return nil
        }
    }

    // MARK: - Formatação

    private static func row(_ fields: [String]) -> String {
        fields.map(escaped).joined(separator: ",")
    }

    /// Aspas quando o campo contém separador, aspas ou quebra de linha.
    private static func escaped(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) else {
            return field
        }
        return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    /// Sempre com ponto decimal, para planilhas lerem como número.
    private static func decimal(_ value: Double) -> String {
        String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), value)
    }

    /// Data em ISO 8601 (só o dia), independente do idioma do app.
    private static func day(_ date: Date) -> String {
        date.formatted(
            .iso8601.year().month().day().dateSeparator(.dash)
        )
    }
}
