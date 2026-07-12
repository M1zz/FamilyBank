//
//  MarketView.swift
//  FamilyBank — 우리집 은행
//
//  시장 탭: 우리집 경제의 현재 상태 — 물가, 환율, 이자율, 통화량, 가게, 투자 시세
//

import SwiftUI
import SwiftData
import Charts

struct MarketView: View {
    let settings: FamilySettings
    /// 부모 화면에서는 투자 시세·매매까지 포함, 자녀 폰 모드는 별도 투자 탭이 있으므로 제외
    var embedInvest: Bool = true

    @Query(sort: \FamilyMember.createdAt) private var members: [FamilyMember]
    @Query(sort: \HouseholdItem.createdAt) private var storeItems: [HouseholdItem]

    private var totalWallet: Int { members.reduce(0) { $0 + $1.balance } }
    private var totalSavings: Int { members.reduce(0) { $0 + $1.savings } }
    private var totalInvest: Int { members.reduce(0) { $0 + $1.investValue } }
    private var totalCirculation: Int { totalWallet + totalSavings + totalInvest }
    private var activeItemCount: Int { storeItems.filter { $0.isActive }.count }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 핵심 지표
                    LazyVGrid(columns: columns, spacing: 12) {
                        indicatorCard("🏷️", "물가지수",
                                      "\(Int(settings.priceIndex.rounded()))",
                                      settings.inflationSinceStart >= 0.5
                                      ? "시작보다 +\(settings.inflationSinceStart.cleanPercent)%"
                                      : "시작 100 기준",
                                      .orange)
                        indicatorCard("🎈", "물가 상승률",
                                      "주 \(settings.weeklyInflationRate.cleanPercent)%",
                                      settings.weeklyInflationRate > 0 ? "매주 물가가 올라요" : "인플레이션 없음",
                                      .red)
                        indicatorCard("💱", "환율",
                                      "1 = \(Int(settings.wonPerCoin).comma)원",
                                      "1 \(settings.currencyName)의 실제 가치",
                                      .green)
                        indicatorCard("🏦", "저축 이자율",
                                      "주 \(settings.weeklyInterestRate.cleanPercent)%",
                                      "저축통장에 매주 복리",
                                      .blue)
                    }

                    // 물가 추이
                    if settings.priceIndexHistory.count >= 2 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("물가 추이 📊")
                                .font(.headline)
                            Chart(chartPoints(settings.priceIndexHistory.map { Int($0.rounded()) })) { point in
                                LineMark(
                                    x: .value("주", point.id),
                                    y: .value("물가지수", point.value)
                                )
                                .foregroundStyle(Color.orange.gradient)
                                .interpolationMethod(.catmullRom)
                                AreaMark(
                                    x: .value("주", point.id),
                                    y: .value("물가지수", point.value)
                                )
                                .foregroundStyle(Color.orange.opacity(0.12).gradient)
                                .interpolationMethod(.catmullRom)
                            }
                            .chartYScale(domain: .automatic(includesZero: false))
                            .frame(height: 140)
                            Text("물가가 오르면 같은 돈으로 살 수 있는 게 줄어들어요")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .card()
                    }

                    // 인플레이션 안내
                    if settings.weeklyInflationRate > 0 {
                        InflationCard(settings: settings)
                    }

                    // 통화량
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("우리집 통화량 💰")
                                .font(.headline)
                            Spacer()
                            Text("≈ \(settings.wonValue(ofCoins: totalCirculation).comma)원")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        MoneyText(amount: totalCirculation, currencyName: settings.currencyName, font: .title2)
                        HStack(spacing: 8) {
                            supplyChip("지갑", totalWallet, .green)
                            supplyChip("저축", totalSavings, .blue)
                            supplyChip("투자", totalInvest, .indigo)
                        }
                    }
                    .card()

                    // 우리집 가게
                    NavigationLink {
                        StoreListView(settings: settings)
                            .navigationTitle("🏪 우리집 가게")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        HStack {
                            Text("🏪")
                                .font(.system(size: 36))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("우리집 가게")
                                    .font(.headline)
                                Text(activeItemCount > 0
                                     ? "물품 \(activeItemCount)개 판매 중 · 환율 자동 반영"
                                     : "아직 물품이 없어요 · 액션 탭에서 추가")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .card()
                    }
                    .buttonStyle(.plain)

                    // 투자 시세
                    if embedInvest {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("투자 시장 📈")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        InvestSectionView(settings: settings)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("🏛️ 시장")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func indicatorCard(_ emoji: String, _ title: String, _ value: String, _ caption: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(emoji)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(color)
            Text(caption)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func supplyChip(_ label: String, _ amount: Int, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(amount.comma)
                .font(.footnote.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
