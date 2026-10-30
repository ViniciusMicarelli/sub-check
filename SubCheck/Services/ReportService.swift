//
//  ReportService.swift
//  SubCheck
//
//  Relatório mensal em PDF: resumo dos gastos, quebra por categoria e a
//  lista de assinaturas. Recurso Pro.
//

import Foundation
import UIKit

enum ReportService {

    /// Tamanho da folha (A4 em pontos) e margens.
    private static let pageSize = CGSize(width: 595, height: 842)
    private static let margin: CGFloat = 40

    /// Gera o PDF e devolve o arquivo pronto para o `ShareLink`.
    /// `nil` quando não há assinaturas.
    static func monthlyReport(_ subscriptions: [Subscription]) -> URL? {
        guard !subscriptions.isEmpty else { return nil }

        let active = subscriptions.filter { !$0.isCancelled }
        let monthly = active.monthlyTotal(in: .shared)

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(origin: .zero, size: pageSize)
        )

        let data = renderer.pdfData { context in
            var cursor = CGPoint(x: margin, y: margin)

            context.beginPage()
            cursor = drawHeader(at: cursor)
            cursor = drawSummary(monthly: monthly, active: active.count, at: cursor)
            cursor = drawCategories(active, at: cursor)
            cursor = drawTable(subscriptions, at: cursor, context: context)
        }

        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("subcheck-relatorio.pdf")

        do {
            try data.write(to: file, options: .atomic)
            return file
        } catch {
            return nil
        }
    }

    // MARK: - Seções

    private static func drawHeader(at point: CGPoint) -> CGPoint {
        let title = L.t("Relatório SubCheck")
        draw(title, at: point, font: .systemFont(ofSize: 24, weight: .bold), color: .black)

        let subtitle = Date().formatted(date: .long, time: .omitted)
        let next = CGPoint(x: point.x, y: point.y + 32)
        draw(subtitle, at: next, font: .systemFont(ofSize: 12), color: .darkGray)

        let line = CGPoint(x: point.x, y: next.y + 26)
        UIColor.systemGray4.setStroke()
        let path = UIBezierPath()
        path.move(to: line)
        path.addLine(to: CGPoint(x: pageSize.width - margin, y: line.y))
        path.lineWidth = 1
        path.stroke()

        return CGPoint(x: point.x, y: line.y + 24)
    }

    private static func drawSummary(monthly: Double, active: Int, at point: CGPoint) -> CGPoint {
        var cursor = point
        cursor = draw(L.t("Resumo"), at: cursor, font: .systemFont(ofSize: 16, weight: .semibold), color: .black, spacingAfter: 12)

        let rows: [(String, String)] = [
            (L.t("Total mensal"), Money.format(monthly)),
            (L.t("Custo anual"), Money.format(monthly * 12)),
            (L.t("Assinaturas ativas"), "\(active)")
        ]

        for (label, value) in rows {
            draw(label, at: cursor, font: .systemFont(ofSize: 12), color: .darkGray)
            draw(value, at: CGPoint(x: pageSize.width - margin - 160, y: cursor.y), width: 160, font: .systemFont(ofSize: 12, weight: .semibold), color: .black, alignment: .right)
            cursor = CGPoint(x: cursor.x, y: cursor.y + 20)
        }

        return CGPoint(x: point.x, y: cursor.y + 14)
    }

    private static func drawCategories(_ subscriptions: [Subscription], at point: CGPoint) -> CGPoint {
        var cursor = draw(L.t("Gastos por categoria"), at: point, font: .systemFont(ofSize: 16, weight: .semibold), color: .black, spacingAfter: 12)

        let grouped = Dictionary(grouping: subscriptions, by: \.categoryType)
            .map { category, items in
                (category.displayName, items.monthlyTotal(in: .shared))
            }
            .sorted { $0.1 > $1.1 }

        for (name, total) in grouped {
            draw(name, at: cursor, font: .systemFont(ofSize: 12), color: .darkGray)
            draw(Money.format(total), at: CGPoint(x: pageSize.width - margin - 160, y: cursor.y), width: 160, font: .systemFont(ofSize: 12), color: .black, alignment: .right)
            cursor = CGPoint(x: cursor.x, y: cursor.y + 20)
        }

        return CGPoint(x: point.x, y: cursor.y + 14)
    }

    private static func drawTable(
        _ subscriptions: [Subscription],
        at point: CGPoint,
        context: UIGraphicsPDFRendererContext
    ) -> CGPoint {
        var cursor = draw(L.t("Assinaturas"), at: point, font: .systemFont(ofSize: 16, weight: .semibold), color: .black, spacingAfter: 12)

        let columns: [CGFloat] = [0, 220, 300, 380, 470]
        let header = [L.t("Nome"), L.t("Valor"), L.t("Frequência"), L.t("Próxima cobrança")]

        for (index, title) in header.enumerated() {
            draw(title, at: CGPoint(x: margin + columns[index], y: cursor.y), width: 120, font: .systemFont(ofSize: 11, weight: .semibold), color: .darkGray)
        }
        cursor = CGPoint(x: cursor.x, y: cursor.y + 20)

        for subscription in subscriptions.sorted(by: { $0.nextBillingDate < $1.nextBillingDate }) {
            // Nova página quando a linha passaria do rodapé.
            if cursor.y > pageSize.height - margin - 24 {
                context.beginPage()
                cursor = CGPoint(x: margin, y: margin)
            }

            let values = [
                subscription.isCancelled ? "\(subscription.name) (\(L.t("Cancelada")))" : subscription.name,
                Money.format(subscription.cost, code: subscription.currencyCode),
                subscription.frequency.displayName,
                subscription.nextBillingDate.formatted(date: .abbreviated, time: .omitted)
            ]

            for (index, value) in values.enumerated() {
                draw(
                    value,
                    at: CGPoint(x: margin + columns[index], y: cursor.y),
                    width: index == 0 ? 210 : 110,
                    font: .systemFont(ofSize: 11),
                    color: .black
                )
            }

            cursor = CGPoint(x: cursor.x, y: cursor.y + 18)
        }

        return cursor
    }

    // MARK: - Desenho

    @discardableResult
    private static func draw(
        _ text: String,
        at point: CGPoint,
        width: CGFloat = 400,
        font: UIFont,
        color: UIColor,
        alignment: NSTextAlignment = .left,
        spacingAfter: CGFloat = 0
    ) -> CGPoint {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineBreakMode = .byTruncatingTail

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]

        let bounding = CGSize(width: width, height: 18)
        (text as NSString).draw(
            with: CGRect(origin: point, size: bounding),
            options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine],
            attributes: attributes,
            context: nil
        )

        return CGPoint(x: point.x, y: point.y + 18 + spacingAfter)
    }
}
