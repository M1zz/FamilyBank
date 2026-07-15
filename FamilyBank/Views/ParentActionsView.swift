//
//  ParentActionsView.swift
//  쑥쑥용돈
//
//  액션 탭: PIN 잠금 뒤에서 부모가 자주 하는 일을 큰 버튼으로 빠르게
//

import SwiftUI
import SwiftData
import LocalAuthentication

struct ParentActionsView: View {
    @Bindable var settings: FamilySettings
    @State private var unlocked = false
    @State private var didAutoPrompt = false

    /// 기기에서 Face ID/Touch ID를 쓸 수 있는지
    private var biometryAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    private var biometryLabel: String {
        LAContext().biometryType == .touchID ? "Touch ID로 열기" : "Face ID로 열기"
    }

    var body: some View {
        NavigationStack {
            if unlocked {
                ActionGridView(settings: settings, onLock: { unlocked = false; didAutoPrompt = false })
            } else {
                VStack(spacing: 16) {
                    PINEntryView(title: "부모 확인이 필요해요", correctPIN: settings.parentPIN) {
                        unlocked = true
                    }
                    if biometryAvailable {
                        Button {
                            authenticateWithBiometrics()
                        } label: {
                            Label(biometryLabel, systemImage: "faceid")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .navigationTitle("⚡️ 액션")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    // 잠금 화면이 뜨면 한 번 자동으로 Face ID 시도
                    guard !didAutoPrompt else { return }
                    didAutoPrompt = true
                    authenticateWithBiometrics()
                }
            }
        }
    }

    /// 기기 암호가 아닌 생체 인증만 사용 — 실패하면 앱의 부모 PIN으로 폴백
    private func authenticateWithBiometrics() {
        let context = LAContext()
        context.localizedCancelTitle = "PIN 입력"
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else { return }
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                               localizedReason: "부모 확인을 위해 사용해요") { success, _ in
            if success {
                DispatchQueue.main.async { unlocked = true }
            }
        }
    }
}

// MARK: - 액션 버튼 그리드

struct ActionGridView: View {
    @Bindable var settings: FamilySettings
    let onLock: () -> Void

    @Environment(\.modelContext) private var context
    @Query(sort: \FamilyMember.createdAt) private var members: [FamilyMember]
    @Query(sort: \HouseholdItem.createdAt) private var storeItems: [HouseholdItem]

    @State private var showBarcodeList = false
    @State private var showAddItem = false
    @State private var showAddMember = false
    @State private var showInvitePicker = false
    @State private var showKidModePicker = false
    @State private var inviteTarget: FamilyMember?
    @State private var kidModeCandidate: FamilyMember?
    @AppStorage(KidModeStorage.key) private var kidModeUID = ""

    private var children: [FamilyMember] { members.filter { $0.isChild } }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                NavigationLink {
                    GiveMoneyView(settings: settings)
                } label: {
                    actionCard("💸", "용돈 주기", "지급 · 차감", .pink)
                }
                .buttonStyle(.plain)

                Button {
                    showBarcodeList = true
                } label: {
                    actionCard("🏷️", "물품 바코드", "찍으면 바로 결제", .orange)
                }
                .buttonStyle(.plain)

                Button {
                    showAddItem = true
                } label: {
                    actionCard("🏪", "물품 추가", "가게에 등록", .green)
                }
                .buttonStyle(.plain)

                Button {
                    showInvitePicker = true
                } label: {
                    actionCard("💌", "자녀 초대", "초대장 · QR", .blue)
                }
                .buttonStyle(.plain)

                Button {
                    showKidModePicker = true
                } label: {
                    actionCard("📱", "자녀 폰 모드", "이 기기 건네주기", .purple)
                }
                .buttonStyle(.plain)

                Button {
                    showAddMember = true
                } label: {
                    actionCard("👨‍👩‍👧‍👦", "구성원 추가", "가족 등록", .teal)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    ParentDashboardView(settings: settings, onLock: onLock)
                } label: {
                    actionCard("⚙️", "은행 설정", "이자 · 환율 · 물가", .gray)
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("⚡️ 액션")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onLock()
                } label: {
                    Label("잠그기", systemImage: "lock.fill")
                }
            }
        }
        .sheet(isPresented: $showBarcodeList) {
            ItemBarcodeListSheet(settings: settings)
        }
        .sheet(isPresented: $showAddItem) {
            AddStoreItemSheet(settings: settings)
        }
        .sheet(isPresented: $showAddMember) {
            AddMemberSheet(settings: settings)
        }
        .sheet(item: $inviteTarget) { member in
            InviteSheet(member: member, settings: settings)
        }
        .confirmationDialog("누구를 초대할까요?", isPresented: $showInvitePicker, titleVisibility: .visible) {
            ForEach(children) { child in
                Button("\(child.emoji) \(child.name)") { inviteTarget = child }
            }
            Button("취소", role: .cancel) {}
        }
        .confirmationDialog("이 기기를 누구의 폰으로 만들까요? 되돌리려면 부모 PIN이 필요해요.",
                            isPresented: $showKidModePicker, titleVisibility: .visible) {
            ForEach(children) { child in
                Button("\(child.emoji) \(child.name)") { activateKidMode(child) }
            }
            Button("취소", role: .cancel) {}
        }
    }

    private func activateKidMode(_ child: FamilyMember) {
        if child.uid.isEmpty {
            child.uid = UUID().uuidString
            try? context.save()
        }
        kidModeUID = child.uid
    }

    private func actionCard(_ emoji: String, _ title: String, _ subtitle: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(emoji)
                .font(.system(size: 34))
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
