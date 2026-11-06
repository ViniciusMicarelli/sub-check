//
//  SampleDataSeeder.swift
//  SubCheck
//
//  Fills the store with a realistic starter set the first time the app runs
//  so the dashboard, charts and widgets have something to show.
//

import Foundation
import SwiftData

@MainActor
enum SampleDataSeeder {

    private struct Sample {
        let name: String
        let cost: Double
        let frequency: RecurrenceFrequency
        let category: CategoryType
        let startMonthsAgo: Int
    }

    private static let samples: [Sample] = [
        Sample(name: "Netflix", cost: 55.90, frequency: .monthly, category: .entertainment, startMonthsAgo: 14),
        Sample(name: "Spotify", cost: 21.90, frequency: .monthly, category: .entertainment, startMonthsAgo: 22),
        Sample(name: "iCloud+", cost: 12.90, frequency: .monthly, category: .utilities, startMonthsAgo: 30),
        Sample(name: "Figma", cost: 89.00, frequency: .monthly, category: .productivity, startMonthsAgo: 9),
        Sample(name: "Amazon Prime", cost: 19.90, frequency: .monthly, category: .entertainment, startMonthsAgo: 18),
        Sample(name: "Smart Fit", cost: 119.90, frequency: .monthly, category: .health, startMonthsAgo: 6),
        Sample(name: "Notion", cost: 48.00, frequency: .monthly, category: .productivity, startMonthsAgo: 4),
        Sample(name: "Folha de S.Paulo", cost: 29.90, frequency: .monthly, category: .news, startMonthsAgo: 12),
        Sample(name: "Duolingo", cost: 39.90, frequency: .yearly, category: .education, startMonthsAgo: 8),
        Sample(name: "Adobe Creative Cloud", cost: 299.00, frequency: .monthly, category: .productivity, startMonthsAgo: 20),
        Sample(name: "Sem Parar", cost: 24.90, frequency: .monthly, category: .transport, startMonthsAgo: 16),
        Sample(name: "1Password", cost: 179.00, frequency: .yearly, category: .utilities, startMonthsAgo: 5)
    ]

    /// Dados de exemplo só existem em builds de desenvolvimento, e uma única
    /// vez. Em produção o app abre vazio (e, com iCloud, esperando a nuvem),
    /// e nunca repõe exemplos depois que o usuário apaga tudo.
    static func seedIfNeeded(in context: ModelContext) {
        #if DEBUG
        let key = "sampleDataSeeded"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)

        let count = (try? context.fetchCount(FetchDescriptor<Subscription>())) ?? 0
        guard count == 0 else { return }
        seed(in: context)
        #endif
    }

    static func seed(in context: ModelContext) {
        let calendar = Calendar.current
        for sample in samples {
            let start = calendar.date(byAdding: .month, value: -sample.startMonthsAgo, to: Date()) ?? Date()
            let subscription = Subscription(
                name: sample.name,
                cost: sample.cost,
                startDate: start,
                frequency: sample.frequency,
                category: sample.category.rawValue
            )
            context.insert(subscription)
        }
        try? context.save()
        seedBills(in: context)
    }

    /// Salário e contas de exemplo (só em desenvolvimento), com histórico para
    /// as estimativas e o gráfico.
    static func seedBills(in context: ModelContext) {
        #if DEBUG
        let calendar = Calendar.current
        let today = calendar.component(.day, from: Date())
        func day(_ offset: Int) -> Int { min(max(today + offset, 1), 28) }

        UserDefaults.standard.set(6200.0, forKey: SalaryStore.amountKey)
        UserDefaults.standard.set(5, forKey: SalaryStore.dayKey)

        let specs: [(String, BillCategory, Int, Bool, Double, [Double])] = [
            ("Aluguel", .rent, 1, true, 1800, [1800, 1800, 1800]),
            ("Condomínio", .condo, day(-3), true, 540, [540, 540, 520]),
            ("Conta de água", .water, day(0), false, 0, [171.2, 156.8, 142.3]),
            ("Conta de luz", .electricity, day(7), false, 0, [236.1, 198.9, 212.4]),
            ("Internet", .internet, day(4), true, 119.9, [119.9, 119.9, 119.9]),
            ("Celular", .phone, day(10), true, 59.9, [59.9, 59.9, 59.9])
        ]

        var bills: [Bill] = []
        for spec in specs {
            let bill = Bill(name: spec.0, category: spec.1, dueDay: spec.2, isFixed: spec.3, expectedAmount: spec.4)
            context.insert(bill)
            bills.append(bill)
            for (index, amount) in spec.5.enumerated() {
                let reference = calendar.date(byAdding: .month, value: -(index + 1), to: Date()) ?? Date()
                let due = BillSchedule.dueDate(day: spec.2, inMonthOf: reference)
                context.insert(BillEntry(
                    billID: bill.id, billName: bill.name, categoryRaw: bill.categoryRaw,
                    monthStart: BillSchedule.monthStart(of: reference), dueDate: due,
                    amount: amount, isPaid: true, paidAt: due
                ))
            }
        }
        try? context.save()
        BillLedger.ensureEntries(for: bills, in: context)

        // O aluguel deste mês já foi pago.
        let month = BillSchedule.monthStart(of: Date())
        let entries = (try? context.fetch(FetchDescriptor<BillEntry>(predicate: #Predicate { $0.monthStart == month }))) ?? []
        if let rent = entries.first(where: { $0.billName == "Aluguel" }) {
            BillLedger.record(rent, amount: 1800, paid: true, in: context)
        }
        #endif
    }

    static func eraseAll(in context: ModelContext) {
        try? context.delete(model: Subscription.self)
        try? context.delete(model: DeletedSubscription.self)
        try? context.delete(model: PaymentRecord.self)
        try? context.delete(model: Bill.self)
        try? context.delete(model: BillEntry.self)
        UserDefaults.standard.removeObject(forKey: SalaryStore.amountKey)
        UserDefaults.standard.removeObject(forKey: SalaryStore.dayKey)
        try? context.save()
    }
}
