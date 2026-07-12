//
//  InvestView.swift
//  FamilyBank — 우리집 은행
//
//  투자: 모의 펀드 시세 확인, 매수/매도
//

import SwiftUI
import SwiftData
import Charts

struct InvestTabView: View {
    let settings: FamilySettings
    /// 지정하면 투자자 선택 없이 이 구성원으로 고정 (자녀 폰 모드)
    var fixedInvestor: FamilyMember? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                InvestSectionView(settings: settings, fixedInvestor: fixedInvestor)
                    .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("📈 투자")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - 투자 섹션 (투자 탭과 시장 탭에서 재사용)

struct InvestSectionView: View {
    let settings: FamilySettings
    var fixedInvestor: FamilyMember? = nil

    @Query(sort: \FamilyMember.createdAt) private var members: [FamilyMember]
    @Query(sort: \InvestProduct.createdAt) private var products: [InvestProduct]

    @State private var selectedMemberIndex = 0
    @State private var selectedProduct: InvestProduct?

    private var children: [FamilyMember] { members.filter { $0.isChild } }
    private var activeProducts: [InvestProduct] { products.filter { $0.isActive } }
    private var investor: FamilyMember? {
        if let fixedInvestor { return fixedInvestor }
        return children.indices.contains(selectedMemberIndex) ? children[selectedMemberIndex] : children.first
    }

    var body: some View {
                VStack(spacing: 16) {
                    // 투자자 선택 (자녀 폰 모드에서는 내 지갑 요약만)
                    if let fixedInvestor {
                        HStack {
                            Text("지갑: \(fixedInvestor.balance.comma) \(settings.currencyName)")
                            Spacer()
                            Text("투자 평가액: \(fixedInvestor.investValue.comma) \(settings.currencyName)")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .card()
                    } else if !children.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("투자자 선택")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Picker("투자자", selection: $selectedMemberIndex) {
                                ForEach(children.indices, id: \.self) { i in
                                    Text("\(children[i].emoji) \(children[i].name)").tag(i)
                                }
                            }
                            .pickerStyle(.segmented)

                            if let investor {
                                HStack {
                                    Text("지갑: \(investor.balance.comma) \(settings.currencyName)")
                                    Spacer()
                                    Text("투자 평가액: \(investor.investValue.comma) \(settings.currencyName)")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                        .card()
                    }

                    // 상품 목록
                    if activeProducts.isEmpty {
                        VStack(spacing: 8) {
                            Text("📭")
                                .font(.system(size: 48))
                            Text("판매 중인 투자 상품이 없어요")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("부모 모드에서 상품을 추가할 수 있어요")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(activeProducts) { product in
                            Button {
                                selectedProduct = product
                            } label: {
                                ProductCard(product: product, settings: settings)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("💡 시세는 하루에 한 번 바뀌어요. 값이 쌀 때 사서 비쌀 때 팔면 이익, 반대면 손해예요!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }
                .sheet(item: $selectedProduct) { product in
                    ProductDetailView(product: product, investor: investor, settings: settings)
                }
    }
}

// MARK: - 상품 카드

struct ProductCard: View {
    let product: InvestProduct
    let settings: FamilySettings

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(product.emoji)
                    .font(.system(size: 32))
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.name)
                        .font(.headline)
                    Text(product.riskLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(product.price.comma) \(settings.currencyName)")
                        .font(.headline)
                        .monospacedDigit()
                    Text("\(product.changeRate >= 0 ? "▲" : "▼") \(String(format: "%.1f", abs(product.changeRate)))%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(product.changeRate >= 0 ? Color.red : Color.blue)
                }
            }

            // 미니 차트
            if product.priceHistory.count >= 2 {
                Chart(chartPoints(Array(product.priceHistory.suffix(30)))) { point in
                    LineMark(
                        x: .value("일", point.id),
                        y: .value("가격", point.value)
                    )
                    .foregroundStyle((product.changeRate >= 0 ? Color.red : Color.blue).gradient)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartYScale(domain: .automatic(includesZero: false))
                .frame(height: 44)
            }
        }
        .card()
    }
}

// MARK: - 상품 상세 (매수/매도)

struct ProductDetailView: View {
    @Bindable var product: InvestProduct
    let investor: FamilyMember?
    let settings: FamilySettings

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var quantity = 1
    @State private var showResult = false
    @State private var resultMessage = ""

    private var holding: Holding? {
        guard let investor else { return nil }
        return (investor.holdings ?? []).first { $0.product === product }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 헤더
                    VStack(spacing: 8) {
                        Text(product.emoji)
                            .font(.system(size: 56))
                        Text(product.name)
                            .font(.title2.weight(.bold))
                        Text(product.riskLabel)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .clipShape(Capsule())
                        Text(product.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .card()

                    // 가격 차트
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("현재 가격")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(product.price.comma) \(settings.currencyName)")
                                .font(.title3.weight(.bold))
                                .monospacedDigit()
                            Text("\(product.changeRate >= 0 ? "▲" : "▼") \(String(format: "%.1f", abs(product.changeRate)))%")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(product.changeRate >= 0 ? Color.red : Color.blue)
                        }

                        if product.priceHistory.count >= 2 {
                            Chart(chartPoints(product.priceHistory)) { point in
                                LineMark(
                                    x: .value("일", point.id),
                                    y: .value("가격", point.value)
                                )
                                .foregroundStyle(Color.accentColor.gradient)
                                .interpolationMethod(.catmullRom)
                            }
                            .chartYScale(domain: .automatic(includesZero: false))
                            .frame(height: 180)
                        } else {
                            Text("아직 가격 기록이 부족해요. 내일 다시 확인해 보세요!")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .card()

                    // 보유 현황
                    if let investor {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(investor.emoji) \(investor.name)의 보유 현황")
                                .font(.subheadline.weight(.semibold))
                            if let holding, holding.quantity > 0 {
                                HStack {
                                    Text("\(holding.quantity)주 · 평균 \(holding.avgPrice.comma)")
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(holding.profit >= 0 ? "+" : "")\(holding.profit.comma) (\(String(format: "%.1f", holding.profitRate))%)")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(holding.profit >= 0 ? Color.red : Color.blue)
                                }
                            } else {
                                Text("아직 보유하고 있지 않아요")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            HStack {
                                Text("지갑 잔액")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(investor.balance.comma) \(settings.currencyName)")
                                    .font(.caption.weight(.semibold))
                            }
                        }
                        .card()

                        // 매수/매도
                        VStack(spacing: 12) {
                            Stepper("수량: \(quantity)주", value: $quantity, in: 1...999)
                            HStack {
                                Text("총 금액")
                                Spacer()
                                Text("\((product.price * quantity).comma) \(settings.currencyName)")
                                    .fontWeight(.bold)
                                    .monospacedDigit()
                            }
                            .font(.subheadline)

                            HStack(spacing: 12) {
                                Button {
                                    buy(investor)
                                } label: {
                                    Label("매수", systemImage: "plus.circle.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)

                                Button {
                                    sell(investor)
                                } label: {
                                    Label("매도", systemImage: "minus.circle.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)
                                .disabled((holding?.quantity ?? 0) < quantity)
                            }
                        }
                        .card()
                    } else {
                        Text("투자하려면 먼저 홈에서 자녀를 등록해 주세요.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .card()
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("투자 상품")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .alert("알림", isPresented: $showResult) {
                Button("확인") {}
            } message: {
                Text(resultMessage)
            }
        }
    }

    private func buy(_ investor: FamilyMember) {
        let ok = BankEngine.buy(member: investor, product: product, quantity: quantity, context: context)
        resultMessage = ok
            ? "\(product.name) \(quantity)주를 샀어요! 📈"
            : "지갑에 돈이 부족해요. 필요 금액: \((product.price * quantity).comma) \(settings.currencyName)"
        showResult = true
    }

    private func sell(_ investor: FamilyMember) {
        let ok = BankEngine.sell(member: investor, product: product, quantity: quantity, context: context)
        resultMessage = ok
            ? "\(product.name) \(quantity)주를 팔았어요! \((product.price * quantity).comma) \(settings.currencyName)이 지갑에 들어왔어요."
            : "보유 수량이 부족해요."
        showResult = true
    }
}
