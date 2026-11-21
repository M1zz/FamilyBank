//
//  BankEngine.swift
//  쑥쑥용돈
//
//  이자 계산, 투자 시세 변동, 모든 돈 거래를 처리하는 엔진
//

import Foundation
import SwiftUI
import SwiftData

enum BankEngine {

    // MARK: - 주기 처리 (앱 실행 시 호출)

    /// 밀린 이자와 시세 변동을 한 번에 반영
    static func processTick(members: [FamilyMember],
                            products: [InvestProduct],
                            settings: FamilySettings,
                            context: ModelContext) {
        for member in members {
            applyInterest(to: member, weeklyRate: settings.weeklyInterestRate, context: context)
        }
        for product in products {
            updatePrice(of: product)
        }
        applyInflation(settings: settings)
        try? context.save()
    }

    // MARK: - 인플레이션 (주 단위 물가 상승)

    /// 밀린 주 수만큼 물가지수를 복리로 올린다. Pro 가 아니면 0%로 본다(`activeInflationRate`).
    static func applyInflation(settings: FamilySettings) {
        // 칸을 아직 모르면(페이월 전부터 쓰던 가족이 업데이트 뒤 처음 켠 순간) 밀린 주를 0%로 써 버리지 않고 기다린다.
        guard ProEntitlement.isKnown else { return }
        let rate = settings.activeInflationRate
        let week: TimeInterval = 7 * 24 * 60 * 60
        let elapsed = Date().timeIntervalSince(settings.lastInflationDate)
        let weeks = Int(elapsed / week)
        guard weeks > 0 else { return }

        if rate > 0 {
            for _ in 0..<min(weeks, 104) {
                settings.priceIndex *= (1 + rate / 100)
                settings.priceIndexHistory.append(settings.priceIndex)
            }
            if settings.priceIndexHistory.count > 104 {
                settings.priceIndexHistory = Array(settings.priceIndexHistory.suffix(104))
            }
        }
        settings.lastInflationDate = settings.lastInflationDate.addingTimeInterval(Double(weeks) * week)
    }

    // MARK: - 저축 이자 (주 단위 복리)

    static func applyInterest(to member: FamilyMember, weeklyRate: Double, context: ModelContext) {
        let week: TimeInterval = 7 * 24 * 60 * 60
        let elapsed = Date().timeIntervalSince(member.lastInterestDate)
        let weeks = Int(elapsed / week)
        guard weeks > 0 else { return }

        guard member.savings > 0, weeklyRate > 0 else {
            // 저축이 없으면 기준 시점만 앞으로 이동
            member.lastInterestDate = member.lastInterestDate.addingTimeInterval(Double(weeks) * week)
            return
        }

        var totalInterest = 0
        for _ in 0..<min(weeks, 52) {
            let interest = Int((Double(member.savings) * weeklyRate / 100).rounded())
            member.savings += interest
            totalInterest += interest
        }
        member.lastInterestDate = member.lastInterestDate.addingTimeInterval(Double(weeks) * week)

        if totalInterest > 0 {
            let tx = MoneyTransaction(kind: .interest,
                                      amount: totalInterest,
                                      memo: String(localized: "저축 이자 (주 \(weeklyRate.cleanPercent)%, \(weeks)주)", locale: AppLocale.current),
                                      member: member)
            context.insert(tx)
        }
    }

    // MARK: - 투자 시세 변동 (하루 1회 랜덤워크)

    static func updatePrice(of product: InvestProduct) {
        let day: TimeInterval = 24 * 60 * 60
        let elapsed = Date().timeIntervalSince(product.lastUpdate)
        let days = Int(elapsed / day)
        guard days > 0 else { return }

        for _ in 0..<min(days, 30) {
            let shock = Double.random(in: -1...1) * product.volatility
            let drift = product.trend / 100
            let newPrice = Double(product.price) * (1 + drift + shock)
            product.price = max(10, Int(newPrice.rounded()))
            product.priceHistory.append(product.price)
        }
        if product.priceHistory.count > 90 {
            product.priceHistory = Array(product.priceHistory.suffix(90))
        }
        product.lastUpdate = product.lastUpdate.addingTimeInterval(Double(days) * day)
    }

    // MARK: - 용돈 지급 / 차감 (부모 = 중앙은행)

    static func give(to member: FamilyMember, amount: Int, memo: String, context: ModelContext) {
        guard amount > 0 else { return }
        member.balance += amount
        let tx = MoneyTransaction(kind: .allowance,
                                  amount: amount,
                                  memo: memo.isEmpty ? String(localized: "용돈") : memo,
                                  member: member)
        context.insert(tx)
        try? context.save()
    }

    @discardableResult
    static func deduct(from member: FamilyMember, amount: Int, memo: String, context: ModelContext) -> Bool {
        guard amount > 0, member.balance >= amount else { return false }
        member.balance -= amount
        let tx = MoneyTransaction(kind: .deduct,
                                  amount: amount,
                                  memo: memo.isEmpty ? String(localized: "차감") : memo,
                                  member: member)
        context.insert(tx)
        try? context.save()
        return true
    }

    // MARK: - 결제 (자녀 → 부모)

    @discardableResult
    static func pay(from payer: FamilyMember, to receiver: FamilyMember?, amount: Int, memo: String, context: ModelContext) -> Bool {
        guard amount > 0, payer.balance >= amount else { return false }
        payer.balance -= amount
        let payTx = MoneyTransaction(kind: .payment,
                                     amount: amount,
                                     memo: memo.isEmpty ? String(localized: "결제") : memo,
                                     member: payer)
        context.insert(payTx)

        if let receiver {
            receiver.balance += amount
            let receiveTx = MoneyTransaction(kind: .receive,
                                             amount: amount,
                                             memo: String(localized: "\(payer.name)에게 받음 · \(memo.isEmpty ? String(localized: "결제") : memo)"),
                                             member: receiver)
            context.insert(receiveTx)
        }
        try? context.save()
        return true
    }

    // MARK: - 저축

    @discardableResult
    static func depositSavings(member: FamilyMember, amount: Int, context: ModelContext) -> Bool {
        guard amount > 0, member.balance >= amount else { return false }
        if member.savings == 0 {
            member.lastInterestDate = Date()  // 이자 계산 시작점 초기화
        }
        member.balance -= amount
        member.savings += amount
        let tx = MoneyTransaction(kind: .deposit, amount: amount, memo: String(localized: "저축통장에 입금"), member: member)
        context.insert(tx)
        try? context.save()
        return true
    }

    @discardableResult
    static func withdrawSavings(member: FamilyMember, amount: Int, context: ModelContext) -> Bool {
        guard amount > 0, member.savings >= amount else { return false }
        member.savings -= amount
        member.balance += amount
        let tx = MoneyTransaction(kind: .withdraw, amount: amount, memo: String(localized: "저축통장에서 출금"), member: member)
        context.insert(tx)
        try? context.save()
        return true
    }

    // MARK: - 투자

    @discardableResult
    static func buy(member: FamilyMember, product: InvestProduct, quantity: Int, context: ModelContext) -> Bool {
        let cost = product.price * quantity
        guard quantity > 0, member.balance >= cost else { return false }

        member.balance -= cost
        let holding: Holding
        if let existing = (member.holdings ?? []).first(where: { $0.product === product }) {
            holding = existing
        } else {
            holding = Holding(member: member, product: product)
            context.insert(holding)
        }
        holding.quantity += quantity
        holding.totalCost += cost

        let tx = MoneyTransaction(kind: .buy,
                                  amount: cost,
                                  memo: String(localized: "\(product.displayName) \(quantity)주 매수 (@\(product.price.comma))", locale: AppLocale.current),
                                  member: member)
        context.insert(tx)
        try? context.save()
        return true
    }

    @discardableResult
    static func sell(member: FamilyMember, product: InvestProduct, quantity: Int, context: ModelContext) -> Bool {
        guard quantity > 0,
              let holding = (member.holdings ?? []).first(where: { $0.product === product }),
              holding.quantity >= quantity else { return false }

        let proceeds = product.price * quantity
        // 평균 단가 기준으로 원가 차감
        let costOut = holding.quantity > 0 ? holding.totalCost * quantity / holding.quantity : 0
        holding.quantity -= quantity
        holding.totalCost = max(0, holding.totalCost - costOut)
        member.balance += proceeds

        if holding.quantity == 0 {
            context.delete(holding)
        }

        let tx = MoneyTransaction(kind: .sell,
                                  amount: proceeds,
                                  memo: String(localized: "\(product.displayName) \(quantity)주 매도 (@\(product.price.comma))", locale: AppLocale.current),
                                  member: member)
        context.insert(tx)
        try? context.save()
        return true
    }

    // MARK: - 기본 투자 상품

    static func defaultProducts() -> [InvestProduct] {
        [
            InvestProduct(name: String(localized: "거북이 안정펀드"), emoji: "🐢",
                          detail: String(localized: "천천히 하지만 꾸준히! 큰 변동 없이 조금씩 오르는 안전한 상품이에요."),
                          price: 1000, volatility: 0.02, trend: 0.10),
            InvestProduct(name: String(localized: "토끼 성장주"), emoji: "🐰",
                          detail: String(localized: "적당한 위험, 적당한 수익! 오르락내리락하지만 성장하는 상품이에요."),
                          price: 1000, volatility: 0.06, trend: 0.15),
            InvestProduct(name: String(localized: "로켓 모험주"), emoji: "🚀",
                          detail: String(localized: "크게 오를 수도, 크게 떨어질 수도! 위험을 감수해야 하는 상품이에요."),
                          price: 1000, volatility: 0.15, trend: 0.20)
        ]
    }
}

// MARK: - 숫자 표시 도우미

/// 숫자 · 날짜를 그릴 지역 설정.
/// 아랍어에서는 숫자를 0-9, 달력을 그레고리력으로 맞춘다. 다른 언어는 기기 설정 그대로다.
/// 문구 속 숫자(1,000 · 5%)는 0-9 로 쓰여 있어, 기기 지역(사우디 등)을 따르면 한 화면에 ١٢٣ 과 123 이 섞였다.
enum AppLocale {
    static let isArabic = Bundle.main.preferredLocalizations.first == "ar"

    static let current: Locale = {
        guard isArabic else { return .autoupdatingCurrent }
        var parts = Locale.Components(locale: .current)
        parts.languageComponents.languageCode = .arabic
        parts.numberingSystem = Locale.NumberingSystem("latn")
        parts.calendar = .gregorian
        return Locale(components: parts)
    }()
}

extension View {
    /// 앱의 맨 바깥 화면에 붙인다. 아랍어일 때만 숫자 · 달력을 `AppLocale` 로 바꾼다.
    @ViewBuilder func appLocale() -> some View {
        if AppLocale.isArabic {
            environment(\.locale, AppLocale.current)
                .environment(\.calendar, AppLocale.current.calendar)
        } else {
            self
        }
    }
}

extension Int {
    /// 1,234 형태 콤마 표기
    var comma: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = AppLocale.current
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension String {
    /// 왼쪽에서 오른쪽으로 묶은 조각. 아랍어(RTL) 화면에서 +500 이 500+ 로, -200 이 200- 로 뒤집히지 않게 한다.
    var ltr: String { "\u{2066}\(self)\u{2069}" }

    /// 숫자만 남기고 0-9 로 맞춘다. 아랍어 키보드로 친 ١٢٣ 도 123 으로 받는다.
    var asciiDigits: String {
        String(compactMap { $0.wholeNumberValue.map { Character(String($0)) } })
    }
}

extension Double {
    /// 5.0 → "5", 5.5 → "5.5"
    var cleanPercent: String {
        truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(format: "%.1f", self)
    }
}
