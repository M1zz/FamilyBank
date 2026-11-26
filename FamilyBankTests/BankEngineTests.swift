//
//  BankEngineTests.swift
//  쑥쑥용돈
//
//  돈이 새거나 생기지 않는지 — 용돈 · 결제 · 저축 · 이자 · 투자 · 물가의 셈을 본다.
//

import XCTest
import SwiftData
@testable import FamilyBank

@MainActor
final class BankEngineTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext { container.mainContext }
    private let week: TimeInterval = 7 * 24 * 60 * 60
    private let day: TimeInterval = 24 * 60 * 60

    override func setUp() async throws {
        let schema = Schema([FamilyMember.self, MoneyTransaction.self, InvestProduct.self,
                             Holding.self, HouseholdItem.self, FamilySettings.self])
        container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
    }

    override func tearDown() async throws {
        container = nil
    }

    private func child(balance: Int = 0, savings: Int = 0) -> FamilyMember {
        let m = FamilyMember(name: "아이", emoji: "🙂", role: .child)
        m.balance = balance
        m.savings = savings
        context.insert(m)
        return m
    }

    private func product(price: Int = 1000, volatility: Double = 0.06, trend: Double = 0.15) -> InvestProduct {
        let p = InvestProduct(name: "테스트 펀드", emoji: "📈", detail: "", price: price,
                              volatility: volatility, trend: trend)
        context.insert(p)
        return p
    }

    private func transactions(of member: FamilyMember) throws -> [MoneyTransaction] {
        try context.fetch(FetchDescriptor<MoneyTransaction>()).filter { $0.member === member }
    }

    // MARK: - 용돈 · 차감

    func testGiveAddsToWalletAndRecordsAllowance() throws {
        let kid = child()
        BankEngine.give(to: kid, amount: 500, memo: "", context: context)
        XCTAssertEqual(kid.balance, 500)
        let txs = try transactions(of: kid)
        XCTAssertEqual(txs.count, 1)
        XCTAssertEqual(txs.first?.kind, .allowance)
        XCTAssertEqual(txs.first?.amount, 500)
    }

    func testGiveIgnoresZeroAndNegative() throws {
        let kid = child(balance: 100)
        BankEngine.give(to: kid, amount: 0, memo: "", context: context)
        BankEngine.give(to: kid, amount: -50, memo: "", context: context)
        XCTAssertEqual(kid.balance, 100)
        XCTAssertTrue(try transactions(of: kid).isEmpty)
    }

    func testDeductNeverGoesBelowZero() throws {
        let kid = child(balance: 300)
        XCTAssertFalse(BankEngine.deduct(from: kid, amount: 301, memo: "", context: context))
        XCTAssertEqual(kid.balance, 300)
        XCTAssertTrue(BankEngine.deduct(from: kid, amount: 300, memo: "벌금", context: context))
        XCTAssertEqual(kid.balance, 0)
        XCTAssertEqual(try transactions(of: kid).map(\.kind), [.deduct])
    }

    // MARK: - 결제

    func testPayMovesMoneyBetweenMembersWithoutCreatingAny() throws {
        let kid = child(balance: 1000)
        let parent = FamilyMember(name: "엄마", emoji: "👩", role: .parent)
        context.insert(parent)

        XCTAssertTrue(BankEngine.pay(from: kid, to: parent, amount: 400, memo: "과자", context: context))
        XCTAssertEqual(kid.balance, 600)
        XCTAssertEqual(parent.balance, 400)
        XCTAssertEqual(kid.balance + parent.balance, 1000, "결제는 돈을 옮길 뿐 만들거나 없애지 않는다")
        XCTAssertEqual(try transactions(of: kid).map(\.kind), [.payment])
        XCTAssertEqual(try transactions(of: parent).map(\.kind), [.receive])
    }

    func testPayToCentralBankOnlyDebitsPayer() {
        let kid = child(balance: 200)
        XCTAssertTrue(BankEngine.pay(from: kid, to: nil, amount: 200, memo: "", context: context))
        XCTAssertEqual(kid.balance, 0)
    }

    func testPayRejectsOverdraft() {
        let kid = child(balance: 99)
        XCTAssertFalse(BankEngine.pay(from: kid, to: nil, amount: 100, memo: "", context: context))
        XCTAssertEqual(kid.balance, 99)
    }

    // MARK: - 저축

    func testDepositAndWithdrawKeepTotalConstant() {
        let kid = child(balance: 1000)
        XCTAssertTrue(BankEngine.depositSavings(member: kid, amount: 700, context: context))
        XCTAssertEqual(kid.balance, 300)
        XCTAssertEqual(kid.savings, 700)
        XCTAssertFalse(BankEngine.withdrawSavings(member: kid, amount: 701, context: context))
        XCTAssertTrue(BankEngine.withdrawSavings(member: kid, amount: 200, context: context))
        XCTAssertEqual(kid.balance, 500)
        XCTAssertEqual(kid.savings, 500)
        XCTAssertEqual(kid.balance + kid.savings, 1000)
    }

    func testFirstDepositRestartsInterestClock() {
        let kid = child(balance: 1000)
        kid.lastInterestDate = Date().addingTimeInterval(-10 * week)
        BankEngine.depositSavings(member: kid, amount: 100, context: context)
        XCTAssertLessThan(abs(kid.lastInterestDate.timeIntervalSinceNow), 5,
                          "빈 통장에 처음 넣은 돈이 지난 10주치 이자를 받으면 안 된다")
    }

    // MARK: - 이자

    func testInterestCompoundsWeekly() throws {
        let kid = child(savings: 10_000)
        let start = Date().addingTimeInterval(-3 * week - 60)
        kid.lastInterestDate = start
        BankEngine.applyInterest(to: kid, weeklyRate: 5, context: context)
        // 10000 → 10500 → 11025 → 11576 (매주 반올림)
        XCTAssertEqual(kid.savings, 11_576)
        let txs = try transactions(of: kid)
        XCTAssertEqual(txs.map(\.kind), [.interest])
        XCTAssertEqual(txs.first?.amount, 1_576)
        XCTAssertEqual(kid.lastInterestDate.timeIntervalSince(start), 3 * week, accuracy: 0.001,
                       "남은 몇 분은 다음 주 셈으로 넘긴다")
    }

    func testNoInterestBeforeAFullWeek() throws {
        let kid = child(savings: 10_000)
        kid.lastInterestDate = Date().addingTimeInterval(-6 * day)
        BankEngine.applyInterest(to: kid, weeklyRate: 5, context: context)
        XCTAssertEqual(kid.savings, 10_000)
        XCTAssertTrue(try transactions(of: kid).isEmpty)
    }

    func testEmptySavingsOnlyMovesClock() throws {
        let kid = child(savings: 0)
        let start = Date().addingTimeInterval(-2 * week - 1)
        kid.lastInterestDate = start
        BankEngine.applyInterest(to: kid, weeklyRate: 5, context: context)
        XCTAssertEqual(kid.savings, 0)
        XCTAssertEqual(kid.lastInterestDate.timeIntervalSince(start), 2 * week, accuracy: 0.001)
        XCTAssertTrue(try transactions(of: kid).isEmpty)
    }

    func testInterestIsCappedAtOneYear() {
        let kid = child(savings: 1_000)
        kid.lastInterestDate = Date().addingTimeInterval(-200 * week)
        BankEngine.applyInterest(to: kid, weeklyRate: 1, context: context)
        var expected = 1_000
        for _ in 0..<52 { expected += Int((Double(expected) * 0.01).rounded()) }
        XCTAssertEqual(kid.savings, expected, "오래 안 켠 기기도 1년치(52주)까지만 붙인다")
    }

    // MARK: - 투자

    func testBuyThenSellAtSamePriceIsBreakEven() throws {
        let kid = child(balance: 10_000)
        let fund = product(price: 1_000)
        XCTAssertTrue(BankEngine.buy(member: kid, product: fund, quantity: 3, context: context))
        XCTAssertEqual(kid.balance, 7_000)
        let holding = try XCTUnwrap(kid.holdings?.first)
        XCTAssertEqual(holding.quantity, 3)
        XCTAssertEqual(holding.avgPrice, 1_000)
        XCTAssertEqual(kid.totalAssets, 10_000)

        XCTAssertTrue(BankEngine.sell(member: kid, product: fund, quantity: 3, context: context))
        XCTAssertEqual(kid.balance, 10_000)
    }

    func testBuyRejectsWhenNotEnoughMoney() {
        let kid = child(balance: 1_999)
        let fund = product(price: 1_000)
        XCTAssertFalse(BankEngine.buy(member: kid, product: fund, quantity: 2, context: context))
        XCTAssertEqual(kid.balance, 1_999)
        XCTAssertTrue((kid.holdings ?? []).isEmpty)
    }

    func testAverageCostAcrossTwoBuysAndPartialSell() throws {
        let kid = child(balance: 100_000)
        let fund = product(price: 1_000)
        BankEngine.buy(member: kid, product: fund, quantity: 2, context: context)   // 2,000
        fund.price = 2_500
        BankEngine.buy(member: kid, product: fund, quantity: 2, context: context)   // 5,000
        let holding = try XCTUnwrap(kid.holdings?.first)
        XCTAssertEqual(kid.holdings?.count, 1, "같은 상품은 한 보유 칸에 모은다")
        XCTAssertEqual(holding.quantity, 4)
        XCTAssertEqual(holding.avgPrice, 1_750)

        fund.price = 2_000
        XCTAssertTrue(BankEngine.sell(member: kid, product: fund, quantity: 1, context: context))
        XCTAssertEqual(holding.quantity, 3)
        XCTAssertEqual(holding.totalCost, 5_250, "판 1주만큼 평균 단가로 원가를 뺀다")
        XCTAssertEqual(holding.avgPrice, 1_750, "일부를 팔아도 평균 단가는 그대로다")
        XCTAssertEqual(holding.profit, 3 * 2_000 - 5_250)
    }

    func testCannotSellMoreThanHeld() {
        let kid = child(balance: 10_000)
        let fund = product(price: 1_000)
        BankEngine.buy(member: kid, product: fund, quantity: 1, context: context)
        XCTAssertFalse(BankEngine.sell(member: kid, product: fund, quantity: 2, context: context))
        XCTAssertFalse(BankEngine.sell(member: kid, product: product(), quantity: 1, context: context),
                       "안 가진 상품은 못 판다")
        XCTAssertEqual(kid.balance, 9_000)
    }

    // MARK: - 시세

    func testPriceMovesOncePerDayAndStaysAboveFloor() {
        let risky = product(price: 12, volatility: 0.9, trend: -50)
        let start = Date().addingTimeInterval(-5 * day - 60)
        risky.lastUpdate = start
        BankEngine.updatePrice(of: risky)
        XCTAssertEqual(risky.priceHistory.count, 1 + 5, "지난 날 수만큼 한 번씩 움직인다")
        XCTAssertGreaterThanOrEqual(risky.price, 10, "값은 10 아래로 떨어지지 않는다")
        XCTAssertTrue(risky.priceHistory.allSatisfy { $0 >= 10 })
        XCTAssertEqual(risky.lastUpdate.timeIntervalSince(start), 5 * day, accuracy: 0.001)
    }

    func testPriceHistoryKeepsLast90() {
        let fund = product()
        fund.priceHistory = Array(repeating: 1000, count: 89)
        fund.lastUpdate = Date().addingTimeInterval(-30 * day - 1)
        BankEngine.updatePrice(of: fund)
        XCTAssertEqual(fund.priceHistory.count, 90)
    }

    func testPriceUnchangedWithinSameDay() {
        let fund = product()
        fund.lastUpdate = Date().addingTimeInterval(-23 * 60 * 60)
        BankEngine.updatePrice(of: fund)
        XCTAssertEqual(fund.priceHistory, [1000])
    }

    func testChangeRateComparesWithPreviousPrice() {
        let fund = product(price: 1_000)
        XCTAssertEqual(fund.changeRate, 0, "기록이 하나면 변동이 없다")
        fund.priceHistory = [1_000, 1_100]
        fund.price = 1_100
        XCTAssertEqual(fund.changeRate, 10, accuracy: 0.0001)
    }
}
