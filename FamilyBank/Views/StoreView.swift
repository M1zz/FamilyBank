//
//  StoreView.swift
//  쑥쑥용돈
//
//  우리집 가게: 부모가 정한 물품 가격표를 가족 모두가 보고, 자녀는 바로 결제
//

import SwiftUI
import SwiftData

// MARK: - 가게 목록 (payer가 있으면 구매 가능, 없으면 구경만)

struct StoreListView: View {
    let settings: FamilySettings
    var payer: FamilyMember?

    @Environment(\.modelContext) private var context
    @Query(sort: \HouseholdItem.createdAt) private var items: [HouseholdItem]
    @Query(sort: \FamilyMember.createdAt) private var members: [FamilyMember]

    @State private var buyTarget: HouseholdItem?
    @State private var showResult = false
    @State private var resultMessage = ""

    private var activeItems: [HouseholdItem] { items.filter { $0.isActive } }

    /// 가게 주인 = 결제자가 아닌 첫 번째 부모
    private var shopkeeper: FamilyMember? {
        members.first { !$0.isChild && $0 !== payer }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Text("환율")
                    Spacer()
                    Text("1 \(settings.currencyName) = \(Int(settings.wonPerCoin).comma)원")
                        .foregroundStyle(.secondary)
                }
                if let payer {
                    HStack {
                        Text("내 지갑")
                        Spacer()
                        Text("\(payer.balance.comma) \(settings.currencyName)")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("가격표 🏷️") {
                if activeItems.isEmpty {
                    Text("아직 등록된 물품이 없어요.\n부모 모드에서 우리집 물품을 등록해 보세요!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(activeItems) { item in
                        HStack(spacing: 12) {
                            Text(item.emoji)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.subheadline.weight(.medium))
                                Text("실제 가격 \(item.priceWon.comma)원")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(settings.coinPrice(forWon: item.priceWon).comma) \(settings.currencyName)")
                                    .font(.subheadline.weight(.bold))
                                    .monospacedDigit()
                                if payer != nil {
                                    Button("사기") { buyTarget = item }
                                        .buttonStyle(.borderedProminent)
                                        .controlSize(.mini)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .confirmationDialog(buyConfirmTitle, isPresented: Binding(
            get: { buyTarget != nil },
            set: { if !$0 { buyTarget = nil } }
        ), titleVisibility: .visible) {
            Button("결제하기") { performBuy() }
            Button("취소", role: .cancel) { buyTarget = nil }
        }
        .alert("알림", isPresented: $showResult) {
            Button("확인") {}
        } message: {
            Text(resultMessage)
        }
    }

    private var buyConfirmTitle: String {
        guard let item = buyTarget else { return "" }
        return "\(item.emoji) \(item.name)을(를) \(settings.coinPrice(forWon: item.priceWon).comma) \(settings.currencyName)에 살까요?"
    }

    private func performBuy() {
        guard let payer, let item = buyTarget else { return }
        let price = settings.coinPrice(forWon: item.priceWon)
        let ok = BankEngine.pay(from: payer,
                                to: shopkeeper,
                                amount: price,
                                memo: "\(item.emoji) \(item.name)",
                                context: context)
        resultMessage = ok
            ? "\(item.name)을(를) 샀어요! 🎉 남은 지갑: \(payer.balance.comma) \(settings.currencyName)"
            : "지갑에 돈이 부족해요! 잔액: \(payer.balance.comma) \(settings.currencyName)"
        buyTarget = nil
        showResult = true
    }
}

// MARK: - 구매용 시트 (구성원 상세에서 열기)

struct StoreSheet: View {
    let settings: FamilySettings
    let payer: FamilyMember
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            StoreListView(settings: settings, payer: payer)
                .navigationTitle("🏪 우리집 가게")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("닫기") { dismiss() }
                    }
                }
        }
    }
}
