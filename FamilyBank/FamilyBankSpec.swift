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

    /// 수익모델 — 인앱 결제가 없는 완전 무료 앱.
    static let monetization = LeeoMonetization.free

    /// 익명 사용 통계 → FeedbackHub. 없으면 bootstrap 이 스냅샷·app_open 을 건너뛴다.
    static let analytics: any LeeoAnalytics = LeeoUsageAnalytics(spec: FamilyBankSpec.self)
}
