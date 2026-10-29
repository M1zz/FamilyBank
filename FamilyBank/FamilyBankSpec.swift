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

    /// 수익모델 — 인앱 결제가 없는 완전 무료 앱.
    static let monetization = LeeoMonetization.free

    /// 개발자 응원(팁). 소모성 세 가지, 작은 것부터. 기능을 열지 않는다 — 무료 앱이라 혼자 돈다(`startStandalone`).
    @MainActor static let tipJar = LeeoTipJar(config: LeeoTipJarConfig(productIDs: [
        "com.family.FamilyBank.tip.small", "com.family.FamilyBank.tip.medium", "com.family.FamilyBank.tip.large",
    ]))

    /// 익명 사용 통계 → FeedbackHub. 없으면 bootstrap 이 스냅샷·app_open 을 건너뛴다.
    static let analytics: any LeeoAnalytics = LeeoUsageAnalytics(spec: FamilyBankSpec.self)
}
