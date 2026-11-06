import SwiftData
import XCTest
@testable import SubCheck

final class ProAccessSnapshotTests: XCTestCase {

    private let day: TimeInterval = 86_400
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    func testFreshInstallHasNoProUntilTheTrialIsActivated() {
        // O Pro não liga sozinho: a pessoa precisa escolher ativar o teste.
        XCTAssertFalse(ProAccessSnapshot.hasAccess(purchased: false, trialStart: [nil, nil], lastSeen: nil, now: now))
    }

    func testActivatingTheTrialGivesAccessForSevenDays() {
        XCTAssertTrue(ProAccessSnapshot.hasAccess(purchased: false, trialStart: [now], lastSeen: now, now: now))
        let later = now.addingTimeInterval(6 * day)
        XCTAssertTrue(ProAccessSnapshot.hasAccess(purchased: false, trialStart: [now], lastSeen: later, now: later))
        let after = now.addingTimeInterval(8 * day)
        XCTAssertFalse(ProAccessSnapshot.hasAccess(purchased: false, trialStart: [now], lastSeen: after, now: after))
    }

    func testPurchaseWorksWithoutEverStartingTheTrial() {
        XCTAssertTrue(ProAccessSnapshot.hasAccess(purchased: true, trialStart: [nil], lastSeen: nil, now: now))
    }

    func testExpiredTrialWithoutPurchaseHasNoAccess() {
        let start = now.addingTimeInterval(-10 * day)
        XCTAssertFalse(ProAccessSnapshot.hasAccess(purchased: false, trialStart: [start], lastSeen: now, now: now))
    }

    func testPurchaseKeepsAccessAfterTrial() {
        let start = now.addingTimeInterval(-30 * day)
        XCTAssertTrue(ProAccessSnapshot.hasAccess(purchased: true, trialStart: [start], lastSeen: now, now: now))
    }

    func testRollingTheClockBackDoesNotReopenTheTrial() {
        let start = now.addingTimeInterval(-10 * day)
        // O aparelho já viu "hoje"; atrasar o relógio 9 dias não devolve o Pro.
        let tampered = now.addingTimeInterval(-9 * day)
        XCTAssertFalse(ProAccessSnapshot.hasAccess(purchased: false, trialStart: [start], lastSeen: now, now: tampered))
    }
}

@MainActor
final class SaveReporterTests: XCTestCase {

    func testSuccessfulSaveReportsNothing() throws {
        SaveReporter.shared.failure = nil
        let container = try ModelContainer(
            for: SharedModelContainer.schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
        let context = ModelContext(container)
        context.insert(Subscription(name: "Teste", cost: 10))
        XCTAssertTrue(context.saveReporting())
        XCTAssertNil(SaveReporter.shared.failure)
    }
}
