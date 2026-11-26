//
//  MoneyRulesTests.swift
//  쑥쑥용돈
//
//  환율 · 물가 · 칸(Plus/Pro) · 숫자 입력의 규칙.
//

import XCTest
@testable import FamilyBank

@MainActor
final class MoneyRulesTests: XCTestCase {

    private let week: TimeInterval = 7 * 24 * 60 * 60
    private let tierKey = "pro.tier"
    private let onSaleKey = "plans.onSale"
    private var savedTier: Any?
    private var savedOnSale: Any?

    override func setUp() async throws {
        savedTier = UserDefaults.standard.object(forKey: tierKey)
        savedOnSale = UserDefaults.standard.object(forKey: onSaleKey)
    }

    override func tearDown() async throws {
        UserDefaults.standard.set(savedTier, forKey: tierKey)
        UserDefaults.standard.set(savedOnSale, forKey: onSaleKey)
    }

    // MARK: - 거래 방향

    func testIncomeKindsAreExactlyTheOnesThatFillTheWallet() {
        let income = Set(TxKind.allCases.filter(\.isIncome))
        XCTAssertEqual(income, [.allowance, .receive, .withdraw, .sell, .interest])
    }

    // MARK: - 환율

    func testCoinPriceUsesExchangeRateAndRounds() {
        let s = FamilySettings()
        s.wonPerCoin = 10
        XCTAssertEqual(s.coinPrice(forWon: 1_000), 100)
        XCTAssertEqual(s.coinPrice(forWon: 1_005), 101, "반올림한다")
        XCTAssertEqual(s.coinPrice(forWon: 3), 1, "아무리 싸도 1코인은 받는다")
        XCTAssertEqual(s.wonValue(ofCoins: 100), 1_000)
    }

    func testZeroExchangeRateDoesNotDivideByZero() {
        let s = FamilySettings()
        s.wonPerCoin = 0
        XCTAssertEqual(s.coinPrice(forWon: 1_500), 1_500)
    }

    // MARK: - 물가

    func testRealValueShrinksAsPricesRise() {
        let s = FamilySettings()
        XCTAssertEqual(s.realValue(of: 1_000), 1_000)
        s.priceIndex = 125
        XCTAssertEqual(s.realValue(of: 1_000), 800)
        XCTAssertEqual(s.inflationSinceStart, 25, accuracy: 0.0001)
    }

    func testInflationCompoundsForProFamilies() {
        UserDefaults.standard.set(true, forKey: onSaleKey)
        ProEntitlement.setTier(.pro)
        let s = FamilySettings()
        s.weeklyInflationRate = 10
        let start = Date().addingTimeInterval(-2 * week - 60)
        s.lastInflationDate = start

        BankEngine.applyInflation(settings: s)

        XCTAssertEqual(s.priceIndex, 121, accuracy: 0.0001)
        XCTAssertEqual(s.priceIndexHistory.count, 3)
        XCTAssertEqual(s.lastInflationDate.timeIntervalSince(start), 2 * week, accuracy: 0.001)
    }

    func testInflationIsOffWithoutProButClockStillMoves() {
        UserDefaults.standard.set(true, forKey: onSaleKey)
        ProEntitlement.setTier(.free)
        let s = FamilySettings()
        s.weeklyInflationRate = 10
        s.lastInflationDate = Date().addingTimeInterval(-3 * week - 60)

        BankEngine.applyInflation(settings: s)

        XCTAssertEqual(s.priceIndex, 100, "무료 칸에서는 물가가 오르지 않는다")
        XCTAssertLessThan(Date().timeIntervalSince(s.lastInflationDate), week,
                          "나중에 Pro 가 돼도 지난 주들을 한꺼번에 올리지 않는다")
    }

    func testInflationWaitsUntilTierIsKnown() {
        UserDefaults.standard.removeObject(forKey: tierKey)
        let s = FamilySettings()
        let start = Date().addingTimeInterval(-3 * week)
        s.lastInflationDate = start
        BankEngine.applyInflation(settings: s)
        XCTAssertEqual(s.lastInflationDate, start, "애플에게 묻기 전에는 밀린 주를 0%로 써 버리지 않는다")
    }

    func testPriceIndexHistoryKeepsTwoYears() {
        UserDefaults.standard.set(true, forKey: onSaleKey)
        ProEntitlement.setTier(.pro)
        let s = FamilySettings()
        s.weeklyInflationRate = 1
        s.priceIndexHistory = Array(repeating: 100, count: 100)
        s.lastInflationDate = Date().addingTimeInterval(-10 * week - 60)
        BankEngine.applyInflation(settings: s)
        XCTAssertEqual(s.priceIndexHistory.count, 104)
    }

    // MARK: - 칸

    func testHighestOwnedTierWins() {
        XCTAssertEqual(ProEntitlement.tier(owning: []), .free)
        XCTAssertEqual(ProEntitlement.tier(owning: [ProEntitlement.plusYearlyID]), .plus)
        XCTAssertEqual(ProEntitlement.tier(owning: [ProEntitlement.plusYearlyID, ProEntitlement.proLifetimeID]), .pro)
        XCTAssertEqual(ProEntitlement.tier(owning: ["com.family.FamilyBank.tip.small"]), .free, "팁은 칸을 열지 않는다")
    }

    func testLifetimeOwnershipIsPerTier() {
        XCTAssertTrue(ProEntitlement.ownsLifetime(.plus, in: [ProEntitlement.plusLifetimeID]))
        XCTAssertFalse(ProEntitlement.ownsLifetime(.pro, in: [ProEntitlement.plusLifetimeID]))
        XCTAssertFalse(ProEntitlement.ownsLifetime(.plus, in: [ProEntitlement.plusYearlyID]), "연간 구독은 평생이 아니다")
    }

    func testNothingIsLockedBeforeProductsAreOnSale() {
        UserDefaults.standard.set(false, forKey: onSaleKey)
        ProEntitlement.setTier(.free)
        XCTAssertTrue(ProFeature.allCases.allSatisfy(ProEntitlement.allows),
                      "살 수 없는 기기에서는 막지 않는다")
        UserDefaults.standard.set(true, forKey: onSaleKey)
        XCTAssertFalse(ProEntitlement.allows(.inflation))
    }

    // MARK: - 숫자

    func testArabicDigitsAreReadAsAscii() {
        XCTAssertEqual("١٢٣".asciiDigits, "123")
        XCTAssertEqual("1,500원".asciiDigits, "1500")
    }

    func testCleanPercent() {
        XCTAssertEqual(5.0.cleanPercent, "5")
        XCTAssertEqual(2.5.cleanPercent, "2.5")
    }
}
