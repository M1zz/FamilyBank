//
//  KidModeView.swift
//  FamilyBank — 우리집 은행
//
//  자녀 폰 모드: 이 기기를 특정 자녀의 전용 화면으로 전환.
//  자기 지갑·투자·기록·배우기만 보이고, 벗어나려면 부모 PIN이 필요하다.
//

import SwiftUI
import SwiftData

/// 기기별 저장 키 — iCloud 동기화되지 않는 이 기기만의 설정
enum KidModeStorage {
    static let key = "kidModeUID"
}

struct KidTabView: View {
    @Bindable var member: FamilyMember
    let settings: FamilySettings

    @AppStorage(KidModeStorage.key) private var kidModeUID = ""
    @State private var showUnlock = false

    var body: some View {
        TabView {
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
            .tabItem { Label("내 지갑", systemImage: "wallet.pass.fill") }

            MarketView(settings: settings, embedInvest: false)
                .tabItem { Label("시장", systemImage: "chart.bar.xaxis") }

            InvestTabView(settings: settings, fixedInvestor: member)
                .tabItem { Label("투자", systemImage: "chart.line.uptrend.xyaxis") }

            HistoryView(settings: settings, fixedMember: member)
                .tabItem { Label("내 기록", systemImage: "list.bullet.rectangle.fill") }

            EducationView(settings: settings)
                .tabItem { Label("배우기", systemImage: "graduationcap.fill") }
        }
        .sheet(isPresented: $showUnlock) {
            NavigationStack {
                PINEntryView(title: "부모님 확인이 필요해요", correctPIN: settings.parentPIN) {
                    showUnlock = false
                    kidModeUID = ""  // 자녀 폰 모드 해제 → 전체 화면으로 복귀
                }
                .navigationTitle("🔐 부모 모드로 돌아가기")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("취소") { showUnlock = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}
