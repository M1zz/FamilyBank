//
//  AllowanceIntents.swift
//  FamilyBank
//
//  "쑥쑥용돈, 민수한테 용돈 줘" — 앱을 열지 않고 아이 지갑에 넣는다(부모 = 중앙은행).
//  "쑥쑥용돈, 민수 잔액" — 지갑과 저금을 알려 준다.
//  앱의 "용돈 주기"와 같은 길(BankEngine.give)을 탄다.
//

import AppIntents
import Foundation
import SwiftData

struct ChildEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: LocalizedStringResource("아이", comment: "Siri: a child in the family bank")
    )
    static let defaultQuery = ChildQuery()

    let id: String
    let name: String
    let emoji: String

    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(emoji) \(name)") }

    init(_ member: FamilyMember) {
        id = member.uid
        name = member.name
        emoji = member.emoji
    }
}

struct ChildQuery: EntityStringQuery {
    @Dependency private var container: ModelContainer

    func entities(for identifiers: [String]) async throws -> [ChildEntity] {
        FamilyBankLibrary.children(in: container).filter { identifiers.contains($0.uid) }.map(ChildEntity.init)
    }

    func entities(matching string: String) async throws -> [ChildEntity] {
        FamilyBankLibrary.children(in: container).filter { $0.name.localizedCaseInsensitiveContains(string) }.map(ChildEntity.init)
    }

    func suggestedEntities() async throws -> [ChildEntity] {
        FamilyBankLibrary.children(in: container).map(ChildEntity.init)
    }
}

struct GiveAllowanceIntent: AppIntent {
    static let title = LocalizedStringResource("용돈 주기", comment: "Siri: give allowance to a child")
    static let description = IntentDescription(
        LocalizedStringResource("아이 지갑에 용돈을 넣습니다.", comment: "Siri: give allowance description")
    )

    @Parameter(title: LocalizedStringResource("아이", comment: "Siri: child parameter"),
               requestValueDialog: IntentDialog(LocalizedStringResource("누구에게 줄까요?", comment: "Siri: ask which child")))
    var child: ChildEntity

    @Parameter(title: LocalizedStringResource("금액", comment: "Siri: amount parameter"),
               inclusiveRange: (1, 10_000_000),
               requestValueDialog: IntentDialog(LocalizedStringResource("얼마를 줄까요?", comment: "Siri: ask amount")))
    var amount: Int

    @Dependency private var container: ModelContainer

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = ModelContext(container)
        guard let member = FamilyBankLibrary.children(in: container, context: context).first(where: { $0.uid == child.id }) else {
            return .result(dialog: IntentDialog(LocalizedStringResource("그 아이를 찾지 못했어요.", comment: "Siri: child not found")))
        }
        BankEngine.give(to: member, amount: amount, memo: "", context: context)
        let money = FamilyBankLibrary.money(in: context)
        return .result(dialog: IntentDialog(LocalizedStringResource("\(member.name)에게 \(money(amount))을 줬어요. 지갑에 \(money(member.balance)) 있어요.", comment: "Siri: allowance given. Arguments: child, amount, new balance")))
    }
}

struct ChildBalanceIntent: AppIntent {
    static let title = LocalizedStringResource("잔액 보기", comment: "Siri: a child's balance")
    static let description = IntentDescription(
        LocalizedStringResource("아이의 지갑과 저금을 알려 줍니다.", comment: "Siri: balance description")
    )

    @Parameter(title: LocalizedStringResource("아이", comment: "Siri: child parameter"),
               requestValueDialog: IntentDialog(LocalizedStringResource("누구의 잔액인가요?", comment: "Siri: ask whose balance")))
    var child: ChildEntity

    @Dependency private var container: ModelContainer

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = ModelContext(container)
        guard let member = FamilyBankLibrary.children(in: container, context: context).first(where: { $0.uid == child.id }) else {
            return .result(dialog: IntentDialog(LocalizedStringResource("그 아이를 찾지 못했어요.", comment: "Siri: child not found")))
        }
        let money = FamilyBankLibrary.money(in: context)
        return .result(dialog: IntentDialog(LocalizedStringResource("\(member.name) 지갑에 \(money(member.balance)), 저금 \(money(member.savings)) 있어요.", comment: "Siri: balance. Arguments: child, wallet, savings")))
    }
}

struct FamilyBankShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GiveAllowanceIntent(),
            phrases: ["Give \(\.$child) allowance in \(.applicationName)", "Give allowance in \(.applicationName)"],
            shortTitle: "Give Allowance",
            systemImageName: "wonsign.circle"
        )
        AppShortcut(
            intent: ChildBalanceIntent(),
            phrases: ["\(\.$child) balance in \(.applicationName)", "Check balance in \(.applicationName)"],
            shortTitle: "Check Balance",
            systemImageName: "banknote"
        )
    }
}

enum FamilyBankLibrary {
    static func children(in container: ModelContainer, context: ModelContext? = nil) -> [FamilyMember] {
        let context = context ?? ModelContext(container)
        return ((try? context.fetch(FetchDescriptor<FamilyMember>())) ?? []).filter(\.isChild)
    }

    /// 앱과 같은 표기: "1,000 쑥" 처럼 가족 화폐 이름을 붙인다.
    static func money(in context: ModelContext) -> (Int) -> String {
        let name = (try? context.fetch(FetchDescriptor<FamilySettings>()).first)?.currencyName ?? ""
        return { amount in name.isEmpty ? amount.comma : "\(amount.comma) \(name)" }
    }
}
