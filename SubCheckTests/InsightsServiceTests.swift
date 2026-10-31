import XCTest
@testable import SubCheck

@MainActor
final class InsightsServiceTests: XCTestCase {

    private func sub(
        _ name: String,
        cost: Double,
        frequency: RecurrenceFrequency = .monthly,
        category: CategoryType = .entertainment,
        cancelled: Bool = false
    ) -> Subscription {
        Subscription(
            name: name, cost: cost, currencyCode: CurrencyService.shared.baseCode,
            startDate: Date(), frequency: frequency, category: category.rawValue,
            isCancelled: cancelled
        )
    }

    private func ids(_ subs: [Subscription]) -> Set<String> {
        Set(InsightsService.insights(for: subs).map(\.id))
    }

    func testEmptyHasNoInsights() {
        XCTAssertTrue(InsightsService.insights(for: []).isEmpty)
    }

    func testOverlapDetectedForSameCategory() {
        let subs = [sub("A", cost: 20), sub("B", cost: 20)]
        XCTAssertTrue(ids(subs).contains("overlap"))
    }

    func testConcentrationWhenOneServiceDominates() {
        let subs = [sub("Big", cost: 100, category: .utilities), sub("Small", cost: 10, category: .health)]
        XCTAssertTrue(ids(subs).contains("concentration"))
    }

    func testCancelledProducesSavingsOnly() {
        let subs = [sub("Old", cost: 30, cancelled: true)]
        let result = ids(subs)
        XCTAssertTrue(result.contains("saved"))
        XCTAssertFalse(result.contains("daily"))
    }

    func testUpcomingTotalIgnoresCancelled() {
        let subs = [sub("Gone", cost: 50, cancelled: true)]
        XCTAssertEqual(InsightsService.upcomingTotal(subs, days: 30), 0)
    }

    func testWeeklyChargeRepeatsWithinMonth() {
        let weekly = sub("Weekly", cost: 10, frequency: .weekly)
        // Início hoje: ao menos 4 ocorrências em 30 dias.
        XCTAssertGreaterThanOrEqual(InsightsService.upcomingTotal([weekly], days: 30), 40)
    }
}

final class SubscriptionBillingTests: XCTestCase {

    func testNextBillingIsInFuture() {
        let past = Calendar.current.date(byAdding: .month, value: -5, to: Date())!
        let s = Subscription(name: "X", cost: 10, startDate: past)
        XCTAssertGreaterThan(s.nextBillingDate, Date())
    }

    func testYearlyCostIsMonthlyTimesTwelve() {
        let s = Subscription(name: "Y", cost: 120, frequency: .yearly)
        XCTAssertEqual(s.monthlyCost, 10, accuracy: 0.001)
        XCTAssertEqual(s.yearlyCost, 120, accuracy: 0.001)
    }
}

final class TrialAndPriceTests: XCTestCase {

    func testTrialDaysLeftCountsCalendarDays() {
        let end = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        let s = Subscription(name: "T", cost: 10, trialEndsAt: end)
        XCTAssertEqual(s.trialDaysLeft, 3)
    }

    func testExpiredOrCancelledTrialHasNoDaysLeft() {
        let past = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        XCTAssertNil(Subscription(name: "T", cost: 10, trialEndsAt: past).trialDaysLeft)

        let future = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        XCTAssertNil(Subscription(name: "T", cost: 10, isCancelled: true, trialEndsAt: future).trialDaysLeft)
    }

    func testPriceChangeRecordedFromBaseline() {
        let s = Subscription(name: "P", cost: 20)
        s.recordPriceChange(from: 10)
        XCTAssertEqual(s.previousCost, 10)
        XCTAssertEqual(s.priceChange ?? 0, 1.0, accuracy: 0.001)
    }

    func testNoPriceChangeWhenUnchanged() {
        let s = Subscription(name: "P", cost: 10)
        s.recordPriceChange(from: 10)
        XCTAssertNil(s.priceChange)
    }
}
