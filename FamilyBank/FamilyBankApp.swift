//
//  FamilyBankApp.swift
//  쑥쑥용돈
//
//  가족용 화폐 시스템: 용돈 지급, 결제, 저축 이자, 투자 체험
//

import SwiftUI
import SwiftData
import AppIntents
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
                container = StoreFallback.memoryContainer(schema: schema, after: error)
            }
        }
        // Siri 인텐트가 같은 장부를 쓴다 (→ AllowanceIntents.swift)
        let shared = container
        AppDependencyManager.shared.add(dependency: shared)
        // 스토어 스크린샷용 가상 장부 (DEBUG 빌드 + -ScreenshotDemo 일 때만)
        ScreenshotDemo.seedIfNeeded(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .leeoSatisfactionCheck(FamilyBankSpec.self)
                .storeFallbackNotice()
                // 팁 상품을 불러오고 끝나지 않은 팁을 마저 센다.
                .task { await FamilyBankSpec.tipJar.startStandalone() }
                // 창 크기로 접힘을 재서 아래로 흘린다. 시트 · 알림창도 접힌 선을 비킨다 (LeeoKit Fold).
                .foldAware()
        }
        .modelContainer(container)
    }
}

// MARK: - 저장소를 못 연 날
//
// 원래 저장소를 못 열면 이번 실행만 메모리에서 연다. 디스크의 기록은 건드리지 않는다.
// 예전에는 아무 말 없이 넘어가서, 사용자는 저장되는 줄 알고 계속 적었다 — 이제는 알린다.

enum StoreFallback {
    /// 이번 실행이 임시(메모리) 저장소로 열렸는가
    private(set) static var isActive = false

    static func memoryContainer(schema: Schema, after error: Error) -> ModelContainer {
        isActive = true
        print("⚠️ 저장소를 열지 못해 이번 실행은 메모리에서 엽니다: \(error)")
        do {
            return try ModelContainer(
                for: schema,
                configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            )
        } catch {
            // 메모리 저장소마저 안 되는 건 스키마 자체가 잘못된 것 — 개발 중에 바로 드러난다
            fatalError("메모리 저장소도 열지 못함: \(error)")
        }
    }
}

extension View {
    /// 임시 저장소로 열렸으면 한 번 알린다. 앱의 맨 바깥 화면에 붙인다.
    func storeFallbackNotice() -> some View {
        modifier(StoreFallbackNotice())
    }
}

private struct StoreFallbackNotice: ViewModifier {
    @State private var isPresented = StoreFallback.isActive

    func body(content: Content) -> some View {
        content.alert("기록을 열지 못했어요", isPresented: $isPresented) {
        } message: {
            Text("저장된 기록은 지워지지 않았어요. 다만 지금 적는 내용은 저장되지 않으니, 앱을 껐다 켜 보세요.")
        }
    }
}
