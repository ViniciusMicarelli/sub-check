import SwiftData
import XCTest
@testable import SubCheck

final class BillRulesTests: XCTestCase {

    private var cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }

    // MARK: Calendário

    func testDueDateClampsToShortMonths() {
        XCTAssertEqual(cal.component(.day, from: BillSchedule.dueDate(day: 31, inMonthOf: date(2027, 2, 10), calendar: cal)), 28)
        XCTAssertEqual(cal.component(.day, from: BillSchedule.dueDate(day: 31, inMonthOf: date(2028, 2, 10), calendar: cal)), 29)
        XCTAssertEqual(cal.component(.day, from: BillSchedule.dueDate(day: 31, inMonthOf: date(2026, 4, 1), calendar: cal)), 30)
        XCTAssertEqual(cal.component(.day, from: BillSchedule.dueDate(day: 5, inMonthOf: date(2026, 4, 20), calendar: cal)), 5)
    }

    func testUpcomingDueDatesIncludeTodayAndCrossMonths() {
        let from = date(2026, 11, 5)
        let dates = BillSchedule.upcomingDueDates(day: 5, from: from, count: 3, calendar: cal)
        XCTAssertEqual(dates.map { cal.dateComponents([.month, .day], from: $0) }.map { "\($0.month!)/\($0.day!)" }, ["11/5", "12/5", "1/5"])

        let after = BillSchedule.upcomingDueDates(day: 5, from: date(2026, 11, 6), count: 2, calendar: cal)
        XCTAssertEqual(after.map { cal.component(.month, from: $0) }, [12, 1])
    }

    // MARK: Situação

    func testStatus() {
        let now = date(2026, 11, 5)
        XCTAssertEqual(BillMath.status(isPaid: false, dueDate: date(2026, 11, 9), now: now, calendar: cal), .upcoming)
        XCTAssertEqual(BillMath.status(isPaid: false, dueDate: date(2026, 11, 5), now: now, calendar: cal), .dueToday)
        XCTAssertEqual(BillMath.status(isPaid: false, dueDate: date(2026, 11, 2), now: now, calendar: cal), .overdue)
        XCTAssertEqual(BillMath.status(isPaid: true, dueDate: date(2026, 11, 2), now: now, calendar: cal), .paid)
        XCTAssertEqual(BillMath.daysUntil(date(2026, 11, 2), now: now, calendar: cal), -3)
    }

    func testEstimateUsesExpectedThenAverageOfLastThree() {
        XCTAssertEqual(BillMath.estimate(expected: 120, previous: [200, 300]), 120)
        XCTAssertEqual(BillMath.estimate(expected: 0, previous: [100, 200, 300, 900]), 200, accuracy: 0.001)
        XCTAssertEqual(BillMath.estimate(expected: 0, previous: []), 0)
        XCTAssertEqual(BillMath.estimate(expected: 0, previous: [0, 0]), 0)
    }

    func testChangeAgainstRecentAverage() {
        XCTAssertEqual(BillMath.change(current: 236, previous: [200, 200, 200])!, 0.18, accuracy: 0.001)
        XCTAssertNil(BillMath.change(current: 236, previous: [200]))
        XCTAssertNil(BillMath.change(current: 0, previous: [200, 200]))
    }

    // MARK: Plano do mês

    func testMonthPlanMath() {
        let plan = MonthPlan(salary: 5000, subscriptions: 300, billsPaid: 1800, billsPending: 700)
        XCTAssertEqual(plan.committed, 2800)
        XCTAssertEqual(plan.remaining, 2200)
        XCTAssertEqual(plan.committedFraction, 0.56, accuracy: 0.001)
        XCTAssertFalse(plan.isOver)
    }

    func testMonthPlanOverBudgetAndNoSalary() {
        let over = MonthPlan(salary: 2000, subscriptions: 300, billsPaid: 1800, billsPending: 700)
        XCTAssertTrue(over.isOver)
        XCTAssertEqual(over.remaining, -800)
        XCTAssertEqual(over.committedFraction, 1)

        let none = MonthPlan(salary: 0, subscriptions: 100, billsPaid: 0, billsPending: 0)
        XCTAssertFalse(none.hasSalary)
        XCTAssertFalse(none.isOver)
        XCTAssertEqual(none.committedFraction, 0)
    }
}

@MainActor
final class BillLedgerTests: XCTestCase {

    private var cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: SharedModelContainer.schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
        return ModelContext(container)
    }

    private func entries(_ context: ModelContext) -> [BillEntry] {
        (try? context.fetch(FetchDescriptor<BillEntry>())) ?? []
    }

    func testEnsureEntriesIsIdempotentAndPrefillsFixedBills() throws {
        let context = try makeContext()
        let rent = Bill(name: "Aluguel", category: .rent, dueDay: 1, isFixed: true, expectedAmount: 1800)
        let water = Bill(name: "Água", category: .water, dueDay: 5)
        context.insert(rent); context.insert(water)

        let now = date(2026, 11, 5)
        XCTAssertEqual(BillLedger.ensureEntries(for: [rent, water], in: context, now: now, calendar: cal), 2)
        XCTAssertEqual(BillLedger.ensureEntries(for: [rent, water], in: context, now: now, calendar: cal), 0)

        let all = entries(context)
        XCTAssertEqual(all.count, 2)
        XCTAssertEqual(all.first { $0.billName == "Aluguel" }?.amount, 1800)
        XCTAssertEqual(all.first { $0.billName == "Água" }?.amount, 0)
        XCTAssertFalse(all.contains { $0.isPaid })
    }

    func testInactiveBillsGetNoEntry() throws {
        let context = try makeContext()
        let old = Bill(name: "Antiga", dueDay: 3)
        old.isActive = false
        context.insert(old)
        XCTAssertEqual(BillLedger.ensureEntries(for: [old], in: context, now: date(2026, 11, 5), calendar: cal), 0)
    }

    func testRecordingTheAmountMarksItPaid() throws {
        let context = try makeContext()
        let water = Bill(name: "Água", category: .water, dueDay: 5)
        context.insert(water)
        BillLedger.ensureEntries(for: [water], in: context, now: date(2026, 11, 5), calendar: cal)
        let entry = try XCTUnwrap(entries(context).first)

        BillLedger.record(entry, amount: 182.4, paid: true, paidAt: date(2026, 11, 5), in: context)
        XCTAssertTrue(entry.isPaid)
        XCTAssertEqual(entry.amount, 182.4, accuracy: 0.001)

        BillLedger.unpay(entry, in: context)
        XCTAssertFalse(entry.isPaid)
        XCTAssertNil(entry.paidAt)
        XCTAssertEqual(entry.amount, 182.4, accuracy: 0.001)
    }

    func testSkippedMonthIsNotRecreatedAndNotCounted() throws {
        let context = try makeContext()
        let water = Bill(name: "Água", dueDay: 5)
        context.insert(water)
        let now = date(2026, 11, 20)
        BillLedger.ensureEntries(for: [water], in: context, now: now, calendar: cal)
        BillLedger.skip(try XCTUnwrap(entries(context).first), in: context)

        XCTAssertEqual(BillLedger.ensureEntries(for: [water], in: context, now: now, calendar: cal), 0)
        let plan = MonthPlan.make(salary: 3000, subscriptions: [], bills: [water], entries: entries(context), now: now, calendar: cal)
        XCTAssertEqual(plan.bills, 0)
    }

    func testRemoveDuplicatesKeepsThePaidOne() throws {
        let context = try makeContext()
        let id = UUID()
        let month = BillSchedule.monthStart(of: date(2026, 11, 5), calendar: cal)
        let unpaid = BillEntry(billID: id, billName: "Luz", categoryRaw: "electricity", monthStart: month, dueDate: date(2026, 11, 12))
        let paid = BillEntry(billID: id, billName: "Luz", categoryRaw: "electricity", monthStart: month, dueDate: date(2026, 11, 12), amount: 210, isPaid: true, paidAt: date(2026, 11, 12))
        context.insert(unpaid); context.insert(paid)

        XCTAssertEqual(BillLedger.removeDuplicates(in: context), 1)
        let left = entries(context)
        XCTAssertEqual(left.count, 1)
        XCTAssertTrue(left[0].isPaid)
    }

    func testDeletingABillKeepsPaidHistoryAndDropsPending() throws {
        let context = try makeContext()
        let bill = Bill(name: "Luz", category: .electricity, dueDay: 12)
        context.insert(bill)
        let nov = BillSchedule.monthStart(of: date(2026, 11, 5), calendar: cal)
        let oct = BillSchedule.monthStart(of: date(2026, 10, 5), calendar: cal)
        context.insert(BillEntry(billID: bill.id, billName: "Luz", categoryRaw: "electricity", monthStart: oct, dueDate: date(2026, 10, 12), amount: 190, isPaid: true, paidAt: date(2026, 10, 12)))
        context.insert(BillEntry(billID: bill.id, billName: "Luz", categoryRaw: "electricity", monthStart: nov, dueDate: date(2026, 11, 12)))

        BillLedger.delete(bill, in: context)
        let left = entries(context)
        XCTAssertEqual(left.count, 1)
        XCTAssertEqual(left[0].amount, 190)
        XCTAssertEqual((try? context.fetchCount(FetchDescriptor<Bill>())) ?? -1, 0)
    }

    func testMonthPlanCountsPaidPendingAndEstimates() throws {
        let context = try makeContext()
        let rent = Bill(name: "Aluguel", dueDay: 1, isFixed: true, expectedAmount: 1800)
        let light = Bill(name: "Luz", category: .electricity, dueDay: 12)
        context.insert(rent); context.insert(light)

        let now = date(2026, 11, 5)
        let oct = BillSchedule.monthStart(of: date(2026, 10, 5), calendar: cal)
        let sep = BillSchedule.monthStart(of: date(2026, 9, 5), calendar: cal)
        // Histórico da luz: set 200, out 220 → estimativa de novembro = 210.
        context.insert(BillEntry(billID: light.id, billName: "Luz", categoryRaw: "electricity", monthStart: sep, dueDate: date(2026, 9, 12), amount: 200, isPaid: true))
        context.insert(BillEntry(billID: light.id, billName: "Luz", categoryRaw: "electricity", monthStart: oct, dueDate: date(2026, 10, 12), amount: 220, isPaid: true))

        BillLedger.ensureEntries(for: [rent, light], in: context, now: now, calendar: cal)
        let rentEntry = try XCTUnwrap(entries(context).first { $0.billName == "Aluguel" && $0.monthStart == BillSchedule.monthStart(of: now, calendar: cal) })
        BillLedger.record(rentEntry, amount: 1800, paid: true, in: context)

        let plan = MonthPlan.make(salary: 6000, subscriptions: [], bills: [rent, light], entries: entries(context), now: now, calendar: cal)
        XCTAssertEqual(plan.billsPaid, 1800, accuracy: 0.001)
        XCTAssertEqual(plan.billsPending, 210, accuracy: 0.001)
        XCTAssertEqual(plan.remaining, 6000 - 2010, accuracy: 0.001)
    }
}
