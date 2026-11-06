import ActivityKit
import XCTest
@testable import SubCheck

final class LiveActivityLifecycleTests: XCTestCase {

    func testFreshActivityIsNotRecycled() {
        let now = Date()
        XCTAssertFalse(LiveActivityLifecycle.shouldRecycle(startedAt: now.addingTimeInterval(-60), now: now))
    }

    func testOldActivityIsRecycledBeforeSystemLimit() {
        let now = Date()
        // O iOS derruba aos 8h; reciclamos bem antes disso.
        XCTAssertTrue(LiveActivityLifecycle.shouldRecycle(startedAt: now.addingTimeInterval(-5 * 3600), now: now))
        XCTAssertLessThan(LiveActivityLifecycle.recycleAfter, 8 * 3600)
    }

    func testStaleDateOnlyForFutureDueDates() {
        let now = Date()
        let future = now.addingTimeInterval(3600)
        XCTAssertEqual(LiveActivityLifecycle.staleDate(forDue: future, now: now), future)
        XCTAssertNil(LiveActivityLifecycle.staleDate(forDue: now.addingTimeInterval(-10), now: now))
    }
}

/// Roda de verdade no simulador (o app é o host dos testes).
@MainActor
final class LiveActivityServiceTests: XCTestCase {

    private func sample() -> [Subscription] {
        [Subscription(name: "Netflix", cost: 55.9, startDate: Date().addingTimeInterval(-86_400 * 20))]
    }

    override func tearDown() async throws {
        for activity in Activity<SubCheckActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    func testStartsOnceAndUpdatesInsteadOfDuplicating() async throws {
        guard LiveActivityService.shared.areActivitiesEnabled else {
            throw XCTSkip("Live Activities desligadas neste ambiente")
        }
        let first = LiveActivityService.shared.start(with: sample(), bills: [], ignoringPolicy: true)
        XCTAssertEqual(first, .started)
        let second = LiveActivityService.shared.start(with: sample(), bills: [], ignoringPolicy: true)
        XCTAssertEqual(second, .updated)
        XCTAssertEqual(Activity<SubCheckActivityAttributes>.activities.count, 1)
    }

    func testEmptyListEndsRunningActivity() async throws {
        guard LiveActivityService.shared.areActivitiesEnabled else {
            throw XCTSkip("Live Activities desligadas neste ambiente")
        }
        _ = LiveActivityService.shared.start(with: sample(), bills: [], ignoringPolicy: true)
        XCTAssertEqual(Activity<SubCheckActivityAttributes>.activities.count, 1)

        let result = LiveActivityService.shared.start(with: [], bills: [], ignoringPolicy: true)
        XCTAssertEqual(result, .noSubscriptions)
        try await Task.sleep(for: .milliseconds(500))
        XCTAssertEqual(Activity<SubCheckActivityAttributes>.activities.count, 0)
    }

    // MARK: Regras novas: só com Pro e só quando vence em breve

    func testFreeUserNeverGetsTheIsland() async throws {
        guard LiveActivityService.shared.areActivitiesEnabled else {
            throw XCTSkip("Live Activities desligadas neste ambiente")
        }
        // Sem compra nem teste ativado, a política barra a atividade.
        guard !ProAccessSnapshot.current() else { throw XCTSkip("Este aparelho de teste tem Pro") }
        let result = LiveActivityService.shared.start(with: sample(), bills: [])
        XCTAssertEqual(result, .requiresPro)
        XCTAssertEqual(Activity<SubCheckActivityAttributes>.activities.count, 0)
    }

    func testShouldRunNeedsProSwitchAndSystemPermission() {
        XCTAssertTrue(LiveActivityLifecycle.shouldRun(hasPro: true, enabled: true, systemAllows: true))
        XCTAssertFalse(LiveActivityLifecycle.shouldRun(hasPro: false, enabled: true, systemAllows: true))
        XCTAssertFalse(LiveActivityLifecycle.shouldRun(hasPro: true, enabled: false, systemAllows: true))
        XCTAssertFalse(LiveActivityLifecycle.shouldRun(hasPro: true, enabled: true, systemAllows: false))
    }

    func testWindowOnlyCoversChargesDueSoon() {
        let cal = Calendar(identifier: .gregorian)
        let now = cal.date(from: DateComponents(year: 2026, month: 11, day: 6, hour: 10))!
        func day(_ d: Int) -> Date { cal.date(from: DateComponents(year: 2026, month: 11, day: d, hour: 8))! }
        XCTAssertTrue(LiveActivityLifecycle.isWithinWindow(due: day(6), now: now, calendar: cal))   // hoje
        XCTAssertTrue(LiveActivityLifecycle.isWithinWindow(due: day(9), now: now, calendar: cal))   // 3 dias
        XCTAssertFalse(LiveActivityLifecycle.isWithinWindow(due: day(10), now: now, calendar: cal)) // 4 dias
        XCTAssertTrue(LiveActivityLifecycle.isWithinWindow(due: day(4), now: now, calendar: cal))   // atrasada
    }

    func testFarAwayChargeProducesNoState() {
        let now = Date()
        let far = Subscription(name: "Netflix", cost: 55.9, startDate: now.addingTimeInterval(-86_400 * 20))
        // Próxima cobrança a ~10 dias: fora da janela de 3 dias.
        XCTAssertNil(LiveActivityService.state(from: [far], bills: [], windowDays: 3, now: now))
        XCTAssertNotNil(LiveActivityService.state(from: [far], bills: [], windowDays: nil, now: now))
    }

    func testStateCarriesTheSubscriptionIcon() throws {
        let sub = Subscription(name: "Netflix", cost: 55.9, startDate: Date().addingTimeInterval(-86_400 * 20))
        let state = try XCTUnwrap(LiveActivityService.state(from: [sub], bills: []))
        XCTAssertEqual(state.nextIcon, sub.resolvedIcon.rawValue)
        XCTAssertEqual(state.upcoming.first?.icon, sub.resolvedIcon.rawValue)
    }
}
