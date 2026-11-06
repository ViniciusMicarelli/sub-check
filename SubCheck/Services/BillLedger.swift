//
//  BillLedger.swift
//  SubCheck
//
//  Mantém as contas do mês em dia: cria a linha de cada conta ativa, registra
//  o valor que a pessoa informa e cuida das duplicatas que o iCloud pode gerar.
//

import Foundation
import SwiftData

/// Onde ficam o salário líquido e o dia em que ele cai.
enum SalaryStore {
    static let amountKey = "monthlyNetSalary"
    static let dayKey = "salaryDay"
}

@MainActor
enum BillLedger {

    /// Garante uma linha do mês atual para cada conta ativa. Idempotente:
    /// pode rodar a cada abertura do app.
    @discardableResult
    static func ensureEntries(
        for bills: [Bill],
        in context: ModelContext,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        let month = BillSchedule.monthStart(of: now, calendar: calendar)
        let descriptor = FetchDescriptor<BillEntry>(predicate: #Predicate { $0.monthStart == month })
        let existing = (try? context.fetch(descriptor)) ?? []
        let have = Set(existing.map(\.billID))

        var inserted = 0
        for bill in bills where bill.isActive && !have.contains(bill.id) {
            context.insert(
                BillEntry(
                    billID: bill.id,
                    billName: bill.name,
                    categoryRaw: bill.categoryRaw,
                    monthStart: month,
                    dueDate: BillSchedule.dueDate(day: bill.dueDay, inMonthOf: month, calendar: calendar),
                    // Conta fixa já nasce com o valor; a variável espera a pessoa.
                    amount: bill.isFixed ? bill.expectedAmount : 0
                )
            )
            inserted += 1
        }
        if inserted > 0 { context.saveReporting() }
        return inserted
    }

    /// Remove linhas repetidas (mesma conta e mesmo mês). Com iCloud, dois
    /// aparelhos podem criar o mês antes de sincronizar. Fica a linha paga.
    @discardableResult
    static func removeDuplicates(in context: ModelContext) -> Int {
        let entries = (try? context.fetch(FetchDescriptor<BillEntry>())) ?? []
        var kept: [String: BillEntry] = [:]
        var removed = 0
        for entry in entries {
            let key = "\(entry.billID.uuidString)-\(entry.monthStart.timeIntervalSince1970)"
            if let existing = kept[key] {
                let loser = (existing.isPaid && !entry.isPaid) ? entry : existing
                if loser === existing { kept[key] = entry }
                context.delete(loser)
                removed += 1
            } else {
                kept[key] = entry
            }
        }
        if removed > 0 { context.saveReporting() }
        return removed
    }

    /// Reagenda os avisos de todas as contas com o que está salvo agora.
    static func rescheduleNotifications(in context: ModelContext) {
        let bills = (try? context.fetch(FetchDescriptor<Bill>())) ?? []
        let entries = (try? context.fetch(FetchDescriptor<BillEntry>())) ?? []
        Task { await NotificationService.shared.scheduleBills(bills, entries: entries) }
    }

    /// Atualiza tudo que mostra as contas fora da tela: avisos, Ilha Dinâmica e
    /// widgets. Chamar depois de criar, editar, pagar ou pular uma conta.
    static func refreshSurfaces(in context: ModelContext) {
        rescheduleNotifications(in: context)
        let subscriptions = (try? context.fetch(FetchDescriptor<Subscription>())) ?? []
        LiveActivityService.shared.syncAll(with: subscriptions)
    }

    /// Registra o valor do mês. `paid` marca como paga na data `paidAt`.
    static func record(
        _ entry: BillEntry,
        amount: Double,
        paid: Bool,
        paidAt: Date = Date(),
        in context: ModelContext
    ) {
        entry.amount = max(amount, 0)
        entry.isPaid = paid
        entry.paidAt = paid ? paidAt : nil
        entry.isSkipped = false
        context.saveReporting()
    }

    /// Volta a conta para "não paga" (o valor informado continua).
    static func unpay(_ entry: BillEntry, in context: ModelContext) {
        entry.isPaid = false
        entry.paidAt = nil
        context.saveReporting()
    }

    static func skip(_ entry: BillEntry, in context: ModelContext) {
        entry.isSkipped = true
        entry.isPaid = false
        entry.paidAt = nil
        context.saveReporting()
    }

    /// Depois de editar uma conta, o mês atual (se ainda não pago) acompanha.
    static func syncCurrentEntry(
        for bill: Bill,
        in context: ModelContext,
        now: Date = Date(),
        calendar: Calendar = .current
    ) {
        let month = BillSchedule.monthStart(of: now, calendar: calendar)
        let id = bill.id
        let descriptor = FetchDescriptor<BillEntry>(
            predicate: #Predicate { $0.billID == id && $0.monthStart == month }
        )
        for entry in (try? context.fetch(descriptor)) ?? [] where !entry.isPaid {
            entry.billName = bill.name
            entry.categoryRaw = bill.categoryRaw
            entry.dueDate = BillSchedule.dueDate(day: bill.dueDay, inMonthOf: month, calendar: calendar)
            if bill.isFixed { entry.amount = bill.expectedAmount }
            if !bill.isActive { entry.isSkipped = true }
        }
        context.saveReporting()
    }

    /// Exclui a conta e os meses ainda não pagos. Os meses pagos ficam como
    /// histórico (têm o nome guardado na própria linha).
    static func delete(_ bill: Bill, in context: ModelContext) {
        let id = bill.id
        let descriptor = FetchDescriptor<BillEntry>(
            predicate: #Predicate { $0.billID == id && !$0.isPaid }
        )
        for entry in (try? context.fetch(descriptor)) ?? [] { context.delete(entry) }
        context.delete(bill)
        context.saveReporting()
    }
}

// MARK: - Plano do mês

enum BillPlanning {

    /// Valores pagos de cada conta antes de `month`, do mais recente para o
    /// mais antigo. Alimenta as estimativas e a variação.
    static func history(of entries: [BillEntry], before month: Date) -> [UUID: [Double]] {
        let past = entries
            .filter { $0.isPaid && !$0.isSkipped && $0.monthStart < month && $0.amount > 0 }
            .sorted { $0.monthStart > $1.monthStart }
        var result: [UUID: [Double]] = [:]
        for entry in past { result[entry.billID, default: []].append(entry.amount) }
        return result
    }

    /// Linhas deste e do mês passado que já venceram (ou vencem hoje) e seguem
    /// sem pagamento: são as que pedem uma ação da pessoa.
    static func dueEntries(
        _ entries: [BillEntry], now: Date = Date(), calendar: Calendar = .current
    ) -> [BillEntry] {
        guard let oldest = calendar.date(byAdding: .month, value: -1, to: BillSchedule.monthStart(of: now, calendar: calendar)) else { return [] }
        return entries
            .filter { !$0.isPaid && !$0.isSkipped && $0.monthStart >= oldest
                && BillMath.daysUntil($0.dueDate, now: now, calendar: calendar) <= 0 }
            .sorted { $0.dueDate < $1.dueDate }
    }

    /// Valor que uma linha ainda não paga deve custar: o informado ou, sem
    /// ele, a estimativa da conta.
    static func pendingAmount(_ entry: BillEntry, bill: Bill?, history: [UUID: [Double]]) -> Double {
        if entry.amount > 0 { return entry.amount }
        return BillMath.estimate(expected: bill?.expectedAmount ?? 0, previous: history[entry.billID] ?? [])
    }
}

extension MonthPlan {

    /// Monta o plano do mês atual com o que está salvo.
    static func make(
        salary: Double,
        subscriptions: [Subscription],
        bills: [Bill],
        entries: [BillEntry],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> MonthPlan {
        let month = BillSchedule.monthStart(of: now, calendar: calendar)
        let history = BillPlanning.history(of: entries, before: month)
        let byID = Dictionary(bills.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let thisMonth = entries.filter { $0.monthStart == month && !$0.isSkipped }

        var paid = 0.0
        var pending = 0.0
        for entry in thisMonth {
            if entry.isPaid {
                paid += entry.amount
            } else {
                pending += BillPlanning.pendingAmount(entry, bill: byID[entry.billID], history: history)
            }
        }

        return MonthPlan(
            salary: salary,
            subscriptions: subscriptions.filter { !$0.isCancelled }.monthlyTotal(in: .shared),
            billsPaid: paid,
            billsPending: pending
        )
    }
}
