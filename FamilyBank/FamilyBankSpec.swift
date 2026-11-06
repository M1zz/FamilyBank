import Foundation
import LeeoKit

enum FamilyBankSpec: LeeoAppSpec {
    static let appName = "쑥쑥용돈"
    static let developerEmail = "leeo@kakao.com"
    static let feedback = LeeoFeedbackConfig(containerIdentifier: "iCloud.com.Ysoup.FeedbackHub", appIdentifier: "com.family.FamilyBank")

    /// 법적·지원 링크 — docs/ 의 GitHub Pages (README 에 걸린 주소와 같다).
    /// 계정을 만들지 않는다.
    static let legal = LeeoLegalConfig(
        privacyURL: URL(string: "https://m1zz.github.io/FamilyBank/privacy.html")!,
        supportURL: URL(string: "https://m1zz.github.io/FamilyBank/support.html")!,
        marketingURL: URL(string: "https://m1zz.github.io/FamilyBank/")!
    )

    /// App Store 앱 ID — 리뷰 남기기·친구에게 소개하기 링크.
    static let appStoreID: String? = "6790130891"

    /// 수익모델 — 무료로 내려받고, 무료 · Plus · Pro 세 칸. 유료 칸마다 주 · 월 · 연 구독과 평생.
    /// 칸마다 무엇이 열리는지는 `ProFeature.tier` 한 곳에 있다(→ ProEntitlement.swift).
    static let monetization = LeeoMonetization.freemiumSubscription(
        LeeoSubscriptionConfig(
            productIDs: ProEntitlement.productIDs,
            // 자체 약관이 없으므로 애플 표준 사용권 계약(EULA)을 건다. 구독을 파는 앱의 심사 필수 항목이다.
            termsURL: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!,
            entitlementIDs: ProEntitlement.entitlementIDs,
            gate: LeeoGatePolicy(
                freeLimits: [Gate.children: ProEntitlement.freeChildLimit, Gate.storeItems: ProEntitlement.freeItemLimit],
                proOnly: Set([ProFeature.customInvest, .barcodePay, .inflation, .iCloudSync].map(\.rawValue))),
            // 개발자 응원 팁. 소모성 세 가지, 작은 것부터. 기능을 열지 않는다(→ `tipJar`).
            tipJar: LeeoTipJarConfig(productIDs: ProEntitlement.tipProductIDs)))

    /// 게이트 열쇠말.
    enum Gate {
        static let children = "children"
        static let storeItems = "storeItems"
    }

    /// 개발자 응원(팁). 결제 리스너를 함께 쓰도록 `LeeoStore` 가 만든 것을 쓴다.
    @MainActor static var tipJar: LeeoTipJar? { PurchaseManager.shared.store.tipJar }

    /// 익명 사용 통계 → FeedbackHub. 없으면 bootstrap 이 스냅샷·app_open 을 건너뛴다.
    static let analytics: any LeeoAnalytics = LeeoUsageAnalytics(spec: FamilyBankSpec.self)
}
