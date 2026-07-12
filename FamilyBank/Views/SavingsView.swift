//
//  SavingsView.swift
//  FamilyBank — 우리집 은행
//
//  저축통장: 입출금 + 복리 이자 미리보기
//

import SwiftUI
import SwiftData
import Charts

struct SavingsView: View {
    @Bindable var member: FamilyMember
    let settings: FamilySettings

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var amountText = ""
    @State private var mode: Mode = .deposit
    @State private var showResult = false
    @State private var resultMessage = ""

    enum Mode: String, CaseIterable {
        case deposit = "입금"
        case withdraw = "출금"
    }

    private var amount: Int { Int(amountText) ?? 0 }

    /// 앞으로 12주 동안의 복리 예상 (현재 저축 기준)
    private var projection: [ChartPoint] {
        var result: [ChartPoint] = [ChartPoint(id: 0, value: member.savings)]
        var current = Double(member.savings)
        for week in 1...12 {
            current *= (1 + settings.weeklyInterestRate / 100)
            result.append(ChartPoint(id: week, value: Int(current.rounded())))
        }
        return result
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("내 저축통장") {
                    HStack {
                        Text("저축 잔액")
                        Spacer()
                        MoneyText(amount: member.savings, currencyName: settings.currencyName, font: .body)
                    }
                    HStack {
                        Text("주간 이자율")
                        Spacer()
                        Text("\(settings.weeklyInterestRate.cleanPercent)% (복리)")
                            .foregroundStyle(.purple)
                            .fontWeight(.semibold)
                    }
                    HStack {
                        Text("지갑 잔액")
                        Spacer()
                        Text("\(member.balance.comma) \(settings.currencyName)")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("입금 / 출금") {
                    Picker("종류", selection: $mode) {
                        ForEach(Mode.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)

                    AmountField(placeholder: "금액", text: $amountText)

                    Button {
                        perform()
                    } label: {
                        Label(mode == .deposit ? "저축통장에 넣기" : "지갑으로 꺼내기",
                              systemImage: mode == .deposit ? "tray.and.arrow.down.fill" : "tray.and.arrow.up.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(amount <= 0)
                }

                if member.savings > 0 {
                    Section("이대로 두면 얼마가 될까? (12주 복리 예상)") {
                        Chart(projection) { point in
                            LineMark(
                                x: .value("주", point.id),
                                y: .value("금액", point.value)
                            )
                            .foregroundStyle(Color.purple.gradient)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("주", point.id),
                                y: .value("금액", point.value)
                            )
                            .foregroundStyle(Color.purple.opacity(0.12).gradient)
                            .interpolationMethod(.catmullRom)
                        }
                        .frame(height: 160)

                        if let last = projection.last {
                            Text("12주 뒤 예상: \(last.value.comma) \(settings.currencyName) (+\((last.value - member.savings).comma))")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.purple)
                        }
                        Text("이자가 이자를 낳는 것을 '복리'라고 해요. 오래 저축할수록 돈이 눈덩이처럼 불어나요! ⛄️")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("🏦 저축통장")
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

    private func perform() {
        let ok: Bool
        if mode == .deposit {
            ok = BankEngine.depositSavings(member: member, amount: amount, context: context)
            resultMessage = ok
                ? "\(amount.comma) \(settings.currencyName)을(를) 저축했어요! 매주 이자가 붙어요. 💰"
                : "지갑에 돈이 부족해요."
        } else {
            ok = BankEngine.withdrawSavings(member: member, amount: amount, context: context)
            resultMessage = ok
                ? "\(amount.comma) \(settings.currencyName)을(를) 지갑으로 옮겼어요."
                : "저축통장에 돈이 부족해요."
        }
        if ok { amountText = "" }
        showResult = true
    }
}
