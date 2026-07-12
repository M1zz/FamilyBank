//
//  ParentModeView.swift
//  FamilyBank — 우리집 은행
//
//  부모 모드: PIN 잠금 뒤에서 용돈 지급, 구성원/상품/설정 관리
//

import SwiftUI
import SwiftData

// MARK: - PIN 게이트

struct ParentGateView: View {
    @Bindable var settings: FamilySettings
    @State private var unlocked = false

    var body: some View {
        NavigationStack {
            if unlocked {
                ParentDashboardView(settings: settings, onLock: { unlocked = false })
            } else {
                PINEntryView(title: "부모 모드 PIN을 입력하세요", correctPIN: settings.parentPIN) {
                    unlocked = true
                }
                .navigationTitle("🔐 부모 모드")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

// MARK: - 부모 대시보드

struct ParentDashboardView: View {
    @Bindable var settings: FamilySettings
    let onLock: () -> Void

    @Environment(\.modelContext) private var context
    @Query(sort: \FamilyMember.createdAt) private var members: [FamilyMember]
    @Query(sort: \InvestProduct.createdAt) private var products: [InvestProduct]
    @Query(sort: \HouseholdItem.createdAt) private var storeItems: [HouseholdItem]

    @State private var showAddMember = false
    @State private var showAddProduct = false
    @State private var showAddItem = false
    @State private var showResetConfirm = false
    @State private var newPIN = ""
    @State private var inviteTarget: FamilyMember?

    private var children: [FamilyMember] { members.filter { $0.isChild } }

    var body: some View {
        Form {
            // 용돈 주기 / 차감
            Section("💸 돈 관리") {
                NavigationLink {
                    GiveMoneyView(settings: settings)
                } label: {
                    Label("용돈 주기 / 차감하기", systemImage: "gift.fill")
                }
            }

            // 구성원 관리
            Section("👨‍👩‍👧‍👦 가족 구성원") {
                ForEach(members) { member in
                    HStack {
                        Text(member.emoji)
                        Text(member.name)
                        Spacer()
                        Text(member.role.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if member.isChild {
                            Button {
                                inviteTarget = member
                            } label: {
                                Image(systemName: "paperplane.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.tint)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .onDelete { offsets in
                    for i in offsets {
                        context.delete(members[i])
                    }
                    try? context.save()
                }
                Button {
                    showAddMember = true
                } label: {
                    Label("구성원 추가", systemImage: "person.badge.plus")
                }
            }

            // 투자 상품 관리
            Section("📈 투자 상품") {
                ForEach(products) { product in
                    HStack {
                        Text(product.emoji)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(product.name)
                                .font(.subheadline)
                            Text("\(product.price.comma) · \(product.riskLabel)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { product.isActive },
                            set: { product.isActive = $0; try? context.save() }
                        ))
                        .labelsHidden()
                    }
                }
                .onDelete { offsets in
                    for i in offsets {
                        context.delete(products[i])
                    }
                    try? context.save()
                }
                Button {
                    showAddProduct = true
                } label: {
                    Label("상품 추가", systemImage: "plus.square.on.square")
                }
            }

            // 우리집 가게 관리
            Section("🏪 우리집 가게") {
                ForEach(storeItems) { item in
                    HStack {
                        Text(item.emoji)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.subheadline)
                            Text("\(item.priceWon.comma)원 → \(settings.coinPrice(forWon: item.priceWon).comma) \(settings.currencyName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { item.isActive },
                            set: { item.isActive = $0; try? context.save() }
                        ))
                        .labelsHidden()
                    }
                }
                .onDelete { offsets in
                    for i in offsets {
                        context.delete(storeItems[i])
                    }
                    try? context.save()
                }
                Button {
                    showAddItem = true
                } label: {
                    Label("물품 추가", systemImage: "tag.fill")
                }
            }

            // 은행 설정
            Section("⚙️ 은행 설정") {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("환율: 1 \(settings.currencyName) =")
                        TextField("10", text: Binding(
                            get: { String(Int(settings.wonPerCoin)) },
                            set: {
                                let won = Int($0.filter { $0.isNumber }) ?? 0
                                if won > 0 {
                                    settings.wonPerCoin = Double(won)
                                    try? context.save()
                                }
                            }
                        ))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 60)
                        Text("원")
                    }
                    Text("예: 실제 1,000원짜리 물건 = \(settings.coinPrice(forWon: 1000).comma) \(settings.currencyName). 가게 물품의 \(settings.currencyName) 가격이 이 환율로 자동 계산돼요.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("화폐 이름")
                    Spacer()
                    TextField("화폐 이름", text: Binding(
                        get: { settings.currencyName },
                        set: { settings.currencyName = $0; try? context.save() }
                    ))
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 120)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("주간 저축 이자율: \(settings.weeklyInterestRate.cleanPercent)%")
                    Slider(value: Binding(
                        get: { settings.weeklyInterestRate },
                        set: { settings.weeklyInterestRate = $0; try? context.save() }
                    ), in: 0...20, step: 0.5)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("주간 물가 상승률: \(settings.weeklyInflationRate.cleanPercent)%")
                    Slider(value: Binding(
                        get: { settings.weeklyInflationRate },
                        set: { settings.weeklyInflationRate = $0; try? context.save() }
                    ), in: 0...10, step: 0.5)
                    Text("매주 우리집 물가지수가 이만큼 올라요 (현재 지수 \(Int(settings.priceIndex.rounded()))). 0%로 두면 인플레이션이 없어요. 물가에 맞춰 실제 간식·장난감 가격도 조금씩 올려 주면 아이가 돈의 가치 변화를 몸으로 배워요.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("PIN 변경")
                    Spacer()
                    SecureField("새 PIN 4자리", text: $newPIN)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 120)
                        .onChange(of: newPIN) { _, v in
                            newPIN = String(v.filter { $0.isNumber }.prefix(4))
                        }
                    Button("저장") {
                        guard newPIN.count == 4 else { return }
                        settings.parentPIN = newPIN
                        newPIN = ""
                        try? context.save()
                    }
                    .disabled(newPIN.count != 4)
                }
            }

            // 초기화
            Section {
                Button(role: .destructive) {
                    showResetConfirm = true
                } label: {
                    Label("모든 데이터 초기화", systemImage: "trash.fill")
                }
            } footer: {
                Text("모든 구성원, 거래 기록, 투자 상품이 삭제되고 처음 설정 화면으로 돌아갑니다.")
            }
        }
        .navigationTitle("🏦 부모 모드")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onLock()
                } label: {
                    Label("잠그기", systemImage: "lock.fill")
                }
            }
        }
        .sheet(isPresented: $showAddMember) {
            AddMemberSheet(settings: settings)
        }
        .sheet(isPresented: $showAddProduct) {
            AddProductSheet()
        }
        .sheet(isPresented: $showAddItem) {
            AddStoreItemSheet(settings: settings)
        }
        .sheet(item: $inviteTarget) { member in
            InviteSheet(member: member, settings: settings)
        }
        .confirmationDialog("정말 모든 데이터를 삭제할까요?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("전부 삭제", role: .destructive) { resetAll() }
            Button("취소", role: .cancel) {}
        }
    }

    private func resetAll() {
        try? context.delete(model: MoneyTransaction.self)
        try? context.delete(model: Holding.self)
        try? context.delete(model: InvestProduct.self)
        try? context.delete(model: HouseholdItem.self)
        try? context.delete(model: FamilyMember.self)
        try? context.delete(model: FamilySettings.self)
        try? context.save()
    }
}

// MARK: - 용돈 주기 / 차감

struct GiveMoneyView: View {
    let settings: FamilySettings

    @Environment(\.modelContext) private var context
    @Query(sort: \FamilyMember.createdAt) private var members: [FamilyMember]

    @State private var selectedIndex = 0
    @State private var amountText = ""
    @State private var memo = ""
    @State private var mode: Mode = .give
    @State private var showResult = false
    @State private var resultMessage = ""

    enum Mode: String, CaseIterable {
        case give = "용돈 주기"
        case deduct = "차감하기"
    }

    private var children: [FamilyMember] { members.filter { $0.isChild } }
    private var amount: Int { Int(amountText) ?? 0 }
    private var target: FamilyMember? {
        children.indices.contains(selectedIndex) ? children[selectedIndex] : children.first
    }

    private let quickMemos = ["주간 용돈 📅", "심부름 🏃", "숙제 완료 📚", "청소 도움 🧹", "착한 일 💝"]

    var body: some View {
        Form {
            Section("누구에게?") {
                if children.isEmpty {
                    Text("등록된 자녀가 없어요")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("자녀", selection: $selectedIndex) {
                        ForEach(children.indices, id: \.self) { i in
                            Text("\(children[i].emoji) \(children[i].name)").tag(i)
                        }
                    }
                    .pickerStyle(.menu)
                    if let target {
                        HStack {
                            Text("현재 지갑")
                            Spacer()
                            Text("\(target.balance.comma) \(settings.currencyName)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("얼마나?") {
                Picker("종류", selection: $mode) {
                    ForEach(Mode.allCases, id: \.self) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)

                AmountField(placeholder: "금액", text: $amountText)

                HStack {
                    ForEach([500, 1000, 5000], id: \.self) { preset in
                        Button("+\(preset.comma)") {
                            amountText = "\((Int(amountText) ?? 0) + preset)"
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                }
            }

            Section("이유") {
                TextField("메모 (예: 주간 용돈)", text: $memo)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(quickMemos, id: \.self) { q in
                            Button(q) { memo = q }
                                .buttonStyle(.bordered)
                                .font(.caption)
                        }
                    }
                }
            }

            Section {
                Button {
                    perform()
                } label: {
                    Label(mode == .give ? "\(amount.comma) \(settings.currencyName) 주기" : "\(amount.comma) \(settings.currencyName) 차감",
                          systemImage: mode == .give ? "gift.fill" : "minus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .disabled(amount <= 0 || target == nil)
            }
        }
        .navigationTitle("💸 용돈 관리")
        .navigationBarTitleDisplayMode(.inline)
        .alert("알림", isPresented: $showResult) {
            Button("확인") {}
        } message: {
            Text(resultMessage)
        }
    }

    private func perform() {
        guard let target else { return }
        if mode == .give {
            BankEngine.give(to: target, amount: amount, memo: memo, context: context)
            resultMessage = "\(target.name)에게 \(amount.comma) \(settings.currencyName)을(를) 줬어요! 🎁"
            amountText = ""
        } else {
            let ok = BankEngine.deduct(from: target, amount: amount, memo: memo, context: context)
            resultMessage = ok
                ? "\(target.name)의 지갑에서 \(amount.comma) \(settings.currencyName)을(를) 차감했어요."
                : "\(target.name)의 지갑 잔액이 부족해요."
            if ok { amountText = "" }
        }
        showResult = true
    }
}

// MARK: - 구성원 추가 시트

struct AddMemberSheet: View {
    let settings: FamilySettings

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var emoji = "😀"
    @State private var role: MemberRole = .child
    /// 자녀 추가 완료 후 초대장을 보여줄 대상
    @State private var invitee: FamilyMember?

    private let emojis = ["😀", "😎", "🦖", "🐱", "🐶", "🦄", "👑", "🌟", "⚽️", "🎀", "👨", "👩"]

    var body: some View {
        NavigationStack {
            if let invitee {
                InviteCardView(member: invitee, settings: settings)
                    .navigationTitle("💌 초대장")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("완료") { dismiss() }
                        }
                    }
            } else {
                addForm
            }
        }
    }

    private var addForm: some View {
        Form {
            Section("이름") {
                TextField("이름", text: $name)
            }
            Section("이모지") {
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
            }
            Section("역할") {
                Picker("역할", selection: $role) {
                    ForEach(MemberRole.allCases) { r in
                        Text(r.rawValue).tag(r)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .navigationTitle("구성원 추가")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("추가") {
                    let trimmed = name.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    let member = FamilyMember(name: trimmed, emoji: emoji, role: role)
                    context.insert(member)
                    try? context.save()
                    if member.isChild {
                        invitee = member  // 자녀면 바로 초대장으로
                    } else {
                        dismiss()
                    }
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }
}

// MARK: - 가게 물품 추가 시트

struct AddStoreItemSheet: View {
    let settings: FamilySettings

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var emoji = "🛒"
    @State private var priceText = "1000"

    private let emojis = ["🛒", "🥤", "🍪", "🍦", "🍕", "🧸", "🎮", "📺", "📚", "🎬", "🍿", "⚽️"]
    private var priceWon: Int { Int(priceText) ?? 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("물품 정보") {
                    TextField("물품 이름 (예: 콜라, 게임 30분)", text: $name)
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
                }
                Section("실제 가격 (원)") {
                    AmountField(placeholder: "실제 세상 가격", text: $priceText)
                    if priceWon > 0 {
                        HStack {
                            Text("우리집 가격")
                            Spacer()
                            Text("\(settings.coinPrice(forWon: priceWon).comma) \(settings.currencyName)")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.tint)
                        }
                        Text("환율 1 \(settings.currencyName) = \(Int(settings.wonPerCoin).comma)원 기준으로 자동 계산돼요.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("물품 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty, priceWon > 0 else { return }
                        context.insert(HouseholdItem(name: trimmed, emoji: emoji, priceWon: priceWon))
                        try? context.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || priceWon <= 0)
                }
            }
        }
    }
}

// MARK: - 투자 상품 추가 시트

struct AddProductSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var emoji = "📈"
    @State private var detail = ""
    @State private var priceText = "1000"
    @State private var riskLevel: RiskLevel = .medium

    enum RiskLevel: String, CaseIterable {
        case low = "안정형 🐢"
        case medium = "보통형 🐰"
        case high = "위험형 🚀"

        var volatility: Double {
            switch self {
            case .low: return 0.02
            case .medium: return 0.06
            case .high: return 0.15
            }
        }
        var trend: Double {
            switch self {
            case .low: return 0.10
            case .medium: return 0.15
            case .high: return 0.20
            }
        }
    }

    private let emojis = ["📈", "🐢", "🐰", "🚀", "🌳", "⭐️", "🏠", "🍎", "🤖", "🎮"]

    var body: some View {
        NavigationStack {
            Form {
                Section("상품 정보") {
                    TextField("상품 이름 (예: 별빛 펀드)", text: $name)
                    TextField("설명 (선택)", text: $detail)
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
                }
                Section("시작 가격") {
                    AmountField(placeholder: "1주 가격", text: $priceText)
                }
                Section("위험도") {
                    Picker("위험도", selection: $riskLevel) {
                        ForEach(RiskLevel.allCases, id: \.self) { r in
                            Text(r.rawValue).tag(r)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text(riskDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("투자 상품 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        let price = max(10, Int(priceText) ?? 1000)
                        guard !trimmed.isEmpty else { return }
                        let product = InvestProduct(
                            name: trimmed,
                            emoji: emoji,
                            detail: detail.isEmpty ? "우리집 투자 상품이에요." : detail,
                            price: price,
                            volatility: riskLevel.volatility,
                            trend: riskLevel.trend
                        )
                        context.insert(product)
                        try? context.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var riskDescription: String {
        switch riskLevel {
        case .low: return "하루 ±2% 정도로 조금씩 움직여요. 잃을 걱정이 적어요."
        case .medium: return "하루 ±6% 정도로 오르내려요. 적당한 도전이에요."
        case .high: return "하루 ±15%까지 크게 움직여요! 크게 벌 수도, 잃을 수도 있어요."
        }
    }
}
