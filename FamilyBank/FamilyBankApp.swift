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
    @Environment(\.scenePhase) private var scenePhase

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
        // iCloud 로 기기 간 기록을 맞추는 것은 Pro 다(→ ProEntitlement.syncsWithICloud).
        // 칸이 바뀌면 다음 실행부터 따른다. 끄더라도 기기 안 기록은 그대로 남는다.
        let syncs = ProEntitlement.syncsWithICloud
        do {
            let config = ModelConfiguration(schema: schema, cloudKitDatabase: syncs ? .automatic : .none)
            container = try ModelContainer(for: schema, configurations: [config])
            CloudSync.isOn = syncs
        } catch {
            // iCloud 설정이 안 되어 있으면 기기 로컬 저장으로 자동 전환
            do {
                let localConfig = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
                container = try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                container = StoreFallback.memoryContainer(schema: schema, after: error)
            }
        }
        // 페이월이 생긴 버전을 처음 켤 때 이미 가족 장부가 있었으면, 페이월 전부터 쓰던 가족이다(Pro 평생).
        // 임시 저장소로 열린 날은 장부가 안 보일 뿐이라 세지 않는다.
        if !StoreFallback.isActive {
            let context = container.mainContext
            ProEntitlement.noteFamilyBeforePaywall {
                ((try? context.fetchCount(FetchDescriptor<FamilySettings>())) ?? 0) > 0
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
            WidePadPanes { RootView() }
                .leeoSatisfactionCheck(FamilyBankSpec.self)
                // 개발자가 보낸 의견에 답장하면, 앱이 앞으로 올 때 답장을 시트로 보여 준다 (LeeoKit).
                .leeoFeedbackReplyNotice(FamilyBankSpec.self)
                .storeFallbackNotice()
                // 영수증을 읽어 칸을 정한다. 팁 상품과 끝나지 않은 팁은 LeeoStore 가 함께 챙긴다.
                .task { await PurchaseManager.shared.refresh() }
                // 창 크기로 접힘을 재서 아래로 흘린다. 시트 · 알림창도 접힌 선을 비킨다 (LeeoKit Fold).
                .foldAware()
                // Spotlight 에 싣는 아이 목록을 지금 것에 맞춘다. 열 때 한 번, 뒤로 보낼 때마다.
                .task { await FamilyBankLibrary.reindex(container) }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .background { Task { await FamilyBankLibrary.reindex(container) } }
                    if phase == .active { Task { await PurchaseManager.shared.refresh() } }
                }
        }
        .modelContainer(container)
    }
}

// MARK: - iCloud 동기화

enum CloudSync {
    /// 이번 실행의 저장소가 iCloud 로 맞추는가. 칸이 바뀌어도 다음 실행까지는 그대로다.
    static var isOn = false
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
