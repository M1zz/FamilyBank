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
        LeeoEngagement.shared.registerLaunch()
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
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .leeoSatisfactionCheck(FamilyBankSpec.self)
        }
        .modelContainer(container)
    }
}
