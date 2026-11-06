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

final class SavingsProjectionTests: XCTestCase {

    func testNoInflationIsLinear() {
        let curve = SavingsProjection.curve(monthlyTotal: 100, monthlySaved: 40, years: 2, inflation: 0)
        XCTAssertEqual(curve.count, 25)
        XCTAssertEqual(curve.first?.saved, 0)
        XCTAssertEqual(curve[12].saved, 480, accuracy: 0.001)
        XCTAssertEqual(curve[24].saved, 960, accuracy: 0.001)
        XCTAssertEqual(curve[24].spentWithoutCancelling, 2400, accuracy: 0.001)
    }

    func testInflationApplesFromTheSecondYear() {
        let curve = SavingsProjection.curve(monthlyTotal: 100, monthlySaved: 100, years: 2, inflation: 0.10)
        XCTAssertEqual(curve[12].saved, 1200, accuracy: 0.001)          // 1º ano: valor atual
        XCTAssertEqual(curve[24].saved, 1200 + 1320, accuracy: 0.001)   // 2º ano: +10%
    }

    func testInvestingTheSavingsBeatsJustSaving() {
        let plain = SavingsProjection.curve(monthlyTotal: 100, monthlySaved: 50, years: 5, inflation: 0.05, yield: 0)
        let invested = SavingsProjection.curve(monthlyTotal: 100, monthlySaved: 50, years: 5, inflation: 0.05, yield: 0.10)
        XCTAssertEqual(plain.last?.saved, plain.last?.savedInvested)    // sem rendimento, igual
        XCTAssertGreaterThan(invested.last!.savedInvested, invested.last!.saved)
    }

    func testHorizonAndInputsAreClamped() {
        XCTAssertEqual(SavingsProjection.curve(monthlyTotal: 10, monthlySaved: 5, years: 99, inflation: 0).count, 121)
        XCTAssertEqual(SavingsProjection.curve(monthlyTotal: 10, monthlySaved: 5, years: 0, inflation: 0).count, 13)
        // Não economiza mais do que gasta.
        let capped = SavingsProjection.curve(monthlyTotal: 10, monthlySaved: 999, years: 1, inflation: 0)
        XCTAssertEqual(capped.last?.saved ?? 0, 120, accuracy: 0.001)
        XCTAssertTrue(SavingsProjection.curve(monthlyTotal: .nan, monthlySaved: 1, years: 1, inflation: 0).isEmpty)
    }

    func testScrubbingFindsTheNearestMonth() {
        let curve = SavingsProjection.curve(monthlyTotal: 10, monthlySaved: 10, years: 1, inflation: 0)
        XCTAssertEqual(SavingsProjection.point(atMonth: 5.4, in: curve)?.month, 5)
        XCTAssertEqual(SavingsProjection.point(atMonth: -3, in: curve)?.month, 0)
        XCTAssertEqual(SavingsProjection.point(atMonth: 500, in: curve)?.month, 12)
    }
}
