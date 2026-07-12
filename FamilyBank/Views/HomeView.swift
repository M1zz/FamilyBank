//
//  HomeView.swift
//  FamilyBank — 우리집 은행
//
//  가족 구성원별 자산 현황
//

import SwiftUI
import SwiftData

struct HomeView: View {
    let settings: FamilySettings
    @Query(sort: \FamilyMember.createdAt) private var members: [FamilyMember]

    private var children: [FamilyMember] { members.filter { $0.isChild } }
    private var parents: [FamilyMember] { members.filter { !$0.isChild } }
    private var totalCirculation: Int { members.reduce(0) { $0 + $1.totalAssets } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 총 유통 화폐
                    VStack(alignment: .leading, spacing: 6) {
                        Label("우리집에 도는 돈", systemImage: "banknote.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        MoneyText(amount: totalCirculation, currencyName: settings.currencyName, font: .largeTitle)
                        Text("주간 저축 이자율 \(settings.weeklyInterestRate.cleanPercent)% · 주간 물가 상승률 \(settings.weeklyInflationRate.cleanPercent)%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .card()

                    if !children.isEmpty {
                        sectionHeader("자녀 👧")
                        ForEach(children) { member in
                            NavigationLink {
                                MemberDetailView(member: member, settings: settings)
                            } label: {
                                MemberCard(member: member, settings: settings)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if !parents.isEmpty {
                        sectionHeader("부모 🏦")
                        ForEach(parents) { member in
                            NavigationLink {
                                MemberDetailView(member: member, settings: settings)
                            } label: {
                                MemberCard(member: member, settings: settings)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 물가 카드 (인플레이션)

struct InflationCard: View {
    let settings: FamilySettings

    /// 처음 기준 1,000의 현재 구매력
    private var powerOf1000: Int { settings.realValue(of: 1000) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("우리집 물가", systemImage: "cart.fill.badge.plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("지수 \(Int(settings.priceIndex.rounded()))")
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(.orange)
            }

            if settings.inflationSinceStart >= 0.5 {
                Text("처음보다 물가가 \(settings.inflationSinceStart.cleanPercent)% 올랐어요. 지갑 속 1,000 \(settings.currencyName)의 힘은 이제 \(powerOf1000.comma) \(settings.currencyName)만큼이에요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("💡 돈을 그냥 두면 힘이 줄어요. 저축(이자)이나 투자로 지켜 보세요!")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else {
                Text("매주 물가가 \(settings.weeklyInflationRate.cleanPercent)%씩 올라요. 같은 돈으로 살 수 있는 게 조금씩 줄어든다는 뜻이에요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .card()
    }
}

// MARK: - 구성원 카드

struct MemberCard: View {
    let member: FamilyMember
    let settings: FamilySettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(member.emoji)
                    .font(.system(size: 36))
                VStack(alignment: .leading, spacing: 2) {
                    Text(member.name)
                        .font(.headline)
                    Text(member.role.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("총자산")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    MoneyText(amount: member.totalAssets, currencyName: settings.currencyName, font: .title3)
                }
            }

            HStack(spacing: 8) {
                assetChip("지갑", member.balance, .green)
                assetChip("저축", member.savings, .blue)
                assetChip("투자", member.investValue, .indigo)
            }
        }
        .card()
    }

    private func assetChip(_ label: String, _ amount: Int, _ color: Color) -> some View {
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
