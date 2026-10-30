//
//  KidModeView.swift
//  쑥쑥용돈
//
//  자녀 폰 모드: 이 기기를 특정 자녀의 전용 화면으로 전환.
//  자기 지갑·투자·기록·배우기만 보이고, 벗어나려면 부모 PIN이 필요하다.
//

import SwiftUI
import SwiftData
import LeeoKit

/// 기기별 저장 키 — iCloud 동기화되지 않는 이 기기만의 설정
enum KidModeStorage {
    static let key = "kidModeUID"
}

struct KidTabView: View {
    @Bindable var member: FamilyMember
    let settings: FamilySettings

    @AppStorage(KidModeStorage.key) private var kidModeUID = ""
    @State private var showUnlock = false
    @State private var tab = 0

    private var wallet: some View {
        NavigationStack {
            MemberDetailView(member: member, settings: settings)
                .navigationTitle("\(member.emoji) \(member.name)의 은행")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showUnlock = true
                        } label: {
                            Label("부모 모드", systemImage: "lock.fill")
                        }
                    }
                }
        }
    }

    var body: some View {
        // 아이폰 듀오를 펴면 고르는 쪽에 고른 탭, 결과 쪽에 내 지갑 (→ FoldPanes.swift).
        TabView(selection: $tab) {
            wallet
                .tabItem { Label("내 지갑", systemImage: "wallet.pass.fill") }
                .tag(0)

            FoldTab { MarketView(settings: settings, embedInvest: false) } result: { wallet }
                .tabItem { Label("시장", systemImage: "chart.bar.xaxis") }
                .tag(1)

            FoldTab { InvestTabView(settings: settings, fixedInvestor: member) } result: { wallet }
                .tabItem { Label("투자", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(2)

            FoldTab { HistoryView(settings: settings, fixedMember: member) } result: { wallet }
                .tabItem { Label("내 기록", systemImage: "list.bullet.rectangle.fill") }
                .tag(3)

            FoldTab { EducationView(settings: settings) } result: { wallet }
                .tabItem { Label("배우기", systemImage: "graduationcap.fill") }
                .tag(4)
        }
        // 펴면 시스템 탭바 대신 고르는 쪽 판 바닥에 막대가 선다. 내 지갑은 늘 결과 쪽 판에 있어 빠진다.
        .foldTabBar(items: [
            .init(value: 1, title: String(localized: "시장"), symbol: "chart.bar.xaxis"),
            .init(value: 2, title: String(localized: "투자"), symbol: "chart.line.uptrend.xyaxis"),
            .init(value: 3, title: String(localized: "내 기록"), symbol: "list.bullet.rectangle.fill"),
            .init(value: 4, title: String(localized: "배우기"), symbol: "graduationcap.fill"),
        ], selected: tab == 0 ? 1 : tab) { tab = $0 }
        .foldResultTabRedirect($tab, resultTab: 0, fallback: 1)
        .sheet(isPresented: $showUnlock) {
            NavigationStack {
                PINEntryView(title: String(localized: "부모님 확인이 필요해요"), correctPIN: settings.parentPIN) {
                    showUnlock = false
                    kidModeUID = ""  // 자녀 폰 모드 해제 → 전체 화면으로 복귀
                }
                .navigationTitle("🔐 부모 모드로 돌아가기")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("취소", systemImage: "xmark") { showUnlock = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}
