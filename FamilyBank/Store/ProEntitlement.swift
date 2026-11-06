//
//  ProEntitlement.swift
//  쑥쑥용돈
//
//  우리집 은행의 어느 칸(무료 · Plus · Pro)을 쓰는가. 칸마다 무엇이 열리는지는 여기 한 곳에만 적는다.
//
//   · 무료: 화폐 · 용돈 · 결제 · 저축 이자 · 기본 투자 3종 · 자녀 폰 모드 · 기록 전부 · 배우기. 자녀 2명, 가게 물품 10개.
//   · Plus: 자녀 · 물품 제한 없음, 투자 상품 직접 만들기.
//   · Pro:  Plus 전부 + 바코드 결제, 물가 상승 체험, iCloud 기기 간 동기화.
//
//  ⚠️ 아이의 잔액 · 저축 · 투자 · 기록은 어떤 칸에서도 잠그거나 지우지 않는다.
//     한도는 **새로 만드는 것**만 본다. 한도를 넘는 옛 자녀 · 물품 · 상품은 그대로 쓴다.
//  ⚠️ 팁은 권한이 아니다. 팁 상품을 `tierByProduct` 에 넣지 않는다.
//
//  StoreKit 은 여기 없다. 영수증 확인은 `PurchaseManager` 가 하고 그 결과를 여기 한 줄로 적는다.
//  (앱을 켤 때 저장소를 고르는 `FamilyBankApp.init` 이 StoreKit 을 기다리지 않고 읽을 수 있게.)
//

import Foundation

/// 칸. 값이 클수록 더 많이 연다. Pro 는 Plus 를 전부 포함한다.
enum ProTier: Int, Comparable, CaseIterable {
    case free = 0
    case plus = 1
    case pro = 2

    static func < (lhs: ProTier, rhs: ProTier) -> Bool { lhs.rawValue < rhs.rawValue }

    var title: String {
        switch self {
        case .free: String(localized: "무료")
        case .plus: String(localized: "쑥쑥용돈 Plus")
        case .pro:  String(localized: "쑥쑥용돈 Pro")
        }
    }

    /// 페이월 카드의 한 줄.
    var tagline: String {
        switch self {
        case .free: String(localized: "부모는 중앙은행, 아이 둘은 용돈을 받고 저축해 이자를 받아요")
        case .plus: String(localized: "아이가 몇 명이든, 우리집 가게를 마음껏")
        case .pro:  String(localized: "바코드로 결제하고, 물가까지 배우고, 기기 어디서나")
        }
    }
}

/// 값을 받고 여는 것. 페이월 카드와 잠긴 자리가 이 목록 하나를 함께 읽는다.
enum ProFeature: String, CaseIterable, Identifiable {
    case moreChildren
    case moreItems
    case customInvest
    case barcodePay
    case inflation
    case iCloudSync

    var id: String { rawValue }

    /// 이 기능을 여는 가장 낮은 칸.
    var tier: ProTier {
        switch self {
        case .moreChildren, .moreItems, .customInvest: .plus
        case .barcodePay, .inflation, .iCloudSync:     .pro
        }
    }

    /// 그 칸에서 새로 열리는 것 (페이월 카드 차례).
    static func opened(by tier: ProTier) -> [ProFeature] { allCases.filter { $0.tier == tier } }

    var title: String {
        switch self {
        case .moreChildren: String(localized: "자녀 수 제한 없음")
        case .moreItems:    String(localized: "우리집 가게 물품 무제한")
        case .customInvest: String(localized: "투자 상품 직접 만들기")
        case .barcodePay:   String(localized: "바코드 결제")
        case .inflation:    String(localized: "물가 상승 체험")
        case .iCloudSync:   String(localized: "iCloud 기기 간 동기화")
        }
    }

    var note: String {
        switch self {
        case .moreChildren: String(localized: "셋째도 넷째도 형제 모두 같이 용돈을 받고 이자를 받아요.")
        case .moreItems:    String(localized: "간식, 게임 시간, 주말 외식권까지 살 거리를 마음껏 올려요.")
        case .customInvest: String(localized: "이름, 시작 가격, 위험도를 정해 우리집만의 상품을 만들어요.")
        case .barcodePay:   String(localized: "아이가 물품 바코드를 찍어 직접 결제해요.")
        case .inflation:    String(localized: "매주 오르는 우리집 물가지수로 돈의 가치가 줄어드는 걸 배워요.")
        case .iCloudSync:   String(localized: "아이폰과 아이패드의 기록을 iCloud로 맞춰요.")
        }
    }

    var systemImage: String {
        switch self {
        case .moreChildren: "person.3.fill"
        case .moreItems:    "storefront.fill"
        case .customInvest: "chart.line.uptrend.xyaxis"
        case .barcodePay:   "barcode.viewfinder"
        case .inflation:    "cart.fill.badge.plus"
        case .iCloudSync:   "icloud.fill"
        }
    }
}

enum ProEntitlement {

    // MARK: - 무료 한도

    /// 무료로 둘 수 있는 자녀 수.
    static let freeChildLimit = 2
    /// 무료로 올릴 수 있는 우리집 가게 물품 수.
    static let freeItemLimit = 10

    // MARK: - 상품 ID
    //
    // ⚠️ App Store Connect · `FamilyBank.storekit` 과 글자 하나까지 같아야 한다.
    //    주 · 월 · 연 구독 여섯은 **한 구독 그룹**에 넣는다(Pro 가 위 단계). 그래야 서로 갈아탄다.

    private static let prefix = "com.family.FamilyBank"

    static let plusWeeklyID   = prefix + ".plus.weekly"
    static let plusMonthlyID  = prefix + ".plus.monthly"
    static let plusYearlyID   = prefix + ".plus.yearly"
    /// Plus 평생.
    static let plusLifetimeID = prefix + ".plus"
    static let proWeeklyID    = prefix + ".pro.weekly"
    static let proMonthlyID   = prefix + ".pro.monthly"
    static let proYearlyID    = prefix + ".pro.yearly"
    /// Pro 평생.
    static let proLifetimeID  = prefix + ".pro"
    /// Plus 평생을 산 사람이 Pro 평생으로 올리는 값.
    static let upgradeID      = prefix + ".pro.upgrade"
    /// 구독 중인 사람의 졸업가 Pro 평생 (→ LeeoGraduation).
    static let graduateID     = prefix + ".pro.graduate"

    /// 개발자 응원 팁 (소모성 셋, 작은 것부터). 아무것도 열지 않는다.
    static let tipProductIDs = [prefix + ".tip.small", prefix + ".tip.medium", prefix + ".tip.large"]

    /// 페이월이 불러올 상품. 스토어에 아직 없는 것은 불러와지지 않고, 그 단추는 서지 않는다.
    static let productIDs = [plusYearlyID, plusLifetimeID, proYearlyID, proLifetimeID, upgradeID, graduateID,
                             plusWeeklyID, plusMonthlyID, proWeeklyID, proMonthlyID]

    /// 상품마다 여는 칸. 구독은 같은 칸의 평생과 같은 권한, 올리기 · 졸업은 Pro 평생이다.
    static let tierByProduct: [String: ProTier] = [
        plusWeeklyID: .plus, plusMonthlyID: .plus, plusYearlyID: .plus, plusLifetimeID: .plus,
        proWeeklyID: .pro, proMonthlyID: .pro, proYearlyID: .pro, proLifetimeID: .pro,
        upgradeID: .pro, graduateID: .pro,
    ]

    static var entitlementIDs: Set<String> { Set(tierByProduct.keys) }

    /// 평생 상품 (끝나지 않는 것).
    static let lifetimeIDs: Set<String> = [plusLifetimeID, proLifetimeID, upgradeID, graduateID]

    /// 연 구독. 구독 졸업을 제안할 대상이다. 주 · 월 구독에 졸업가를 주면 한 주 값으로 평생이 싸진다.
    static let yearlyIDs: Set<String> = [plusYearlyID, proYearlyID]

    /// 자동 갱신 구독 전부.
    static let subscriptionIDs: Set<String> = [plusWeeklyID, plusMonthlyID, plusYearlyID,
                                               proWeeklyID, proMonthlyID, proYearlyID]

    /// 가진 상품이 여는 칸. 가장 높은 것을 쓴다.
    static func tier(owning productIDs: Set<String>) -> ProTier {
        productIDs.compactMap { tierByProduct[$0] }.max() ?? .free
    }

    /// 이 칸의 평생을 이미 가졌는가.
    static func ownsLifetime(_ tier: ProTier, in productIDs: Set<String>) -> Bool {
        productIDs.contains { lifetimeIDs.contains($0) && tierByProduct[$0] == tier }
    }

    // MARK: - 지금 쓰는 칸 (영수증의 거울)

    private static let tierKey = "pro.tier"
    private static var defaults: UserDefaults { .standard }

    /// 지금 쓰는 칸. 스크린샷 데모는 모든 기능을 보인다.
    static var tier: ProTier {
        if ScreenshotDemo.isOn { return .pro }
        return cachedTier ?? .free
    }

    static func allows(_ feature: ProFeature) -> Bool { !isSelling || tier >= feature.tier }

    private static let onSaleKey = "plans.onSale"

    /// **팔기 시작했는가.** 유료 칸 상품을 하나도 못 불러온 기기는 한도로 막지 않는다.
    /// ⚠️ App Store Connect 에 상품이 서기 전에 빌드가 나가면, 살 수 없는데 막히는 사람이 생긴다.
    ///    한 번이라도 불러온 기기는 기억해 둔다 — 그 뒤로 잠깐 오프라인이어도 다시 한도가 선다.
    static var isSelling: Bool { defaults.bool(forKey: onSaleKey) }

    /// `PurchaseManager` 만 부른다.
    static func markSelling() { defaults.set(true, forKey: onSaleKey) }

    /// 적혀 있는 답. **nil 은 '무료'가 아니라 '아직 애플에게 안 물어봤다'** 이다.
    static var cachedTier: ProTier? {
        (defaults.object(forKey: tierKey) as? Int).flatMap(ProTier.init(rawValue:))
    }

    /// 애플에게 물어본 적이 있는가.
    static var isKnown: Bool { ScreenshotDemo.isOn || cachedTier != nil }

    /// `PurchaseManager` 만 부른다.
    static func setTier(_ value: ProTier) {
        guard cachedTier != value else { return }
        defaults.set(value.rawValue, forKey: tierKey)
    }

    // MARK: - iCloud 동기화

    /// 이번 실행에 iCloud 로 맞출 것인가. 저장소를 열기 전에 한 번 읽는다.
    ///
    /// 아직 애플에게 묻기 전(nil)이면 켠다. 페이월이 생기기 전부터 쓰던 가족은 동기화로 기록을 맞춰 왔고,
    /// 그분들은 곧 Pro 로 확인된다(`grandfathered`). 확인 전 한 번 꺼 버리면 그사이 적은 것이 다른 기기에 늦게 간다.
    /// ⚠️ 끄더라도 기기 안 기록은 그대로다. iCloud 쪽 사본도 지우지 않는다.
    static var syncsWithICloud: Bool {
        if ScreenshotDemo.isOn { return false }
        guard isSelling, let cachedTier else { return true }
        return cachedTier >= ProFeature.iCloudSync.tier
    }

    // MARK: - 페이월 전부터 쓰던 가족

    /// 무료였던 마지막 빌드(1.0.3 빌드 6). 이 빌드 이하로 처음 받은 사람은 Pro 평생이다.
    static let lastFreeBuild = 6

    private static let legacyCheckedKey = "pro.legacy.checked"
    private static let legacyFamilyKey = "pro.legacy.family"

    /// 이 기기에 페이월 전부터 쓰던 우리집 은행이 있었는가.
    static var hadFamilyBeforePaywall: Bool { defaults.bool(forKey: legacyFamilyKey) }

    /// 페이월이 생긴 버전을 **처음 켤 때 한 번만** 적는다. 그때 이미 가족 장부가 있었으면 쓰던 가족이다.
    /// 그 뒤에 새로 만든 장부는 세지 않는다.
    static func noteFamilyBeforePaywall(hasFamily: () -> Bool) {
        guard !defaults.bool(forKey: legacyCheckedKey) else { return }
        defaults.set(true, forKey: legacyCheckedKey)
        if hasFamily() { defaults.set(true, forKey: legacyFamilyKey) }
    }
}

// MARK: - 물가 상승 체험 (Pro)

extension FamilySettings {
    /// 실제로 물가에 반영되는 주간 상승률. Pro 가 아니면 0%다 — 정해 둔 값은 지우지 않고 그대로 둔다.
    var activeInflationRate: Double {
        ProEntitlement.allows(.inflation) ? weeklyInflationRate : 0
    }
}
