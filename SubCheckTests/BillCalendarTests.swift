import SwiftData
import XCTest
@testable import SubCheck

@MainActor
final class BillCalendarTests: XCTestCase {

    private var cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        c.firstWeekday = 1   // domingo
        return c
    }()

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }

    private func month(_ y: Int, _ m: Int) -> Date { BillSchedule.monthStart(of: date(y, m, 1), calendar: cal) }

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: SharedModelContainer.schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
        return ModelContext(container)
    }

    private func paid(_ bill: Bill, _ y: Int, _ m: Int, _ amount: Double, in context: ModelContext) -> BillEntry {
        let e = BillEntry(billID: bill.id, billName: bill.name, categoryRaw: bill.categoryRaw,
                          monthStart: month(y, m), dueDate: date(y, m, bill.dueDay),
                          amount: amount, isPaid: true, paidAt: date(y, m, bill.dueDay))
        context.insert(e)
        return e
    }

    // MARK: Ocorrências

    func testPastMonthShowsOnlyWhatWasRecorded() throws {
        let context = try makeContext()
        let water = Bill(name: "Água", category: .water, dueDay: 5)
        let light = Bill(name: "Luz", category: .electricity, dueDay: 12)
        context.insert(water); context.insert(light)
        let entry = paid(water, 2026, 9, 150, in: context)

        let now = date(2026, 11, 6)
        let sep = BillCalendar.occurrences(bills: [water, light], entries: [entry], month: month(2026, 9), now: now, calendar: cal)
        XCTAssertEqual(sep.map(\.name), ["Água"])         // a luz não tem linha em setembro
        XCTAssertEqual(sep[0].amount, 150)
        XCTAssertFalse(sep[0].isProjected)
    }

    func testFutureMonthProjectsActiveBillsWithEstimates() throws {
        let context = try makeContext()
        let rent = Bill(name: "Aluguel", category: .rent, dueDay: 1, isFixed: true, expectedAmount: 1800)
        let light = Bill(name: "Luz", category: .electricity, dueDay: 12)
        context.insert(rent); context.insert(light)
        let history = [paid(light, 2026, 8, 200, in: context), paid(light, 2026, 9, 220, in: context), paid(light, 2026, 10, 240, in: context)]

        let now = date(2026, 11, 6)
        let dec = BillCalendar.occurrences(bills: [rent, light], entries: history, month: month(2026, 12), now: now, calendar: cal)
        XCTAssertEqual(dec.map(\.name), ["Aluguel", "Luz"])
        XCTAssertTrue(dec.allSatisfy { $0.isProjected && $0.isEstimate && $0.status == .upcoming })
        XCTAssertEqual(dec[0].amount, 1800)
        XCTAssertEqual(dec[1].amount, 220, accuracy: 0.001)       // média de 200, 220, 240
    }

    func testSkippedEntriesDoNotComeBackAsProjections() throws {
        let context = try makeContext()
        let water = Bill(name: "Água", dueDay: 5)
        context.insert(water)
        let skipped = BillEntry(billID: water.id, billName: "Água", categoryRaw: "water",
                                monthStart: month(2026, 11), dueDate: date(2026, 11, 5))
        skipped.isSkipped = true
        context.insert(skipped)

        let nov = BillCalendar.occurrences(bills: [water], entries: [skipped], month: month(2026, 11), now: date(2026, 11, 6), calendar: cal)
        XCTAssertTrue(nov.isEmpty)
    }

    func testMonthPlanForAFutureMonthUsesProjections() throws {
        let context = try makeContext()
        let rent = Bill(name: "Aluguel", dueDay: 1, isFixed: true, expectedAmount: 1800)
        context.insert(rent)
        let plan = MonthPlan.make(salary: 5000, subscriptions: [], bills: [rent], entries: [],
                                  month: month(2027, 1), now: date(2026, 11, 6), calendar: cal)
        XCTAssertEqual(plan.billsPending, 1800)
        XCTAssertEqual(plan.remaining, 3200)
    }

    // MARK: Grade

    func testWeeksGridForNovember2026() {
        // 1º de novembro de 2026 é domingo.
        let weeks = BillCalendar.weeks(for: month(2026, 11), calendar: cal)
        XCTAssertEqual(weeks.count, 5)
        XCTAssertTrue(weeks.allSatisfy { $0.count == 7 })
        XCTAssertEqual(cal.component(.day, from: weeks[0][0]!), 1)
        XCTAssertEqual(weeks.flatMap { $0 }.compactMap { $0 }.count, 30)
        XCTAssertNil(weeks[4][6])    // 30/nov é segunda: o resto da semana fica vazio
    }

    func testWeeksGridStartsOnTheRightWeekday() {
        // 1º de dezembro de 2026 é terça: duas posições vazias antes (domingo, segunda).
        let weeks = BillCalendar.weeks(for: month(2026, 12), calendar: cal)
        XCTAssertNil(weeks[0][0]); XCTAssertNil(weeks[0][1])
        XCTAssertEqual(cal.component(.day, from: weeks[0][2]!), 1)

        var monday = cal; monday.firstWeekday = 2
        let mondayWeeks = BillCalendar.weeks(for: month(2026, 12), calendar: monday)
        XCTAssertNil(mondayWeeks[0][0])
        XCTAssertEqual(monday.component(.day, from: mondayWeeks[0][1]!), 1)
    }

    // MARK: Assinaturas no calendário

    func testSubscriptionChargesInAMonth() {
        let monthly = Subscription(name: "Netflix", cost: 55.9, startDate: date(2026, 1, 10), frequency: .monthly)
        let weekly = Subscription(name: "Revista", cost: 10, startDate: date(2026, 11, 2), frequency: .weekly)
        let cancelled = Subscription(name: "Velha", cost: 9, startDate: date(2026, 1, 3), isCancelled: true)

        let charges = SubscriptionCalendar.charges(of: [monthly, weekly, cancelled], inMonth: month(2026, 11), calendar: cal)
        XCTAssertEqual(charges.filter { $0.name == "Netflix" }.count, 1)
        XCTAssertEqual(charges.filter { $0.name == "Revista" }.count, 5)   // 2, 9, 16, 23, 30
        XCTAssertFalse(charges.contains { $0.name == "Velha" })
        XCTAssertEqual(charges, charges.sorted { $0.date < $1.date })
    }

    // MARK: Evolução

    func testEvolutionTotalsPastCountOnlyInformedAmounts() throws {
        let context = try makeContext()
        let rent = Bill(name: "Aluguel", category: .rent, dueDay: 1, isFixed: true, expectedAmount: 1800)
        let light = Bill(name: "Luz", category: .electricity, dueDay: 12)
        context.insert(rent); context.insert(light)
        var entries = [paid(rent, 2026, 9, 1800, in: context), paid(light, 2026, 9, 200, in: context),
                       paid(rent, 2026, 10, 1800, in: context), paid(light, 2026, 10, 260, in: context)]
        // outubro tem uma linha sem valor: não pode virar "estimativa" no passado
        let blank = BillEntry(billID: light.id, billName: "Luz", categoryRaw: "electricity", monthStart: month(2026, 8), dueDate: date(2026, 8, 12))
        context.insert(blank); entries.append(blank)

        let totals = BillEvolution.totals(bills: [rent, light], entries: entries, endingAt: month(2026, 11), count: 4, now: date(2026, 11, 6), calendar: cal)
        XCTAssertEqual(totals.map { cal.component(.month, from: $0.month) }, [8, 9, 10, 11])
        XCTAssertEqual(totals[0].total, 0)                 // agosto: só a linha vazia
        XCTAssertEqual(totals[1].total, 2000)
        XCTAssertEqual(totals[2].total, 2060)
        XCTAssertFalse(totals[2].isProjected)
        XCTAssertTrue(totals[3].isProjected)               // novembro: previsão
        XCTAssertEqual(totals[3].total, 1800 + 230, accuracy: 0.001)   // luz = média de 200 e 260
    }

    func testChangesAgainstRecentAverage() throws {
        let context = try makeContext()
        let light = Bill(name: "Luz", category: .electricity, dueDay: 12)
        let water = Bill(name: "Água", category: .water, dueDay: 5)
        context.insert(light); context.insert(water)
        var entries = [
            paid(light, 2026, 8, 200, in: context), paid(light, 2026, 9, 200, in: context), paid(light, 2026, 10, 200, in: context),
            paid(water, 2026, 8, 100, in: context), paid(water, 2026, 9, 100, in: context), paid(water, 2026, 10, 100, in: context)
        ]
        entries.append(paid(light, 2026, 11, 236, in: context))   // +18%
        entries.append(paid(water, 2026, 11, 101, in: context))   // +1%: abaixo do limite

        let now = date(2026, 11, 20)
        let occ = BillCalendar.occurrences(bills: [light, water], entries: entries, month: month(2026, 11), now: now, calendar: cal)
        let changes = BillEvolution.changes(occurrences: occ, entries: entries, month: month(2026, 11), calendar: cal)
        XCTAssertEqual(changes.map(\.name), ["Luz"])
        XCTAssertEqual(changes[0].change, 0.18, accuracy: 0.001)
    }
}
