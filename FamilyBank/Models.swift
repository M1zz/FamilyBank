//
//  Models.swift
//  FamilyBank — 우리집 은행
//
//  SwiftData 모델 (CloudKit 동기화 호환: 모든 속성 기본값, 관계는 옵셔널)
//

import Foundation
import SwiftData

// MARK: - 역할

enum MemberRole: String, Codable, CaseIterable, Identifiable {
    case parent = "부모"
    case child = "자녀"
    var id: String { rawValue }
}

// MARK: - 거래 종류

enum TxKind: String, Codable, CaseIterable {
    case allowance = "용돈"
    case payment = "결제"
    case receive = "받은 돈"
    case deposit = "저축 입금"
    case withdraw = "저축 출금"
    case interest = "이자"
    case buy = "투자 매수"
    case sell = "투자 매도"
    case deduct = "차감"

    /// 지갑에 돈이 들어오는 거래인지
    var isIncome: Bool {
        switch self {
        case .allowance, .receive, .withdraw, .sell, .interest:
            return true
        case .payment, .deposit, .buy, .deduct:
            return false
        }
    }

    var icon: String {
        switch self {
        case .allowance: return "gift.fill"
        case .payment: return "cart.fill"
        case .receive: return "hand.thumbsup.fill"
        case .deposit: return "tray.and.arrow.down.fill"
        case .withdraw: return "tray.and.arrow.up.fill"
        case .interest: return "percent"
        case .buy: return "chart.line.uptrend.xyaxis"
        case .sell: return "chart.line.downtrend.xyaxis"
        case .deduct: return "minus.circle.fill"
        }
    }
}

// MARK: - 가족 구성원

@Model
final class FamilyMember {
    /// 기기 간 식별용 고유 ID (자녀 폰 모드 지정에 사용)
    var uid: String = ""
    var name: String = ""
    var emoji: String = "🙂"
    var roleRaw: String = MemberRole.child.rawValue
    /// 지갑 잔액
    var balance: Int = 0
    /// 저축 잔액 (매주 이자가 붙음)
    var savings: Int = 0
    /// 마지막으로 이자가 계산된 시점
    var lastInterestDate: Date = Date()
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \MoneyTransaction.member)
    var transactions: [MoneyTransaction]? = nil

    @Relationship(deleteRule: .cascade, inverse: \Holding.member)
    var holdings: [Holding]? = nil

    init(name: String, emoji: String, role: MemberRole) {
        self.uid = UUID().uuidString
        self.name = name
        self.emoji = emoji
        self.roleRaw = role.rawValue
        self.lastInterestDate = Date()
        self.createdAt = Date()
    }

    var role: MemberRole { MemberRole(rawValue: roleRaw) ?? .child }
    var isChild: Bool { role == .child }

    /// 투자 평가액
    var investValue: Int {
        (holdings ?? []).reduce(0) { $0 + $1.currentValue }
    }

    /// 총자산 = 지갑 + 저축 + 투자 평가액
    var totalAssets: Int { balance + savings + investValue }
}

// MARK: - 거래 내역

@Model
final class MoneyTransaction {
    var kindRaw: String = TxKind.allowance.rawValue
    var amount: Int = 0
    var memo: String = ""
    var date: Date = Date()
    var member: FamilyMember? = nil

    init(kind: TxKind, amount: Int, memo: String, member: FamilyMember?) {
        self.kindRaw = kind.rawValue
        self.amount = amount
        self.memo = memo
        self.date = Date()
        self.member = member
    }

    var kind: TxKind { TxKind(rawValue: kindRaw) ?? .allowance }
}

// MARK: - 투자 상품 (모의 펀드)

@Model
final class InvestProduct {
    var name: String = ""
    var emoji: String = "📈"
    var detail: String = ""
    /// 현재 1주 가격
    var price: Int = 1000
    var initialPrice: Int = 1000
    /// 하루 변동폭 (0.02 = ±2%)
    var volatility: Double = 0.06
    /// 하루 평균 상승 경향 (% 단위, 0.15 = 하루 +0.15%)
    var trend: Double = 0.15
    /// 최근 가격 기록 (최대 90개)
    var priceHistory: [Int] = []
    var lastUpdate: Date = Date()
    var isActive: Bool = true
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Holding.product)
    var holdingsList: [Holding]? = nil

    init(name: String, emoji: String, detail: String, price: Int, volatility: Double, trend: Double) {
        self.name = name
        self.emoji = emoji
        self.detail = detail
        self.price = price
        self.initialPrice = price
        self.volatility = volatility
        self.trend = trend
        self.priceHistory = [price]
        self.lastUpdate = Date()
        self.createdAt = Date()
    }

    /// 직전 가격 대비 변동률(%)
    var changeRate: Double {
        guard priceHistory.count >= 2 else { return 0 }
        let prev = priceHistory[priceHistory.count - 2]
        guard prev > 0 else { return 0 }
        return (Double(price - prev) / Double(prev)) * 100
    }

    /// 위험도 표시
    var riskLabel: String {
        if volatility <= 0.03 { return "안정형 🐢" }
        if volatility <= 0.09 { return "보통형 🐰" }
        return "위험형 🚀"
    }
}

// MARK: - 보유 내역

@Model
final class Holding {
    var quantity: Int = 0
    /// 총 매수 금액 (평균 단가 계산용)
    var totalCost: Int = 0
    var member: FamilyMember? = nil
    var product: InvestProduct? = nil

    init(member: FamilyMember?, product: InvestProduct?) {
        self.member = member
        self.product = product
    }

    var avgPrice: Int { quantity > 0 ? totalCost / quantity : 0 }
    var currentValue: Int { (product?.price ?? 0) * quantity }
    var profit: Int { currentValue - totalCost }
    var profitRate: Double {
        guard totalCost > 0 else { return 0 }
        return (Double(profit) / Double(totalCost)) * 100
    }
}

// MARK: - 우리집 가게 물품

@Model
final class HouseholdItem {
    /// 바코드 결제용 고유 ID
    var uid: String = ""
    var name: String = ""
    var emoji: String = "🛒"
    /// 실제 세상 가격 (원) — 코인 가격은 환율로 자동 계산
    var priceWon: Int = 1000
    var isActive: Bool = true
    var createdAt: Date = Date()

    init(name: String, emoji: String, priceWon: Int) {
        self.uid = UUID().uuidString
        self.name = name
        self.emoji = emoji
        self.priceWon = priceWon
        self.createdAt = Date()
    }
}

// MARK: - 가족 설정

@Model
final class FamilySettings {
    /// 우리집 화폐 이름 (예: 콩, 별, 코인)
    var currencyName: String = "코인"
    var parentPIN: String = "0000"
    /// 주간 저축 이자율 (%)
    var weeklyInterestRate: Double = 5.0
    /// 주간 물가 상승률 (%) — 0이면 인플레이션 없음
    var weeklyInflationRate: Double = 2.0
    /// 환율: 1 코인 = 몇 원 (예: 10 → 콜라 1,000원 = 100코인)
    var wonPerCoin: Double = 10.0
    /// 우리집 물가지수 (시작 100, 매주 물가 상승률만큼 오름)
    var priceIndex: Double = 100
    /// 주별 물가지수 기록 (최대 104주)
    var priceIndexHistory: [Double] = [100]
    /// 마지막으로 물가가 반영된 시점
    var lastInflationDate: Date = Date()
    var isSetupComplete: Bool = false
    var createdAt: Date = Date()

    init() {
        self.createdAt = Date()
        self.lastInflationDate = Date()
    }

    /// 물가가 시작(100) 대비 몇 % 올랐는지
    var inflationSinceStart: Double {
        (priceIndex / 100 - 1) * 100
    }

    /// 명목 금액의 실질 가치 (처음 물가 기준 구매력)
    func realValue(of amount: Int) -> Int {
        guard priceIndex > 0 else { return amount }
        return Int((Double(amount) * 100 / priceIndex).rounded())
    }

    /// 실제 가격(원) → 코인 가격 (환율 적용)
    func coinPrice(forWon won: Int) -> Int {
        guard wonPerCoin > 0 else { return won }
        return max(1, Int((Double(won) / wonPerCoin).rounded()))
    }

    /// 코인 → 실제 가치(원) 환산
    func wonValue(ofCoins coins: Int) -> Int {
        Int((Double(coins) * wonPerCoin).rounded())
    }
}
