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
        let first = LiveActivityService.shared.start(with: sample(), bills: [])
        XCTAssertEqual(first, .started)
        let second = LiveActivityService.shared.start(with: sample(), bills: [])
        XCTAssertEqual(second, .updated)
        XCTAssertEqual(Activity<SubCheckActivityAttributes>.activities.count, 1)
    }

    func testEmptyListEndsRunningActivity() async throws {
        guard LiveActivityService.shared.areActivitiesEnabled else {
            throw XCTSkip("Live Activities desligadas neste ambiente")
        }
        _ = LiveActivityService.shared.start(with: sample(), bills: [])
        XCTAssertEqual(Activity<SubCheckActivityAttributes>.activities.count, 1)

        let result = LiveActivityService.shared.start(with: [], bills: [])
        XCTAssertEqual(result, .noSubscriptions)
        try await Task.sleep(for: .milliseconds(500))
        XCTAssertEqual(Activity<SubCheckActivityAttributes>.activities.count, 0)
    }
}
