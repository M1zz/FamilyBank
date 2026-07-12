//
//  MemberDetailView.swift
//  FamilyBank — 우리집 은행
//
//  구성원 상세: 잔액, 결제, 저축, 최근 거래
//

import SwiftUI
import SwiftData

struct MemberDetailView: View {
    @Bindable var member: FamilyMember
    let settings: FamilySettings

    @State private var showPay = false
    @State private var showSavings = false
    @State private var showStore = false

    private var recentTransactions: [MoneyTransaction] {
        (member.transactions ?? [])
            .sorted { $0.date > $1.date }
            .prefix(15)
            .map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 자산 요약
                VStack(spacing: 12) {
                    Text(member.emoji)
                        .font(.system(size: 56))
                    MoneyText(amount: member.totalAssets, currencyName: settings.currencyName, font: .largeTitle)
                    Text("총자산 · 실제 돈으로 약 \(settings.wonValue(ofCoins: member.totalAssets).comma)원")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        summaryBox("💵 지갑", member.balance)
                        summaryBox("🏦 저축", member.savings)
                        summaryBox("📈 투자", member.investValue)
                    }
                }
                .card()

                // 액션 버튼
                HStack(spacing: 12) {
                    Button {
                        showStore = true
                    } label: {
                        Label("가게", systemImage: "storefront.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button {
                        showPay = true
                    } label: {
                        Label("결제", systemImage: "cart.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button {
                        showSavings = true
                    } label: {
                        Label("저축", systemImage: "building.columns.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                // 보유 투자 상품
                if let holdings = member.holdings, !holdings.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("보유 투자 상품")
                            .font(.headline)
                        ForEach(holdings.filter { $0.quantity > 0 }) { holding in
                            HStack {
                                Text(holding.product?.emoji ?? "📈")
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(holding.product?.name ?? "상품")
                                        .font(.subheadline.weight(.medium))
                                    Text("\(holding.quantity)주 · 평균 \(holding.avgPrice.comma)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(holding.currentValue.comma)
                                        .font(.subheadline.weight(.bold))
                                        .monospacedDigit()
                                    Text("\(holding.profit >= 0 ? "+" : "")\(holding.profit.comma) (\(String(format: "%.1f", holding.profitRate))%)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(holding.profit >= 0 ? Color.red : Color.blue)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .card()
                }

                // 최근 거래
                VStack(alignment: .leading, spacing: 10) {
                    Text("최근 거래")
                        .font(.headline)
                    if recentTransactions.isEmpty {
                        Text("아직 거래가 없어요")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(recentTransactions) { tx in
                            TransactionRow(tx: tx, currencyName: settings.currencyName)
                        }
                    }
                }
                .card()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(member.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPay) {
            PayView(payer: member, settings: settings)
        }
        .sheet(isPresented: $showSavings) {
            SavingsView(member: member, settings: settings)
        }
        .sheet(isPresented: $showStore) {
            StoreSheet(settings: settings, payer: member)
        }
    }

    private func summaryBox(_ label: String, _ amount: Int) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(amount.comma)
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
