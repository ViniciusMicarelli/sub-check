import XCTest
@testable import SubCheck

/// Garante que o teste gratuito realmente termina e não pode ser reaberto.
final class TrialPolicyTests: XCTestCase {

    private var calendar = Calendar(identifier: .gregorian)
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    private func policy(days: Int = 7) -> TrialPolicy {
        TrialPolicy(startDate: start, days: days, calendar: calendar)
    }

    private func day(_ n: Double) -> Date { start.addingTimeInterval(n * 86_400) }

    func testActiveRightAtStart() {
        XCTAssertTrue(policy().isActive(now: start))
        XCTAssertTrue(policy().hasProAccess(isPurchased: false, now: start))
    }

    func testStillActiveOnLastDay() {
        XCTAssertTrue(policy().isActive(now: day(6.99)))
    }

    func testEndsExactlyAfterSevenDays() {
        let p = policy()
        XCTAssertFalse(p.isActive(now: p.endDate))
        XCTAssertFalse(p.hasProAccess(isPurchased: false, now: p.endDate))
    }

    func testBlockedLongAfterExpiry() {
        XCTAssertFalse(policy().hasProAccess(isPurchased: false, now: day(30)))
        XCTAssertEqual(policy().daysRemaining(now: day(30)), 0)
    }

    func testPurchaseKeepsProAfterExpiry() {
        XCTAssertTrue(policy().hasProAccess(isPurchased: true, now: day(365)))
    }

    func testDaysRemainingCountsDown() {
        let p = policy()
        XCTAssertEqual(p.daysRemaining(now: start), 7)
        XCTAssertEqual(p.daysRemaining(now: day(3)), 4)
        XCTAssertEqual(p.daysRemaining(now: day(6.5)), 1)
        XCTAssertEqual(p.daysRemaining(now: day(7)), 0)
    }

    func testReinstallKeepsOldestStartDate() {
        let older = start.addingTimeInterval(-10 * 86_400)
        XCTAssertEqual(TrialPolicy.earliestStart(from: [start, older, nil]), older)
        // Sem data guardada o teste ainda não começou: nada começa sozinho.
        XCTAssertNil(TrialPolicy.earliestStart(from: [nil, nil]))
    }

    func testStateNotStartedActiveAndExpired() {
        XCTAssertEqual(TrialPolicy.state(start: nil, now: day(0)), .notStarted)
        XCTAssertEqual(TrialPolicy.state(start: start, now: day(0)), .active(daysLeft: 7))
        XCTAssertEqual(TrialPolicy.state(start: start, now: day(3)), .active(daysLeft: 4))
        XCTAssertEqual(TrialPolicy.state(start: start, now: day(7)), .expired)
    }

    func testRollingClockBackDoesNotReopenTrial() {
        let p = policy()
        let seen = day(10)                 // já viu o dia 10: teste acabou
        let rolledBack = day(2)            // usuário atrasa o relógio
        let effective = TrialPolicy.effectiveNow(rolledBack, lastSeen: seen)
        XCTAssertEqual(effective, seen)
        XCTAssertFalse(p.hasProAccess(isPurchased: false, now: effective))
    }

    func testClockMovingForwardIsUsedAsIs() {
        XCTAssertEqual(TrialPolicy.effectiveNow(day(5), lastSeen: day(2)), day(5))
        XCTAssertEqual(TrialPolicy.effectiveNow(day(5), lastSeen: nil), day(5))
    }
}
