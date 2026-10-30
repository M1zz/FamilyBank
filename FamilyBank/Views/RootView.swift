//
//  RootView.swift
//  쑥쑥용돈
//

import SwiftUI
import SwiftData
import LeeoKit

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase

    @Query(sort: \FamilySettings.createdAt) private var settingsList: [FamilySettings]
    @Query private var members: [FamilyMember]
    @Query private var products: [InvestProduct]

    /// 이 기기가 자녀 폰 모드인지 (기기별 설정, 동기화 안 됨)
    @AppStorage(KidModeStorage.key) private var kidModeUID = ""

    private var kidModeMember: FamilyMember? {
        guard !kidModeUID.isEmpty else { return nil }
        return members.first { $0.isChild && $0.uid == kidModeUID }
    }

    var body: some View {
        Group {
            if let settings = settingsList.first, settings.isSetupComplete {
                if let kid = kidModeMember {
                    KidTabView(member: kid, settings: settings)
                } else {
                    MainTabView(settings: settings)
                }
            } else {
                OnboardingView()
                    // 아이폰 듀오를 펴도 처음 설정이 접힌 선을 넘지 않게 고르는 쪽 판에
                    .foldConfined()
            }
        }
        .dismissKeyboardOnTap()
        .onAppear { tick() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { tick() }
        }
    }

    /// 밀린 이자·시세를 반영
    private func tick() {
        guard let settings = settingsList.first, settings.isSetupComplete else { return }
        BankEngine.processTick(members: members, products: products, settings: settings, context: context)
    }
}

// MARK: - 메인 탭

struct MainTabView: View {
    @Bindable var settings: FamilySettings
    @State private var tab = ScreenshotDemo.startTab

    var body: some View {
        // 아이폰 듀오를 펴면 고르는 쪽에 고른 탭, 결과 쪽에 대시보드 (→ FoldPanes.swift).
        TabView(selection: $tab) {
            HomeView(settings: settings)
                .tabItem { Label("대시보드", systemImage: "chart.bar.fill") }
                .tag(0)

            FoldTab { ParentActionsView(settings: settings) } result: { dashboard }
                .tabItem { Label("액션", systemImage: "bolt.fill") }
                .tag(1)

            FoldTab { MarketView(settings: settings) } result: { dashboard }
                .tabItem { Label("시장", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(2)

            FoldTab { HistoryView(settings: settings) } result: { dashboard }
                .tabItem { Label("기록", systemImage: "list.bullet.rectangle.fill") }
                .tag(3)

            FoldTab { EducationView(settings: settings) } result: { dashboard }
                .tabItem { Label("배우기", systemImage: "graduationcap.fill") }
                .tag(4)
        }
        // 펴면 시스템 탭바 대신 고르는 쪽 판 바닥에 막대가 선다. 대시보드는 늘 결과 쪽 판에 있어 빠진다.
        .foldTabBar(items: [
            .init(value: 1, title: String(localized: "액션"), symbol: "bolt.fill"),
            .init(value: 2, title: String(localized: "시장"), symbol: "chart.line.uptrend.xyaxis"),
            .init(value: 3, title: String(localized: "기록"), symbol: "list.bullet.rectangle.fill"),
            .init(value: 4, title: String(localized: "배우기"), symbol: "graduationcap.fill"),
        ], selected: tab == 0 ? 1 : tab) { tab = $0 }
        .foldResultTabRedirect($tab, resultTab: 0, fallback: 1)
    }

    private var dashboard: HomeView { HomeView(settings: settings) }
}

#Preview {
    RootView()
        .modelContainer(for: [FamilyMember.self, MoneyTransaction.self, InvestProduct.self, Holding.self, HouseholdItem.self, FamilySettings.self], inMemory: true)
}
