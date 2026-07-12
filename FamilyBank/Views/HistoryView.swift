//
//  HistoryView.swift
//  FamilyBank — 우리집 은행
//
//  전체 거래 기록
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    let settings: FamilySettings

    @Query(sort: \MoneyTransaction.date, order: .reverse) private var transactions: [MoneyTransaction]
    @Query(sort: \FamilyMember.createdAt) private var members: [FamilyMember]

    @State private var filterMemberName: String? = nil
    @State private var filterKind: TxKind? = nil

    private var filtered: [MoneyTransaction] {
        transactions.filter { tx in
            if let name = filterMemberName, tx.member?.name != name { return false }
            if let kind = filterKind, tx.kind != kind { return false }
            return true
        }
    }

    struct DayGroup: Identifiable {
        let day: String
        let items: [MoneyTransaction]
        var id: String { day }
    }

    /// 날짜별 그룹
    private var grouped: [DayGroup] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 (E)"
        var dict: [String: [MoneyTransaction]] = [:]
        var order: [String] = []
        for tx in filtered {
            let key = formatter.string(from: tx.date)
            if dict[key] == nil {
                dict[key] = []
                order.append(key)
            }
            dict[key]?.append(tx)
        }
        return order.map { DayGroup(day: $0, items: dict[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filtered.isEmpty {
                    VStack(spacing: 8) {
                        Text("🧾")
                            .font(.system(size: 56))
                        Text("거래 기록이 없어요")
                            .font(.headline)
                        Text("용돈을 주거나 결제하면 여기에 기록돼요")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(grouped) { group in
                            Section(group.day) {
                                ForEach(group.items) { tx in
                                    TransactionRow(tx: tx, currencyName: settings.currencyName, showMemberName: true)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("🧾 거래 기록")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        // 구성원 필터
                        Menu("구성원") {
                            Button("전체") { filterMemberName = nil }
                            ForEach(members) { m in
                                Button("\(m.emoji) \(m.name)") { filterMemberName = m.name }
                            }
                        }
                        // 종류 필터
                        Menu("거래 종류") {
                            Button("전체") { filterKind = nil }
                            ForEach(TxKind.allCases, id: \.self) { kind in
                                Button(kind.rawValue) { filterKind = kind }
                            }
                        }
                        if filterMemberName != nil || filterKind != nil {
                            Button("필터 초기화", role: .destructive) {
                                filterMemberName = nil
                                filterKind = nil
                            }
                        }
                    } label: {
                        Label("필터", systemImage: (filterMemberName != nil || filterKind != nil)
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }
}
