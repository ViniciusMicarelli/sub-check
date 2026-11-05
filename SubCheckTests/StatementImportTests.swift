import XCTest
@testable import SubCheck

final class StatementImportTests: XCTestCase {

    private var cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    // MARK: Números e datas

    func testParsesBrazilianAndUSNumbers() {
        XCTAssertEqual(StatementParser.parseNumber("1.234,56"), 1234.56)
        XCTAssertEqual(StatementParser.parseNumber("1,234.56"), 1234.56)
        XCTAssertEqual(StatementParser.parseNumber("-39,90"), -39.90)
        XCTAssertEqual(StatementParser.parseNumber("R$ 39,90"), 39.90)
        XCTAssertEqual(StatementParser.parseNumber("(39,90)"), -39.90)
        XCTAssertEqual(StatementParser.parseNumber("39.90"), 39.90)
        XCTAssertNil(StatementParser.parseNumber("abc"))
    }

    func testParsesDates() {
        let d1 = StatementParser.parseDate("05/10/2026", calendar: cal)
        XCTAssertEqual(cal.component(.day, from: d1!), 5)
        XCTAssertEqual(cal.component(.month, from: d1!), 10)
        let d2 = StatementParser.parseDate("2026-10-05 08:30:00", calendar: cal)
        XCTAssertEqual(cal.component(.day, from: d2!), 5)
        XCTAssertNil(StatementParser.parseDate("Netflix", calendar: cal))
    }

    // MARK: CSV de formatos diferentes

    func testNubankCardFormatPositiveSpend() {
        let csv = """
        date,category,title,amount
        2026-08-05,serviços,Netflix.Com,55.90
        2026-09-05,serviços,Netflix.Com,55.90
        2026-10-05,serviços,Netflix.Com,55.90
        2026-10-07,restaurante,Padaria do Zé,23.50
        2026-10-09,pagamento,Pagamento recebido,-500.00
        """
        let txs = StatementParser.parse(csv, calendar: cal)
        XCTAssertEqual(txs.count, 4)
        XCTAssertTrue(txs.allSatisfy { $0.amount > 0 })
    }

    func testBankAccountSemicolonNegativeSpend() {
        let csv = "Data;Descrição;Valor\n05/08/2026;\"SPOTIFY BR\";-21,90\n05/09/2026;SPOTIFY BR;-21,90\n05/10/2026;SPOTIFY BR;-21,90\n01/10/2026;SALARIO EMPRESA;5.000,00\n"
        let txs = StatementParser.parse(csv, calendar: cal)
        XCTAssertEqual(txs.count, 3)
        XCTAssertEqual(txs[0].amount, 21.90, accuracy: 0.001)
    }

    func testNoHeaderIsInferred() {
        let csv = "05/08/2026;NETFLIX;55,90\n05/09/2026;NETFLIX;55,90\n"
        XCTAssertEqual(StatementParser.parse(csv, calendar: cal).count, 2)
    }

    func testGarbageReturnsEmpty() {
        XCTAssertTrue(StatementParser.parse("", calendar: cal).isEmpty)
        XCTAssertTrue(StatementParser.parse("foo,bar\n1,2\n", calendar: cal).isEmpty)
    }

    // MARK: Detecção

    private func tx(_ y: Int, _ m: Int, _ d: Int, _ text: String, _ amount: Double) -> StatementTransaction {
        StatementTransaction(date: cal.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!,
                             description: text, amount: amount)
    }

    private var now: Date { cal.date(from: DateComponents(year: 2026, month: 10, day: 20))! }

    func testMonthlySubscriptionDetectedDespiteNoiseInName() {
        let list = [
            tx(2026, 8, 5, "NETFLIX.COM 12345", 55.90),
            tx(2026, 9, 5, "Compra Netflix.Com SP", 55.90),
            tx(2026, 10, 5, "NETFLIX.COM 99871", 55.90)
        ]
        let found = RecurrenceDetector.detect(list, now: now, calendar: cal)
        XCTAssertEqual(found.count, 1)
        guard let netflix = found.first else { return }
        XCTAssertEqual(netflix.name, "Netflix")
        XCTAssertEqual(netflix.frequency, .monthly)
        XCTAssertEqual(netflix.confidence, .high)
        XCTAssertTrue(netflix.isLikelyActive)
    }

    func testVariableAmountsAreNotSubscriptions() {
        let list = [
            tx(2026, 8, 5, "Padaria Central", 12.0),
            tx(2026, 9, 6, "Padaria Central", 48.0),
            tx(2026, 10, 7, "Padaria Central", 25.0)
        ]
        XCTAssertTrue(RecurrenceDetector.detect(list, now: now, calendar: cal).isEmpty)
    }

    func testIrregularIntervalsAreIgnored() {
        let list = [
            tx(2026, 8, 5, "Posto Shell", 200),
            tx(2026, 8, 14, "Posto Shell", 200),
            tx(2026, 10, 1, "Posto Shell", 200)
        ]
        XCTAssertTrue(RecurrenceDetector.detect(list, now: now, calendar: cal).isEmpty)
    }

    func testTwoChargesNeedIdenticalAmount() {
        let same = [tx(2026, 9, 5, "Spotify", 21.9), tx(2026, 10, 5, "Spotify", 21.9)]
        XCTAssertEqual(RecurrenceDetector.detect(same, now: now, calendar: cal).count, 1)
        let different = [tx(2026, 9, 5, "Loja X", 21.9), tx(2026, 10, 5, "Loja X", 25.0)]
        XCTAssertTrue(RecurrenceDetector.detect(different, now: now, calendar: cal).isEmpty)
    }

    func testOldSubscriptionIsMarkedInactive() {
        let list = [
            tx(2026, 3, 5, "Deezer", 21.9),
            tx(2026, 4, 5, "Deezer", 21.9),
            tx(2026, 5, 5, "Deezer", 21.9)
        ]
        let found = RecurrenceDetector.detect(list, now: now, calendar: cal)
        XCTAssertEqual(found.count, 1)
        XCTAssertEqual(found.first?.isLikelyActive, false)
    }

    func testYearlyAndWeekly() {
        XCTAssertEqual(RecurrenceDetector.frequency(for: [365, 366]), .yearly)
        XCTAssertEqual(RecurrenceDetector.frequency(for: [7, 7, 7]), .weekly)
        XCTAssertNil(RecurrenceDetector.frequency(for: [10, 45]))
    }

    func testUmbrellaBrandsStaySeparate() {
        let list = [
            tx(2026, 8, 5, "Google One", 9.99), tx(2026, 9, 5, "Google One", 9.99), tx(2026, 10, 5, "Google One", 9.99),
            tx(2026, 8, 9, "Google Play Jogo", 30), tx(2026, 9, 20, "Google Play Jogo", 4)
        ]
        let found = RecurrenceDetector.detect(list, now: now, calendar: cal)
        XCTAssertEqual(found.map(\.name), ["Google One"])
    }

    func testDuplicateSameDayCountsOnce() {
        let list = [tx(2026, 10, 5, "Spotify", 21.9), tx(2026, 10, 5, "Spotify", 21.9)]
        XCTAssertTrue(RecurrenceDetector.detect(list, now: now, calendar: cal).isEmpty)
    }
}
