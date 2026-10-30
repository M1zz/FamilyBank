//
//  FamilyBankApp.swift
//  쑥쑥용돈
//
//  가족용 화폐 시스템: 용돈 지급, 결제, 저축 이자, 투자 체험
//

import SwiftUI
import SwiftData
import LeeoKit

@main
struct FamilyBankApp: App {
    let container: ModelContainer

    init() {
        // 사용량 기록 · 익명 사용 통계 · 크래시 진단 (FeedbackHub).
        LeeoKit.bootstrap(FamilyBankSpec.self)
        let schema = Schema([
            FamilyMember.self,
            MoneyTransaction.self,
            InvestProduct.self,
            Holding.self,
            HouseholdItem.self,
            FamilySettings.self
        ])
        do {
            // iCloud(CloudKit) 동기화 시도 — 가족 기기 간 데이터 공유
            let cloudConfig = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
            container = try ModelContainer(for: schema, configurations: [cloudConfig])
        } catch {
            // iCloud 설정이 안 되어 있으면 기기 로컬 저장으로 자동 전환
            do {
                let localConfig = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
                container = try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                container = try! ModelContainer(for: schema, configurations: [memoryConfig])
            }
        }
        // 스토어 스크린샷용 가상 장부 (DEBUG 빌드 + -ScreenshotDemo 일 때만)
        ScreenshotDemo.seedIfNeeded(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .leeoSatisfactionCheck(FamilyBankSpec.self)
                // 팁 상품을 불러오고 끝나지 않은 팁을 마저 센다.
                .task { await FamilyBankSpec.tipJar.startStandalone() }
                // 창 크기로 접힘을 재서 아래로 흘린다. 시트 · 알림창도 접힌 선을 비킨다 (LeeoKit Fold).
                .foldAware()
        }
        .modelContainer(container)
    }
}
