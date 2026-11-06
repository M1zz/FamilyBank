//
//  PaywallView.swift
//  쑥쑥용돈
//
//  Plus · Pro 를 파는 한 장. 칸 카드 둘(칸마다 연 구독 / 평생, 주 · 월은 펼쳐서) → 세 칸 비교표 → 약관.
//
//  ⚠️ 페이월은 늘 부모 모드(PIN) 안에서만 띄운다. 자녀 폰 모드에서는 어떤 경우에도 뜨지 않는다.
//  ⚠️ 스토어에 아직 없는 상품은 불러와지지 않는다. 그 단추는 서지 않는다(없는 것을 팔지 않는다).
//  첫 해 할인(App Store 첫 구독 할인)과 "연 구독 N년치" 한 줄은 `LeeoTermPicker` 가 알아서 보인다.
//

import SwiftUI
import StoreKit
import LeeoKit
import SwiftData

struct PaywallView: View {
    /// 어디서 들어왔는가. 그 기능이 든 칸을 맨 위에 세우고 강조한다.
    var highlight: ProFeature?
    /// 처음 고를 길. 오래 쓸 가족이 많은 자리(바코드 결제)나 '평생으로 바꾸기'에서는 평생.
    var term: LeeoPlanTerm = .yearly

    @State private var purchases = PurchaseManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    /// 결제 시트를 **이 페이월이 떠 있는 창**에 띄운다.
    @Environment(\.purchase) private var purchaseAction

    @State private var plusTerm: LeeoPlanTerm = .yearly
    @State private var proTerm: LeeoPlanTerm = .yearly
    @State private var loadingProducts = true
    @State private var redeemingCode = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    plansStatus
                    ForEach(tierOrder, id: \.self) { tierCard($0) }
                    PlanComparisonTable()
                    if let message = purchases.failureMessage, !purchases.products.isEmpty {
                        Label(message, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                    legal
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("요금제")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("복원") { Task { await restore() } }
                        .disabled(purchases.isWorking)
                }
            }
            .offerCodeRedemption(isPresented: $redeemingCode) { _ in
                Task {
                    await purchases.refresh()
                    if purchases.tier > .free { dismiss() }
                }
            }
            .task {
                switch highlight?.tier {
                case .pro?: proTerm = term
                case .plus?: plusTerm = term
                default: plusTerm = term; proTerm = term
                }
                LeeoAnalyticsCenter.track(.paywallShown(reason: highlight?.rawValue ?? "settings"))
                await loadPlans()
            }
        }
    }

    /// 들어온 기능의 칸을 앞에.
    private var tierOrder: [ProTier] { highlight?.tier == .pro ? [.pro, .plus] : [.plus, .pro] }

    // MARK: 머리

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("쑥쑥용돈 Plus · Pro")
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
            Text("우리집 은행을 더 크게, 더 진짜처럼. 연 구독이나 평생 중에 고르세요.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Label("가족 공유로 가족 모두의 Apple 계정에서 함께 열려요.", systemImage: "person.2.fill")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: 칸

    private func tierCard(_ tier: ProTier) -> some View {
        let highlighted = highlight?.tier == tier && purchases.tier < tier
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(tier.title)
                    .font(.title3.bold())
                    .accessibilityAddTraits(.isHeader)
                if purchases.tier == tier {
                    Text("지금 쓰는 칸")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.tint)
                }
                Spacer(minLength: 0)
            }
            Text(tier.tagline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if tier == .pro {
                featureRow(systemImage: "square.stack.3d.up.fill", title: String(localized: "Plus의 모든 것"), note: nil)
            }
            ForEach(features(in: tier)) { feature in
                featureRow(systemImage: feature.systemImage, title: feature.title, note: feature.note,
                           highlighted: feature == highlight)
            }
            // 스토어에서 불러온 상품이 있을 때만 고르기와 구매 단추를 세운다.
            if purchases.canBuy(tier) && (yearly(tier) != nil || lifetime(tier) != nil) {
                LeeoTermPicker(term: termBinding(tier), yearly: yearly(tier), lifetime: lifetime(tier))
                    .padding(.top, 4)
                buyButton(tier)
                shortPlans(tier)
            }
        }
        .card()
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(highlighted ? Color.accentColor : .clear, lineWidth: 2)
        }
    }

    /// 그 칸에서 새로 열리는 것. 지금 누른 자리가 맨 위.
    private func features(in tier: ProTier) -> [ProFeature] {
        let opened = ProFeature.opened(by: tier)
        guard let highlight, opened.contains(highlight) else { return opened }
        return [highlight] + opened.filter { $0 != highlight }
    }

    private func featureRow(systemImage: String, title: String, note: String?, highlighted: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(highlighted ? Color.accentColor : .secondary)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.semibold))
                if let note {
                    Text(note)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: 상품

    private func termBinding(_ tier: ProTier) -> Binding<LeeoPlanTerm> {
        tier == .plus ? $plusTerm : $proTerm
    }

    private func yearly(_ tier: ProTier) -> Product? {
        purchases.product(tier == .plus ? ProEntitlement.plusYearlyID : ProEntitlement.proYearlyID)
    }

    /// 칸의 평생. **Plus 평생을 이미 산 사람에게는 Pro 평생 자리에 올리기 상품을 세운다.**
    private func lifetime(_ tier: ProTier) -> Product? {
        if tier == .plus { return purchases.product(ProEntitlement.plusLifetimeID) }
        return purchases.product(upgradesToPro ? ProEntitlement.upgradeID : ProEntitlement.proLifetimeID)
    }

    private var upgradesToPro: Bool { purchases.ownsLifetime(.plus) }

    private func buyButton(_ tier: ProTier) -> some View {
        let chosen = termBinding(tier).wrappedValue
        let product = chosen == .yearly ? yearly(tier) : lifetime(tier)
        let title: String = switch chosen {
        case .yearly: String(localized: "연 구독 시작")
        case .lifetime where tier == .pro && upgradesToPro: String(localized: "Pro 평생으로 올리기")
        case .lifetime: String(localized: "평생으로 사기")
        }
        return Button {
            guard let product else { return }
            Task { await buy(product, opening: tier) }
        } label: {
            Group {
                if purchases.isWorking {
                    ProgressView().tint(.white)
                } else {
                    Text(title).font(.headline)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 32)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(purchases.isWorking || product.map { purchases.owns($0.id) } ?? true)
    }

    /// 주 · 월 구독. 연이 기본이고, 짧게 써 보고 싶은 가족에게만 펼쳐 보인다. 스토어에 없으면 줄째 숨는다.
    @ViewBuilder
    private func shortPlans(_ tier: ProTier) -> some View {
        let weekly = purchases.product(tier == .plus ? ProEntitlement.plusWeeklyID : ProEntitlement.proWeeklyID)
        let monthly = purchases.product(tier == .plus ? ProEntitlement.plusMonthlyID : ProEntitlement.proMonthlyID)
        if weekly != nil || monthly != nil {
            DisclosureGroup("주간 · 월간으로 보기") {
                VStack(spacing: 8) {
                    if let weekly { shortPlanButton(weekly, tier, title: String(localized: "주간 \(weekly.displayPrice)")) }
                    if let monthly { shortPlanButton(monthly, tier, title: String(localized: "월간 \(monthly.displayPrice)")) }
                }
                .padding(.top, 8)
            }
        }
    }

    private func shortPlanButton(_ product: Product, _ tier: ProTier, title: String) -> some View {
        Button {
            Task { await buy(product, opening: tier) }
        } label: {
            Text(title)
                .monospacedDigit()
                .frame(maxWidth: .infinity, minHeight: 32)
        }
        .buttonStyle(.bordered)
        .disabled(purchases.isWorking || purchases.owns(product.id))
    }

    private func buy(_ product: Product, opening tier: ProTier) async {
        await purchases.purchase(product, using: purchaseAction)
        if purchases.tier >= tier { dismiss() }
    }

    private func restore() async {
        await purchases.restore()
        if purchases.tier > .free { dismiss() }
    }

    // MARK: 불러오기

    @ViewBuilder
    private var plansStatus: some View {
        if purchases.products.isEmpty && loadingProducts {
            HStack(spacing: 10) {
                ProgressView()
                Text("요금제를 불러오는 중…").foregroundStyle(.secondary)
            }
        } else if purchases.products.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("요금제를 불러오지 못했어요. 인터넷 연결을 확인하고 다시 불러와 주세요.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    Task { await loadPlans() }
                } label: {
                    Label("다시 불러오기", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    /// 샌드박스(심사 환경)는 첫 조회가 빈손으로 돌아오는 일이 잦아 한 번 더 청한다.
    private func loadPlans() async {
        loadingProducts = true
        await purchases.loadProducts()
        if purchases.products.isEmpty {
            try? await Task.sleep(for: .seconds(1.5))
            await purchases.loadProducts()
        }
        loadingProducts = false
    }

    // MARK: 약관 (구독을 파는 앱의 심사 필수 항목)

    private var legal: some View {
        VStack(alignment: .leading, spacing: 12) {
            if purchases.products.contains(where: { $0.subscription != nil }) {
                Text("구독은 기간이 끝나기 24시간 전까지 해지하지 않으면 같은 값으로 자동 갱신되고, Apple 계정으로 결제돼요. 연 구독을 처음 시작하면 첫 해는 할인된 값으로, 그 뒤로는 정가로 갱신돼요. 해지와 관리는 App Store 계정 설정에서 할 수 있어요. 평생은 구독이 아니라 한 번만 결제해요.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ViewThatFits {
                HStack(spacing: 20) { legalButtons }
                VStack(alignment: .leading, spacing: 12) { legalButtons }
            }
        }
    }

    @ViewBuilder
    private var legalButtons: some View {
        if let terms = FamilyBankSpec.monetization.subscriptionTermsURL {
            Button("이용약관") { openURL(terms) }
        }
        Button("개인정보 처리방침") { openURL(FamilyBankSpec.legal.privacyURL) }
        Button("구매 복원") { Task { await restore() } }
            .disabled(purchases.isWorking)
        Button("코드 사용") { redeemingCode = true }
            .disabled(purchases.isWorking)
    }
}

// MARK: - 세 칸 비교표

/// 페이월에 그대로 서는 표. 무료로 되는 것을 먼저 말한다.
struct PlanComparisonTable: View {
    private enum Cell {
        case yes, no, text(String)
    }

    private struct Row: Identifiable {
        let label: String
        let cells: [Cell]   // 무료 · Plus · Pro
        var id: String { label }
    }

    @Environment(\.dynamicTypeSize) private var typeSize

    private var rows: [Row] {
        let unlimited = String(localized: "무제한")
        let custom = String(localized: "직접 만들기")
        return [
            Row(label: String(localized: "우리집 화폐 · 용돈 지급 · 차감"), cells: [.yes, .yes, .yes]),
            Row(label: String(localized: "저축 이자 · 이자율 정하기"), cells: [.yes, .yes, .yes]),
            Row(label: String(localized: "거래 기록 · 경제 배우기"), cells: [.yes, .yes, .yes]),
            Row(label: String(localized: "부모 모드 PIN · 자녀 폰 모드 · 초대장"), cells: [.yes, .yes, .yes]),
            Row(label: String(localized: "자녀"),
                cells: [.text(String(localized: "\(ProEntitlement.freeChildLimit)명")), .text(unlimited), .text(unlimited)]),
            Row(label: String(localized: "우리집 가게 물품"),
                cells: [.text(String(localized: "\(ProEntitlement.freeItemLimit)개")), .text(unlimited), .text(unlimited)]),
            Row(label: String(localized: "투자 상품"),
                cells: [.text(String(localized: "기본 3종")), .text(custom), .text(custom)]),
            Row(label: ProFeature.barcodePay.title, cells: [.no, .no, .yes]),
            Row(label: ProFeature.inflation.title, cells: [.no, .no, .yes]),
            Row(label: ProFeature.iCloudSync.title, cells: [.no, .no, .yes]),
        ]
    }

    private let tiers: [ProTier] = [.free, .plus, .pro]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("한눈에 비교")
                .font(.title3.bold())
                .accessibilityAddTraits(.isHeader)
            if typeSize.isAccessibilitySize {
                stacked
            } else {
                grid
            }
        }
        .card()
    }

    /// 보통 글자: 네 칸 표.
    private var grid: some View {
        Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
            GridRow {
                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                ForEach(tiers, id: \.self) { tier in
                    Text(shortName(tier))
                        .font(.body.weight(.semibold))
                        .gridColumnAlignment(.center)
                }
            }
            .accessibilityHidden(true)
            ForEach(rows) { row in
                Divider()
                GridRow {
                    Text(row.label)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(Array(row.cells.enumerated()), id: \.offset) { _, cell in
                        cellView(cell)
                            .frame(minWidth: 56)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(spoken(row))
            }
        }
    }

    /// 아주 큰 글자: 줄마다 위아래로.
    private var stacked: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(rows) { row in
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.label).font(.body.weight(.semibold))
                    ForEach(Array(zip(tiers, row.cells)), id: \.0) { tier, cell in
                        HStack {
                            Text(shortName(tier)).foregroundStyle(.secondary)
                            Spacer()
                            cellView(cell)
                        }
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(spoken(row))
            }
        }
    }

    private func shortName(_ tier: ProTier) -> String {
        switch tier {
        case .free: String(localized: "무료")
        case .plus: "Plus"
        case .pro:  "Pro"
        }
    }

    @ViewBuilder
    private func cellView(_ cell: Cell) -> some View {
        switch cell {
        case .yes:
            Image(systemName: "checkmark")
                .font(.body.weight(.bold))
                .foregroundStyle(.green)
        case .no:
            Text(verbatim: "–").foregroundStyle(.secondary)
        case .text(let value):
            Text(value)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// VoiceOver 가 한 줄을 한 번에 읽는다: "자녀, 무료 2명, Plus 무제한, Pro 무제한".
    private func spoken(_ row: Row) -> String {
        let parts = zip(tiers, row.cells).map { tier, cell -> String in
            let value: String = switch cell {
            case .yes: String(localized: "포함")
            case .no: String(localized: "없음")
            case .text(let text): text
            }
            return "\(shortName(tier)) \(value)"
        }
        return ([row.label] + parts).joined(separator: ", ")
    }
}

// MARK: - 잠긴 자리

/// 잠긴 줄 · 카드에 붙는 작은 자물쇠. 눌러 보기 전에 잠긴 걸 알 수 있게.
struct ProLockBadge: View {
    let feature: ProFeature

    var body: some View {
        Image(systemName: "lock.fill")
            .font(.body.weight(.semibold))
            .foregroundStyle(.secondary)
            .accessibilityLabel(String(localized: "잠김, \(feature.tier.title) 필요"))
    }
}

// MARK: - 첫 이자가 붙은 주의 작은 카드

/// 저축에 첫 이자가 붙은 주, 부모 모드에서 **한 번만** 서는 작은 카드. 닫기 쉽게, 무료 가족에게만.
/// 아이가 이자를 받아 본 지금이 우리집 은행을 더 키우고 싶어지는 때다.
struct FirstInterestNudge: View {
    let onShowPlans: () -> Void

    @Query(filter: #Predicate<MoneyTransaction> { $0.kindRaw == "이자" }, sort: \MoneyTransaction.date)
    private var interests: [MoneyTransaction]
    @AppStorage("paywall.firstInterest.seen") private var seen = false
    @State private var purchases = PurchaseManager.shared

    /// 첫 이자가 이번 주(지난 7일) 안에 붙었는가.
    private var isFirstInterestWeek: Bool {
        guard let first = interests.first?.date else { return false }
        return Date().timeIntervalSince(first) < 7 * 24 * 60 * 60
    }

    var body: some View {
        if !seen && purchases.tier == .free && isFirstInterestWeek {
            HStack(alignment: .top, spacing: 12) {
                Text(verbatim: "🌱")
                    .font(.title)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    Text("이번 주 이자가 붙었어요")
                        .font(.headline)
                    Text("아이가 늘어도, 가게가 커져도 Plus와 Pro로 우리집 은행을 함께 키워요.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("요금제 보기") {
                        seen = true
                        onShowPlans()
                    }
                    .buttonStyle(.bordered)
                }
                Spacer(minLength: 0)
                Button {
                    seen = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("닫기"))
            }
            .card()
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            // 한 번 보였으면 다음에는 서지 않는다.
            .onDisappear { seen = true }
        }
    }
}
