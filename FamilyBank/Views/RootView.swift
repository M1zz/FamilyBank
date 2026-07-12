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

    var body: some View {
        Group {
            if let settings = settingsList.first, settings.isSetupComplete {
                MainTabView(settings: settings)
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
    let settings: FamilySettings

    var body: some View {
        TabView {
            HomeView(settings: settings)
                .tabItem { Label("홈", systemImage: "house.fill") }

            InvestTabView(settings: settings)
                .tabItem { Label("투자", systemImage: "chart.line.uptrend.xyaxis") }

            HistoryView(settings: settings)
                .tabItem { Label("기록", systemImage: "list.bullet.rectangle.fill") }

            EducationView(settings: settings)
                .tabItem { Label("배우기", systemImage: "graduationcap.fill") }

            ParentGateView(settings: settings)
                .tabItem { Label("부모", systemImage: "person.2.badge.key.fill") }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [FamilyMember.self, MoneyTransaction.self, InvestProduct.self, Holding.self, HouseholdItem.self, FamilySettings.self], inMemory: true)
}
