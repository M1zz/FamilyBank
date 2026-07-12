//
//  RootView.swift
//  FamilyBank — 우리집 은행
//

import SwiftUI
import SwiftData

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

    var body: some View {
        TabView {
            HomeView(settings: settings)
                .tabItem { Label("대시보드", systemImage: "chart.bar.fill") }

            ParentActionsView(settings: settings)
                .tabItem { Label("액션", systemImage: "bolt.fill") }

            MarketView(settings: settings)
                .tabItem { Label("시장", systemImage: "chart.line.uptrend.xyaxis") }

            HistoryView(settings: settings)
                .tabItem { Label("기록", systemImage: "list.bullet.rectangle.fill") }

            EducationView(settings: settings)
                .tabItem { Label("배우기", systemImage: "graduationcap.fill") }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [FamilyMember.self, MoneyTransaction.self, InvestProduct.self, Holding.self, HouseholdItem.self, FamilySettings.self], inMemory: true)
}
