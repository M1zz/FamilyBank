//
//  OnboardingView.swift
//  쑥쑥용돈
//
//  최초 설정: 화폐 이름 → 부모 PIN → 가족 구성원 등록
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context

    @State private var step = 0
    @State private var currencyName = "코인"
    @State private var pin = ""
    @State private var pinConfirm = ""
    @State private var draftMembers: [DraftMember] = []
    @State private var errorMessage: String?

    struct DraftMember: Identifiable {
        let id = UUID()
        var name: String
        var emoji: String
        var role: MemberRole
    }

    var body: some View {
        NavigationStack {
            VStack {
                switch step {
                case 0: welcomeStep
                case 1: pinStep
                default: membersStep
                }
            }
            .padding()
            .navigationTitle("쑥쑥용돈 시작하기")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: 1단계 — 환영 + 화폐 이름

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("🌱")
                .font(.system(size: 72))
            Text("쑥쑥용돈에 오신 걸 환영해요!")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
            Text("용돈을 주고, 결제하고, 저축 이자를 받고,\n투자도 해 보는 우리 가족만의 경제 시스템이에요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 8) {
                Text("우리집 화폐 이름을 정해 주세요")
                    .font(.headline)
                TextField("예: 콩, 별, 코인", text: $currencyName)
                    .textFieldStyle(.roundedBorder)
                Text("예시: 1,000 \(currencyName.isEmpty ? "코인" : currencyName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .card()

            Spacer()
            Button {
                if currencyName.trimmingCharacters(in: .whitespaces).isEmpty {
                    currencyName = "코인"
                }
                step = 1
            } label: {
                Text("다음")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    // MARK: 2단계 — 부모 PIN

    private var pinStep: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("🔐")
                .font(.system(size: 64))
            Text("부모 모드 비밀번호(PIN)를 정해 주세요")
                .font(.title3.weight(.bold))
                .multilineTextAlignment(.center)
            Text("용돈 지급, 이자율 설정 등은\n이 PIN을 아는 사람만 할 수 있어요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                SecureField("숫자 4자리", text: $pin)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: pin) { _, v in pin = String(v.filter { $0.isNumber }.prefix(4)) }
                SecureField("한 번 더 입력", text: $pinConfirm)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: pinConfirm) { _, v in pinConfirm = String(v.filter { $0.isNumber }.prefix(4)) }
            }
            .card()

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()
            HStack {
                Button("이전") { step = 0 }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                Button {
                    guard pin.count == 4 else {
                        errorMessage = "PIN은 숫자 4자리여야 해요."
                        return
                    }
                    guard pin == pinConfirm else {
                        errorMessage = "두 번 입력한 PIN이 서로 달라요."
                        return
                    }
                    errorMessage = nil
                    step = 2
                } label: {
                    Text("다음").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    // MARK: 3단계 — 가족 구성원

    private var membersStep: some View {
        VStack(spacing: 16) {
            Text("👨‍👩‍👧‍👦")
                .font(.system(size: 56))
            Text("가족 구성원을 등록해 주세요")
                .font(.title3.weight(.bold))
            Text("부모는 은행(중앙은행) 역할, 자녀는 고객이 돼요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            List {
                ForEach(draftMembers) { m in
                    HStack {
                        Text(m.emoji)
                        Text(m.name)
                        Spacer()
                        Text(m.role.rawValue)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(m.role == .parent ? Color.indigo.opacity(0.15) : Color.green.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                .onDelete { draftMembers.remove(atOffsets: $0) }

                MemberQuickAddRow { name, emoji, role in
                    draftMembers.append(DraftMember(name: name, emoji: emoji, role: role))
                }
            }
            .listStyle(.insetGrouped)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Button("이전") { step = 1 }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                Button {
                    finishSetup()
                } label: {
                    Text("시작하기 🎉").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    private func finishSetup() {
        guard draftMembers.contains(where: { $0.role == .parent }) else {
            errorMessage = "부모를 한 명 이상 등록해 주세요."
            return
        }
        guard draftMembers.contains(where: { $0.role == .child }) else {
            errorMessage = "자녀를 한 명 이상 등록해 주세요."
            return
        }

        let settings = FamilySettings()
        settings.currencyName = currencyName.trimmingCharacters(in: .whitespaces)
        settings.parentPIN = pin
        settings.isSetupComplete = true
        context.insert(settings)

        for draft in draftMembers {
            let member = FamilyMember(name: draft.name, emoji: draft.emoji, role: draft.role)
            context.insert(member)
        }
        for product in BankEngine.defaultProducts() {
            context.insert(product)
        }
        try? context.save()
    }
}

// MARK: - 구성원 빠른 추가 행

struct MemberQuickAddRow: View {
    let onAdd: (String, String, MemberRole) -> Void

    @State private var name = ""
    @State private var emoji = "😀"
    @State private var role: MemberRole = .child

    private let emojis = ["😀", "😎", "🦖", "🐱", "🐶", "🦄", "👑", "🌟", "⚽️", "🎀", "👨", "👩"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("이름", text: $name)
                .textFieldStyle(.roundedBorder)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(emojis, id: \.self) { e in
                        Button {
                            emoji = e
                        } label: {
                            Text(e)
                                .font(.title2)
                                .padding(6)
                                .background(emoji == e ? Color.accentColor.opacity(0.2) : Color.clear)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Picker("역할", selection: $role) {
                ForEach(MemberRole.allCases) { r in
                    Text(r.rawValue).tag(r)
                }
            }
            .pickerStyle(.segmented)

            Button {
                let trimmed = name.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                onAdd(trimmed, emoji, role)
                name = ""
                role = .child
            } label: {
                Label("추가", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
    }
}
