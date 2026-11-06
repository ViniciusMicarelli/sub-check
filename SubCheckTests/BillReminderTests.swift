import SwiftData
import XCTest
@testable import SubCheck

final class BillReminderPlannerTests: XCTestCase {

    private var cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private func date(_ m: Int, _ d: Int, _ h: Int = 12) -> Date {
        cal.date(from: DateComponents(year: 2026, month: m, day: d, hour: h))!
    }

    private func kinds(_ plan: [PlannedBillReminder]) -> [PlannedBillReminder.Kind] { plan.map(\.kind) }

    /// O caso que falhou: conta de água para amanhã, lembrete "1 dia antes",
    /// cadastrada à tarde (o aviso das 9h de hoje já passou).
    func testBillDueTomorrowCreatedInTheAfternoonStillGetsNotified() {
        let plan = BillReminderPlanner.plan(
            dueDate: date(11, 7), advanceDays: 1, needsAmount: true, now: date(11, 6, 14), calendar: cal
        )
        XCTAssertEqual(kinds(plan), [.dueDay, .evening, .overdue])
        XCTAssertEqual(cal.component(.hour, from: plan[0].fireDate), 9)
        XCTAssertEqual(cal.component(.day, from: plan[0].fireDate), 7)
        XCTAssertEqual(cal.component(.hour, from: plan[1].fireDate), 19)
    }

    func testAdvanceReminderComesFirstWhenStillInTheFuture() {
        let plan = BillReminderPlanner.plan(
            dueDate: date(11, 5), advanceDays: 2, needsAmount: true, now: date(11, 1, 8), calendar: cal
        )
        XCTAssertEqual(kinds(plan), [.advance, .dueDay, .evening, .overdue])
        XCTAssertEqual(cal.component(.day, from: plan[0].fireDate), 3)
    }

    func testFixedAmountBillsSkipTheEveningNudge() {
        let plan = BillReminderPlanner.plan(
            dueDate: date(11, 7), advanceDays: 0, needsAmount: false, now: date(11, 6, 14), calendar: cal
        )
        XCTAssertEqual(kinds(plan), [.dueDay, .overdue])
    }

    func testBillDueTodayAfterNineStillHasTheEveningAndOverdueReminders() {
        let plan = BillReminderPlanner.plan(
            dueDate: date(11, 6), advanceDays: 1, needsAmount: true, now: date(11, 6, 10), calendar: cal
        )
        XCTAssertEqual(kinds(plan), [.evening, .overdue])
    }

    func testNothingIsPlannedInThePast() {
        let plan = BillReminderPlanner.plan(
            dueDate: date(11, 1), advanceDays: 1, needsAmount: true, now: date(11, 20), calendar: cal
        )
        XCTAssertTrue(plan.isEmpty)
    }

    func testPlanIsSortedByFireDate() {
        let plan = BillReminderPlanner.plan(
            dueDate: date(11, 20), advanceDays: 3, needsAmount: true, now: date(11, 1), calendar: cal
        )
        XCTAssertEqual(plan.map(\.fireDate), plan.map(\.fireDate).sorted())
    }
}

final class BillPromptTests: XCTestCase {

    private var cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private func date(_ m: Int, _ d: Int) -> Date {
        cal.date(from: DateComponents(year: 2026, month: m, day: d, hour: 12))!
    }

    func testPromptOnlyWhenSomethingIsDueAndNotSnoozedToday() {
        let today = date(11, 6)
        XCTAssertFalse(BillPrompt.shouldShow(dueCount: 0, snoozedDay: 0, now: today, calendar: cal))
        XCTAssertTrue(BillPrompt.shouldShow(dueCount: 2, snoozedDay: 0, now: today, calendar: cal))
        XCTAssertFalse(BillPrompt.shouldShow(dueCount: 2, snoozedDay: BillPrompt.dayNumber(today, calendar: cal), now: today, calendar: cal))
        // Adiou ontem: hoje volta a aparecer.
        XCTAssertTrue(BillPrompt.shouldShow(dueCount: 2, snoozedDay: BillPrompt.dayNumber(date(11, 5), calendar: cal), now: today, calendar: cal))
    }

    func testDueEntriesAreUnpaidAndAlreadyDue() {
        let now = date(11, 6)
        func entry(_ month: Int, due: Int, paid: Bool = false, skipped: Bool = false) -> BillEntry {
            let e = BillEntry(billID: UUID(), billName: "x", categoryRaw: "water",
                              monthStart: BillSchedule.monthStart(of: date(month, 1), calendar: cal),
                              dueDate: date(month, due), isPaid: paid)
            e.isSkipped = skipped
            return e
        }
        let list = [
            entry(11, due: 6),                    // vence hoje -> entra
            entry(11, due: 2),                    // atrasada -> entra
            entry(11, due: 9),                    // futura -> fora
            entry(11, due: 3, paid: true),        // paga -> fora
            entry(11, due: 1, skipped: true),     // pulada -> fora
            entry(10, due: 28),                   // mês passado em aberto -> entra
            entry(8, due: 5)                      // muito antiga -> fora
        ]
        let due = BillPlanning.dueEntries(list, now: now, calendar: cal)
        XCTAssertEqual(due.count, 3)
        XCTAssertEqual(due.map { cal.component(.day, from: $0.dueDate) }, [28, 2, 6])
    }
}

@MainActor
final class LiveActivityBillsTests: XCTestCase {

    private func charge(_ name: String, in days: Double, kind: String?) -> SubCheckActivityAttributes.UpcomingCharge {
        .init(id: UUID().uuidString, name: name, amount: 100, dueDate: Date().addingTimeInterval(days * 86_400),
              category: "water", kind: kind)
    }

    func testABillDueSoonBecomesTheNextItemEvenWithoutSubscriptions() throws {
        let state = try XCTUnwrap(LiveActivityService.state(from: [], bills: [charge("Água", in: 1, kind: "bill")]))
        XCTAssertEqual(state.nextName, "Água")
        XCTAssertEqual(state.nextKind, "bill")
    }

    func testTheSoonestItemWinsBetweenSubscriptionsAndBills() throws {
        let netflix = Subscription(name: "Netflix", cost: 55.9, startDate: Date().addingTimeInterval(-86_400 * 20))
        let soonBill = try XCTUnwrap(LiveActivityService.state(from: [netflix], bills: [charge("Água", in: 0.1, kind: "bill")]))
        XCTAssertEqual(soonBill.nextKind, "bill")

        let farBill = try XCTUnwrap(LiveActivityService.state(from: [netflix], bills: [charge("Luz", in: 60, kind: "bill")]))
        XCTAssertNil(farBill.nextKind)
        XCTAssertEqual(farBill.nextName, "Netflix")
    }

    func testNothingToShowReturnsNil() {
        XCTAssertNil(LiveActivityService.state(from: [], bills: []))
    }
}
