//
//  HistoryView.swift
//  쑥쑥용돈
//
//  전체 거래 기록
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct HistoryView: View {
    let settings: FamilySettings
    /// 지정하면 이 구성원의 거래만 표시 (자녀 폰 모드)
    var fixedMember: FamilyMember? = nil

    @Query(sort: \MoneyTransaction.date, order: .reverse) private var transactions: [MoneyTransaction]
    @Query(sort: \FamilyMember.createdAt) private var members: [FamilyMember]

    @State private var filterMemberName: String? = nil
    @State private var filterKind: TxKind? = nil

    private var filtered: [MoneyTransaction] {
        transactions.filter { tx in
            if let fixedMember, tx.member !== fixedMember { return false }
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
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("MMMdEEE")
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
                            .accessibilityHidden(true)
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
                                    TransactionRow(tx: tx, currencyName: settings.currencyName, showMemberName: fixedMember == nil)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("🧾 거래 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 가족 거래 기록을 CSV 로 내보낸다. 기본 내보내기라 어떤 칸에서도 잠그지 않는다.
                if fixedMember == nil && !filtered.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        ShareLink(item: TransactionCSV(transactions: filtered),
                                  preview: SharePreview(String(localized: "거래 기록 CSV"))) {
                            Label("CSV로 내보내기", systemImage: "square.and.arrow.up")
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        // 구성원 필터 (자녀 폰 모드에서는 숨김)
                        if fixedMember == nil {
                            Menu("구성원") {
                                Button("전체") { filterMemberName = nil }
                                ForEach(members) { m in
                                    Button("\(m.emoji) \(m.name)") { filterMemberName = m.name }
                                }
                            }
                        }
                        // 종류 필터
                        Menu("거래 종류") {
                            Button("전체") { filterKind = nil }
                            ForEach(TxKind.allCases, id: \.self) { kind in
                                Button(LocalizedStringKey(kind.rawValue)) { filterKind = kind }
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

// MARK: - CSV 내보내기

/// 거래 기록 한 장. 엑셀 · 넘버스 · 구글 시트에서 바로 열린다(UTF-8 BOM).
struct TransactionCSV: Transferable {
    let text: String

    init(transactions: [MoneyTransaction]) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let header = [String(localized: "날짜"), String(localized: "구성원"), String(localized: "종류"),
                      String(localized: "금액"), String(localized: "메모")]
        let lines = transactions.map { tx in
            [formatter.string(from: tx.date),
             tx.member?.name ?? "",
             String(localized: String.LocalizationValue(tx.kind.rawValue)),
             "\(tx.kind.isIncome ? tx.amount : -tx.amount)",
             tx.displayMemo]
        }
        text = ([header] + lines)
            .map { $0.map(Self.escape).joined(separator: ",") }
            .joined(separator: "\r\n")
    }

    /// 쉼표 · 따옴표 · 줄바꿈이 든 칸은 따옴표로 감싼다.
    private static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0.isNewline }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { csv in
            let day = Date().formatted(.iso8601.year().month().day())
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("FamilyBank-\(day).csv")
            try Data(("\u{FEFF}" + csv.text).utf8).write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }
}
