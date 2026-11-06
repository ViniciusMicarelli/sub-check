import XCTest
@testable import SubCheck

final class CurrencyMaskTests: XCTestCase {

    private let pt = Locale(identifier: "pt_BR")
    private let en = Locale(identifier: "en_US")

    func testTypingDigitsBuildsCentsFromTheRight() {
        XCTAssertEqual(CurrencyMask.display(digits: "1", locale: pt), "0,01")
        XCTAssertEqual(CurrencyMask.display(digits: "12", locale: pt), "0,12")
        XCTAssertEqual(CurrencyMask.display(digits: "12345", locale: pt), "123,45")
        XCTAssertEqual(CurrencyMask.display(digits: "12345", locale: en), "123.45")
    }

    func testThousandsAreGrouped() {
        XCTAssertEqual(CurrencyMask.display(digits: "123456789", locale: pt), "1.234.567,89")
    }

    func testDigitsIgnoreLettersSeparatorsAndLeadingZeros() {
        XCTAssertEqual(CurrencyMask.digits(from: "R$ 0012,34"), "1234")
        XCTAssertEqual(CurrencyMask.digits(from: "abc"), "")
        XCTAssertEqual(CurrencyMask.digits(from: "0,00"), "")
    }

    func testDeletingTheLastCharacterRemovesOneDigit() {
        // "12,34" → o usuário apaga e o texto vira "12,3"
        XCTAssertEqual(CurrencyMask.digits(from: "12,3"), "123")
        XCTAssertEqual(CurrencyMask.value(fromDigits: "123"), 1.23, accuracy: 0.0001)
    }

    func testRoundTripAndEmpty() {
        XCTAssertEqual(CurrencyMask.digits(from: 123.45), "12345")
        XCTAssertEqual(CurrencyMask.digits(from: 0), "")
        XCTAssertEqual(CurrencyMask.display(digits: ""), "")
        XCTAssertEqual(CurrencyMask.value(fromDigits: ""), 0)
    }

    func testDigitCountIsCapped() {
        XCTAssertEqual(CurrencyMask.digits(from: String(repeating: "9", count: 30)).count, CurrencyMask.maxDigits)
    }
}
