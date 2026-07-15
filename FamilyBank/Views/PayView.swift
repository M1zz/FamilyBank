//
//  PayView.swift
//  쑥쑥용돈
//
//  결제: 자녀가 부모(가게)에게 돈을 지불
//

import SwiftUI
import SwiftData

struct PayView: View {
    @Bindable var payer: FamilyMember
    let settings: FamilySettings

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \FamilyMember.createdAt) private var members: [FamilyMember]

    @State private var amountText = ""
    @State private var memo = ""
    @State private var receiverIndex = 0
    @State private var showResult = false
    @State private var resultMessage = ""
    @State private var didSucceed = false

    private var receivers: [FamilyMember] {
        members.filter { $0 !== payer }
    }
    private var amount: Int { Int(amountText) ?? 0 }

    /// 자주 쓰는 결제 예시
    private let quickMemos = ["간식 🍪", "게임 시간 🎮", "TV 시간 📺", "장난감 🧸", "심부름 값 📦"]

    var body: some View {
        NavigationStack {
            Form {
                Section("내 지갑") {
                    HStack {
                        Text("잔액")
                        Spacer()
                        MoneyText(amount: payer.balance, currencyName: settings.currencyName, font: .body)
                    }
                }

                Section("얼마를 낼까요?") {
                    AmountField(placeholder: "금액", text: $amountText)
                    HStack {
                        ForEach([100, 500, 1000], id: \.self) { preset in
                            Button("+\(preset.comma)") {
                                amountText = "\((Int(amountText) ?? 0) + preset)"
                            }
                            .buttonStyle(.bordered)
                            .font(.caption)
                        }
                    }
                }

                Section("무엇에 쓰나요?") {
                    TextField("메모 (예: 간식 사기)", text: $memo)
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

                Section("누구에게 낼까요?") {
                    if receivers.isEmpty {
                        Text("받을 사람이 없어요")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("받는 사람", selection: $receiverIndex) {
                            ForEach(receivers.indices, id: \.self) { i in
                                Text("\(receivers[i].emoji) \(receivers[i].name)").tag(i)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section {
                    Button {
                        performPay()
                    } label: {
                        Label("\(amount.comma) \(settings.currencyName) 결제하기", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(amount <= 0 || receivers.isEmpty)
                }
            }
            .navigationTitle("💳 결제하기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .alert(didSucceed ? "결제 완료! 🎉" : "결제 실패", isPresented: $showResult) {
                Button("확인") {
                    if didSucceed { dismiss() }
                }
            } message: {
                Text(resultMessage)
            }
        }
    }

    private func performPay() {
        let receiver = receivers.indices.contains(receiverIndex) ? receivers[receiverIndex] : nil
        let ok = BankEngine.pay(from: payer, to: receiver, amount: amount, memo: memo, context: context)
        didSucceed = ok
        if ok {
            resultMessage = "\(receiver?.name ?? "")에게 \(amount.comma) \(settings.currencyName)을(를) 결제했어요."
        } else {
            resultMessage = "지갑에 돈이 부족해요! 잔액: \(payer.balance.comma) \(settings.currencyName)"
        }
        showResult = true
    }
}
