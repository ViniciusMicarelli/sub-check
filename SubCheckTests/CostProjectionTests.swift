import XCTest
@testable import SubCheck

final class CostProjectionTests: XCTestCase {

    func testNoIncreaseIsLinear() {
        XCTAssertEqual(CostProjection.total(monthly: 100, years: 5, annualRate: 0), 6_000, accuracy: 0.001)
    }

    func testFirstYearHasNoIncrease() {
        XCTAssertEqual(CostProjection.total(monthly: 100, years: 1, annualRate: 0.2), 1_200, accuracy: 0.001)
    }

    func testCustomRateCompoundsYearly() {
        // 1200 + 1200*1.1 + 1200*1.21
        XCTAssertEqual(CostProjection.total(monthly: 100, years: 3, annualRate: 0.10), 3_972, accuracy: 0.001)
    }

    func testHigherRateCostsMore() {
        let low = CostProjection.total(monthly: 50, years: 10, annualRate: 0.04)
        let high = CostProjection.total(monthly: 50, years: 10, annualRate: 0.12)
        XCTAssertGreaterThan(high, low)
    }

    func testRateIsClampedAndSafe() {
        XCTAssertEqual(CostProjection.clamp(-1), 0)
        XCTAssertEqual(CostProjection.clamp(9), 0.5)
        XCTAssertEqual(CostProjection.clamp(.nan), 0)
        XCTAssertEqual(CostProjection.total(monthly: 100, years: 0, annualRate: 0.1), 0)
    }
}

final class DonutSelectionTests: XCTestCase {

    private let breakdown = [
        CategoryTotal(category: .entertainment, total: 100, count: 3),
        CategoryTotal(category: .productivity, total: 50, count: 2),
        CategoryTotal(category: .health, total: 50, count: 1)
    ]

    func testAngleValueMapsToTheSliceUnderTheTap() {
        XCTAssertEqual(DonutSelection.category(atAngleValue: 10, in: breakdown), .entertainment)
        XCTAssertEqual(DonutSelection.category(atAngleValue: 100, in: breakdown), .entertainment) // borda
        XCTAssertEqual(DonutSelection.category(atAngleValue: 120, in: breakdown), .productivity)
        XCTAssertEqual(DonutSelection.category(atAngleValue: 199, in: breakdown), .health)
    }

    func testBeyondTheEndFallsOnTheLastSliceAndNegativeIsNil() {
        XCTAssertEqual(DonutSelection.category(atAngleValue: 9_999, in: breakdown), .health)
        XCTAssertNil(DonutSelection.category(atAngleValue: -1, in: breakdown))
        XCTAssertNil(DonutSelection.category(atAngleValue: 1, in: []))
    }
}
