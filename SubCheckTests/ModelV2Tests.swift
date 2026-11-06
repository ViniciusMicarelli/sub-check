import SwiftData
import XCTest
@testable import SubCheck

@MainActor
final class ModelV2Tests: XCTestCase {

    private func service() -> CurrencyService {
        CurrencyService(defaults: UserDefaults(suiteName: "test-\(UUID().uuidString)")!)
    }

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: SharedModelContainer.schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
        return ModelContext(container)
    }

    // MARK: Compartilhada

    func testSharedSubscriptionCountsOnlyMyShareInTotals() {
        let svc = service()
        let sub = Subscription(name: "Spotify Family", cost: 40, currencyCode: svc.baseCode)
        XCTAssertEqual(sub.monthlyCost(in: svc), 40, accuracy: 0.001)

        sub.sharedPeople = 4
        XCTAssertEqual(sub.monthlyCost(in: svc), 10, accuracy: 0.001)       // minha parte
        XCTAssertEqual(sub.fullMonthlyCost(in: svc), 40, accuracy: 0.001)   // preço cheio
        XCTAssertEqual(sub.yearlyCost(in: svc), 120, accuracy: 0.001)
        XCTAssertTrue(sub.isShared)
    }

    func testSplitCountNeverDropsBelowOne() {
        let sub = Subscription(name: "X", cost: 10)
        sub.sharedPeople = 0
        XCTAssertEqual(sub.splitCount, 1)
        XCTAssertEqual(sub.shareFactor, 1)
    }

    // MARK: Pacotes

    func testServiceIncludedInBundleIsNotCountedTwice() {
        let svc = service()
        let appleOne = Subscription(name: "Apple One", cost: 60, currencyCode: svc.baseCode)
        let icloud = Subscription(name: "iCloud+", cost: 15, currencyCode: svc.baseCode)
        icloud.bundleParentID = appleOne.id

        XCTAssertTrue(icloud.isIncludedInBundle)
        XCTAssertEqual(icloud.monthlyCost(in: svc), 0)
        XCTAssertEqual([appleOne, icloud].monthlyTotal(in: svc), 60, accuracy: 0.001)
    }

    func testBundleChildCreatesNoHistoryRecords() throws {
        let context = try makeContext()
        let parent = Subscription(name: "Apple One", cost: 60, startDate: Date().addingTimeInterval(-86_400 * 40))
        let child = Subscription(name: "iCloud+", cost: 15, startDate: Date().addingTimeInterval(-86_400 * 40))
        child.bundleParentID = parent.id
        context.insert(parent); context.insert(child)

        PaymentLedger.reconcile([parent, child], in: context)
        let records = try context.fetch(FetchDescriptor<PaymentRecord>())
        XCTAssertFalse(records.isEmpty)
        XCTAssertTrue(records.allSatisfy { $0.subscriptionID == parent.id })
        XCTAssertNotNil(child.lastPaymentDate) // o ciclo andou
    }

    func testRecordRemembersMyShare() {
        let sub = Subscription(name: "Netflix", cost: 60)
        sub.sharedPeople = 3
        let record = PaymentRecord(from: sub, paidAt: Date(), isEstimated: false)
        XCTAssertEqual(record.amount, 60)
        XCTAssertEqual(record.myAmount, 20, accuracy: 0.001)
    }

    // MARK: Cobrança por uso

    func testVariableKindRoundTrips() {
        let sub = Subscription(name: "OpenAI API", cost: 20)
        XCTAssertEqual(sub.billingKind, .fixed)
        sub.billingKind = .variable
        XCTAssertTrue(sub.isVariable)
        XCTAssertEqual(sub.billingKindRaw, "variable")
        sub.billingKindRaw = "lixo"
        XCTAssertEqual(sub.billingKind, .fixed)
    }

    // MARK: Pagamento avulso e cotação

    func testApproximateBaseValueWinsAndNeedsNoInternet() {
        let svc = service()
        let p = OneOffPayment(name: "Trae", amount: 8, currencyCode: "USD")
        p.setApproximateBase(40, base: svc.baseCode)
        XCTAssertEqual(p.baseAmount(in: svc), 40, accuracy: 0.001)
        XCTAssertTrue(p.rateIsManual)
        XCTAssertEqual(p.rateToBase, 5, accuracy: 0.001)
    }

    func testManualRateIsUsedAndNotOverwrittenByStamp() {
        let svc = service()
        let p = OneOffPayment(name: "Trae", amount: 8, currencyCode: "USD")
        p.setManualRate(5.5, base: svc.baseCode)
        XCTAssertEqual(p.baseAmount(in: svc), 44, accuracy: 0.001)
        p.stampRate(using: svc)   // não pode apagar a cotação digitada
        XCTAssertEqual(p.rateToBase, 5.5, accuracy: 0.001)
        XCTAssertEqual(p.baseAmount(in: svc), 44, accuracy: 0.001)
    }

    func testWithoutAnyRateFallsBackToCachedRatesInsteadOfBreaking() {
        let svc = service()
        let p = OneOffPayment(name: "Trae", amount: 8, currencyCode: "USD")
        XCTAssertGreaterThan(p.baseAmount(in: svc), 0)
    }

    func testSameCurrencyNeedsNoRate() {
        let svc = service()
        let p = OneOffPayment(name: "Café", amount: 12, currencyCode: svc.baseCode)
        XCTAssertEqual(p.baseAmount(in: svc), 12, accuracy: 0.001)
    }

    func testMonthTotalOnlyCountsThatMonth() {
        let svc = service()
        let cal = Calendar(identifier: .gregorian)
        let nov = cal.date(from: DateComponents(year: 2026, month: 11, day: 6))!
        let oct = cal.date(from: DateComponents(year: 2026, month: 10, day: 30))!
        let a = OneOffPayment(name: "A", amount: 30, currencyCode: svc.baseCode, paidAt: nov)
        let b = OneOffPayment(name: "B", amount: 70, currencyCode: svc.baseCode, paidAt: nov)
        let c = OneOffPayment(name: "C", amount: 999, currencyCode: svc.baseCode, paidAt: oct)
        XCTAssertEqual(OneOffPayments.total([a, b, c], inMonthOf: nov, service: svc, calendar: cal), 100, accuracy: 0.001)
    }

    // MARK: Compra do Pro vira despesa

    func testProPurchaseIsRecordedOnceWithTheRealPrice() throws {
        let context = try makeContext()
        let svc = service()
        let first = OneOffPayments.recordProPurchase(
            price: 49.90, currencyCode: "BRL", date: Date(), transactionID: "123", in: context, service: svc)
        XCTAssertEqual(first?.name, "SubCheck Pro")
        XCTAssertEqual(first?.amount ?? 0, 49.90, accuracy: 0.001)
        XCTAssertEqual(first?.sourceID, "123")

        let again = OneOffPayments.recordProPurchase(
            price: 49.90, currencyCode: "BRL", date: Date(), transactionID: "123", in: context, service: svc)
        XCTAssertNil(again)
        XCTAssertEqual(try context.fetch(FetchDescriptor<OneOffPayment>()).count, 1)
    }
}

@MainActor
final class CostViewTests: XCTestCase {

    private func service() -> CurrencyService {
        CurrencyService(defaults: UserDefaults(suiteName: "test-\(UUID().uuidString)")!)
    }

    func testTodayExcludesTrialsAndFutureIncludesThem() {
        let svc = service()
        let paid = Subscription(name: "Netflix", cost: 50, currencyCode: svc.baseCode)
        let trial = Subscription(name: "Cursor", cost: 100, currencyCode: svc.baseCode,
                                 trialEndsAt: Date().addingTimeInterval(86_400 * 5))
        let all = [paid, trial]

        XCTAssertTrue(trial.isInTrial)
        XCTAssertFalse(paid.isInTrial)
        XCTAssertEqual(all.monthlyTotal(in: svc, view: .today), 50, accuracy: 0.001)
        XCTAssertEqual(all.monthlyTotal(in: svc, view: .future), 150, accuracy: 0.001)
        XCTAssertEqual(all.trialMonthlyTotal(in: svc), 100, accuracy: 0.001)
        XCTAssertTrue(all.hasActiveTrials)
    }

    func testFinishedTrialCountsAsToday() {
        let svc = service()
        let ended = Subscription(name: "X", cost: 30, currencyCode: svc.baseCode,
                                 trialEndsAt: Date().addingTimeInterval(-86_400 * 2))
        XCTAssertFalse(ended.isInTrial)
        XCTAssertEqual([ended].monthlyTotal(in: svc, view: .today), 30, accuracy: 0.001)
    }

    func testMonthPlanIgnoresTrialsThatEndAfterTheMonth() {
        let cal = Calendar(identifier: .gregorian)
        let now = cal.date(from: DateComponents(year: 2026, month: 11, day: 6, hour: 12))!
        let svc = CurrencyService.shared
        let later = Subscription(name: "Later", cost: 100, currencyCode: svc.baseCode,
                                 trialEndsAt: cal.date(from: DateComponents(year: 2026, month: 12, day: 3)))
        let soon = Subscription(name: "Soon", cost: 40, currencyCode: svc.baseCode,
                                trialEndsAt: cal.date(from: DateComponents(year: 2026, month: 11, day: 20)))
        let plan = MonthPlan.make(salary: 1000, subscriptions: [later, soon], bills: [], entries: [], now: now, calendar: cal)
        XCTAssertEqual(plan.subscriptions, 40, accuracy: 0.001)   // só a que cobra ainda neste mês
    }
}

@MainActor
final class VariableSubscriptionPaymentTests: XCTestCase {

    func testRealAmountReplacesTheEstimateAndManualRateIsKept() throws {
        let container = try ModelContainer(
            for: SharedModelContainer.schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
        let context = ModelContext(container)
        let sub = Subscription(name: "OpenAI API", cost: 20, currencyCode: "USD",
                               startDate: Date().addingTimeInterval(-86_400 * 5))
        sub.billingKind = .variable
        context.insert(sub)

        let record = PaymentLedger.markPaid(sub, actualAmount: 37.5, manualRate: 5.25, in: context)
        XCTAssertEqual(record.amount, 37.5, accuracy: 0.001)
        XCTAssertEqual(sub.cost, 37.5, accuracy: 0.001)            // vira a estimativa seguinte
        XCTAssertTrue(record.rateIsManual)
        XCTAssertEqual(record.rateToBase, 5.25, accuracy: 0.0001)
        XCTAssertNotNil(sub.lastPaymentDate)
    }
}
