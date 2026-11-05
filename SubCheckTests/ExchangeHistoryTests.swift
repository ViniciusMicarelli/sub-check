import XCTest
@testable import SubCheck

final class ExchangeHistoryTests: XCTestCase {

    private var cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private func day(_ d: Int) -> Date {
        cal.date(from: DateComponents(year: 2026, month: 10, day: d, hour: 12))!
    }

    func testImpactDollarFalling() throws {
        // Pagou US$ 10 a R$ 5,00; hoje o dólar está R$ 4,00.
        let impact = try XCTUnwrap(ExchangeImpact(amount: 10, rateAtPayment: 5, currentRate: 4))
        XCTAssertEqual(impact.paidInBase, 50, accuracy: 0.0001)
        XCTAssertEqual(impact.currentInBase, 40, accuracy: 0.0001)
        XCTAssertEqual(impact.difference, -10, accuracy: 0.0001)
        XCTAssertEqual(impact.fraction, -0.2, accuracy: 0.0001)
    }

    func testImpactUnknownRateIsNil() {
        XCTAssertNil(ExchangeImpact(amount: 10, rateAtPayment: 0, currentRate: 4))
    }

    func testEachPaymentKeepsItsOwnRate() throws {
        var history = RateHistory()
        history.record(["USD": 1, "BRL": 5], at: day(1), calendar: cal)
        history.record(["USD": 1, "BRL": 4], at: day(2), calendar: cal)
        XCTAssertEqual(history.rate(from: "USD", to: "BRL", on: day(1), calendar: cal), 5)
        XCTAssertEqual(history.rate(from: "USD", to: "BRL", on: day(2), calendar: cal), 4)
    }

    func testSameDayReplacesSnapshot() {
        var history = RateHistory()
        history.record(["USD": 1, "BRL": 5], at: day(1), calendar: cal)
        history.record(["USD": 1, "BRL": 5.2], at: day(1), calendar: cal)
        XCTAssertEqual(history.snapshots.count, 1)
        XCTAssertEqual(history.snapshots[0].usdRates["BRL"], 5.2)
    }

    func testStaleSnapshotIsNotUsed() {
        var history = RateHistory()
        history.record(["USD": 1, "BRL": 5], at: day(1), calendar: cal)
        XCTAssertNotNil(history.usdRates(on: day(3), calendar: cal))
        XCTAssertNil(history.usdRates(on: day(20), calendar: cal))
    }

    func testNoSnapshotBeforeFirstDay() {
        var history = RateHistory()
        history.record(["USD": 1, "BRL": 5], at: day(10), calendar: cal)
        XCTAssertNil(history.usdRates(on: day(5), calendar: cal))
    }

    func testCrossRateAndSeries() {
        var history = RateHistory()
        history.record(["USD": 1, "BRL": 5, "EUR": 0.9], at: day(1), calendar: cal)
        history.record(["USD": 1, "BRL": 4, "EUR": 0.8], at: day(2), calendar: cal)
        let series = history.series(from: "EUR", to: "BRL")
        XCTAssertEqual(series.count, 2)
        XCTAssertEqual(series[0].rate, 5 / 0.9, accuracy: 0.0001)
        XCTAssertEqual(series[1].rate, 5, accuracy: 0.0001)
    }

    func testHistoryIsCapped() {
        var history = RateHistory()
        let start = day(1)
        for i in 0..<(RateHistory.maxSnapshots + 10) {
            let date = cal.date(byAdding: .day, value: i, to: start)!
            history.record(["USD": 1, "BRL": 5], at: date, calendar: cal)
        }
        XCTAssertEqual(history.snapshots.count, RateHistory.maxSnapshots)
    }
}
