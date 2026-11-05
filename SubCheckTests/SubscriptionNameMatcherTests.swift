import XCTest
@testable import SubCheck

final class SubscriptionNameMatcherTests: XCTestCase {

    private let names = ["Netflix", "Spotify Premium", "Amazon Prime Video", "iCloud+", "Café Clube"]

    func testExactAndCaseInsensitive() {
        XCTAssertEqual(SubscriptionNameMatcher.rank("netflix", in: names), [0])
        XCTAssertEqual(SubscriptionNameMatcher.rank("NETFLIX", in: names), [0])
    }

    func testIgnoresSpokenArticles() {
        XCTAssertEqual(SubscriptionNameMatcher.rank("o spotify", in: names), [1])
    }

    func testIgnoresAccents() {
        XCTAssertEqual(SubscriptionNameMatcher.rank("cafe clube", in: names), [4])
    }

    func testMatchesAnyWordAndSubstring() {
        XCTAssertEqual(SubscriptionNameMatcher.rank("prime", in: names), [2])
        XCTAssertEqual(SubscriptionNameMatcher.rank("cloud", in: names), [3])
    }

    func testLongerSpokenNameStillFindsShorterSubscription() {
        XCTAssertEqual(SubscriptionNameMatcher.rank("netflix premium", in: names), [0])
    }

    func testBestMatchComesFirst() {
        let list = ["Prime Gaming", "Prime", "Amazon Prime"]
        XCTAssertEqual(SubscriptionNameMatcher.rank("prime", in: list), [1, 0, 2])
    }

    func testEmptyQueryReturnsEverythingAndUnknownNothing() {
        XCTAssertEqual(SubscriptionNameMatcher.rank("", in: names), Array(names.indices))
        XCTAssertTrue(SubscriptionNameMatcher.rank("hbo", in: names).isEmpty)
    }
}
