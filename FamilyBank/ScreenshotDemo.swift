//
//  ScreenshotDemo.swift
//  쑥쑥용돈
//
//  스토어 스크린샷용 가상의 네 식구 장부 — DEBUG 빌드에서 `-ScreenshotDemo YES` 로 켰을 때만 동작한다.
//  `-DemoScreen dashboard|child|savings|market|actions|learn` 으로 첫 화면을 고른다.
//  배포(Release) 빌드에는 들어가지 않는다.
//

import Foundation
import SwiftData

enum ScreenshotDemo {
    #if DEBUG
    static var isOn: Bool { UserDefaults.standard.bool(forKey: "ScreenshotDemo") }
    #else
    static var isOn: Bool { false }
    #endif

    static var screen: String { isOn ? (UserDefaults.standard.string(forKey: "DemoScreen") ?? "") : "" }

    /// 시작 탭 (0 대시보드 · 1 액션 · 2 시장 · 3 기록 · 4 배우기)
    static var startTab: Int {
        switch screen {
        case "actions": return 1
        case "market": return 2
        case "history": return 3
        case "learn": return 4
        default: return 0
        }
    }

    static var opensChild: Bool { screen == "child" || screen == "savings" }
    static var opensSavings: Bool { screen == "savings" }
    static var startsUnlocked: Bool { screen == "actions" }

    #if DEBUG
    private struct Names {
        let child1, child2, mom, dad, allowance, chore, game: String
        let items: [String]
    }

    private static func names(for lang: String) -> Names {
        switch lang {
        case "ko": return Names(child1: "하준", child2: "하린", mom: "엄마", dad: "아빠", allowance: "이번 주 용돈", chore: "방 청소 완료", game: "게임 30분", items: ["과자", "아이스크림", "게임 30분", "스티커", "만화책"])
        case "en-GB": return Names(child1: "Oliver", child2: "Amelia", mom: "Mum", dad: "Dad", allowance: "This week's pocket money", chore: "Tidied my room", game: "30 min of games", items: ["Crisps", "Ice lolly", "30 min of games", "Stickers", "Comic"])
        case "en": return Names(child1: "Liam", child2: "Emma", mom: "Mom", dad: "Dad", allowance: "This week's allowance", chore: "Cleaned my room", game: "30 min of games", items: ["Snack", "Ice cream", "30 min of games", "Stickers", "Comic book"])
        case "ja": return Names(child1: "はると", child2: "ゆい", mom: "ママ", dad: "パパ", allowance: "今週のおこづかい", chore: "部屋のそうじ", game: "ゲーム30分", items: ["おかし", "アイス", "ゲーム30分", "シール", "まんが"])
        case "zh-Hans": return Names(child1: "浩然", child2: "欣怡", mom: "妈妈", dad: "爸爸", allowance: "本周零花钱", chore: "打扫房间", game: "游戏30分钟", items: ["零食", "冰淇淋", "游戏30分钟", "贴纸", "漫画书"])
        case "zh-Hant": return Names(child1: "宥廷", child2: "語彤", mom: "媽媽", dad: "爸爸", allowance: "本週零用錢", chore: "打掃房間", game: "遊戲30分鐘", items: ["零食", "冰淇淋", "遊戲30分鐘", "貼紙", "漫畫書"])
        case "es": return Names(child1: "Hugo", child2: "Lucía", mom: "Mamá", dad: "Papá", allowance: "Paga de esta semana", chore: "Ordenar mi cuarto", game: "30 min de videojuegos", items: ["Chuches", "Helado", "30 min de videojuegos", "Pegatinas", "Cómic"])
        case "de": return Names(child1: "Noah", child2: "Emilia", mom: "Mama", dad: "Papa", allowance: "Taschengeld der Woche", chore: "Zimmer aufgeräumt", game: "30 Min. Videospiele", items: ["Süßigkeiten", "Eis", "30 Min. Videospiele", "Sticker", "Comic"])
        case "fr": return Names(child1: "Gabriel", child2: "Jade", mom: "Maman", dad: "Papa", allowance: "Argent de poche de la semaine", chore: "Chambre rangée", game: "30 min de jeux vidéo", items: ["Bonbons", "Glace", "30 min de jeux vidéo", "Autocollants", "BD"])
        case "it": return Names(child1: "Leonardo", child2: "Sofia", mom: "Mamma", dad: "Papà", allowance: "Paghetta della settimana", chore: "Camera riordinata", game: "30 min di videogiochi", items: ["Merendina", "Gelato", "30 min di videogiochi", "Adesivi", "Fumetto"])
        case "pt-BR": return Names(child1: "Miguel", child2: "Helena", mom: "Mamãe", dad: "Papai", allowance: "Mesada da semana", chore: "Arrumei o quarto", game: "30 min de videogame", items: ["Salgadinho", "Sorvete", "30 min de videogame", "Figurinhas", "Gibi"])
        case "ru": return Names(child1: "Миша", child2: "Соня", mom: "Мама", dad: "Папа", allowance: "Карманные на неделю", chore: "Убрал комнату", game: "30 минут игр", items: ["Печенье", "Мороженое", "30 минут игр", "Наклейки", "Комикс"])
        case "th": return Names(child1: "ภูมิ", child2: "ใบเฟิร์น", mom: "แม่", dad: "พ่อ", allowance: "ค่าขนมสัปดาห์นี้", chore: "เก็บห้องเรียบร้อย", game: "เล่นเกม 30 นาที", items: ["ขนม", "ไอศกรีม", "เล่นเกม 30 นาที", "สติกเกอร์", "การ์ตูน"])
        case "vi": return Names(child1: "Minh", child2: "An", mom: "Mẹ", dad: "Bố", allowance: "Tiền tiêu vặt tuần này", chore: "Dọn phòng xong", game: "Chơi game 30 phút", items: ["Bánh kẹo", "Kem", "Chơi game 30 phút", "Hình dán", "Truyện tranh"])
        case "cs": return Names(child1: "Jakub", child2: "Eliška", mom: "Máma", dad: "Táta", allowance: "Kapesné na tento týden", chore: "Uklizený pokoj", game: "30 min her", items: ["Sušenky", "Zmrzlina", "30 min her", "Samolepky", "Komiks"])
        case "da": return Names(child1: "William", child2: "Ida", mom: "Mor", dad: "Far", allowance: "Ugens lommepenge", chore: "Ryddet mit værelse", game: "30 min. spil", items: ["Slik", "Is", "30 min. spil", "Klistermærker", "Tegneserie"])
        case "el": return Names(child1: "Γιώργος", child2: "Μαρία", mom: "Μαμά", dad: "Μπαμπάς", allowance: "Χαρτζιλίκι της εβδομάδας", chore: "Συγύρισα το δωμάτιο", game: "30 λεπτά παιχνίδι", items: ["Σνακ", "Παγωτό", "30 λεπτά παιχνίδι", "Αυτοκόλλητα", "Κόμικ"])
        case "fi": return Names(child1: "Eino", child2: "Aino", mom: "Äiti", dad: "Isä", allowance: "Viikon taskuraha", chore: "Siivosin huoneen", game: "30 min pelaamista", items: ["Karkki", "Jäätelö", "30 min pelaamista", "Tarrat", "Sarjakuva"])
        case "id": return Names(child1: "Raka", child2: "Alya", mom: "Ibu", dad: "Ayah", allowance: "Uang saku minggu ini", chore: "Merapikan kamar", game: "Main game 30 menit", items: ["Camilan", "Es krim", "Main game 30 menit", "Stiker", "Komik"])
        case "nb": return Names(child1: "Jakob", child2: "Nora", mom: "Mamma", dad: "Pappa", allowance: "Ukens lommepenger", chore: "Ryddet rommet", game: "30 min spilling", items: ["Godteri", "Is", "30 min spilling", "Klistremerker", "Tegneserie"])
        case "nl": return Names(child1: "Daan", child2: "Julia", mom: "Mama", dad: "Papa", allowance: "Zakgeld deze week", chore: "Kamer opgeruimd", game: "30 min gamen", items: ["Snoep", "IJsje", "30 min gamen", "Stickers", "Stripboek"])
        case "pl": return Names(child1: "Antoni", child2: "Zosia", mom: "Mama", dad: "Tata", allowance: "Kieszonkowe na ten tydzień", chore: "Posprzątany pokój", game: "30 min gier", items: ["Słodycze", "Lody", "30 min gier", "Naklejki", "Komiks"])
        case "sv": return Names(child1: "Hugo", child2: "Alice", mom: "Mamma", dad: "Pappa", allowance: "Veckans veckopeng", chore: "Städat rummet", game: "30 min spel", items: ["Godis", "Glass", "30 min spel", "Klistermärken", "Serietidning"])
        case "tr": return Names(child1: "Yusuf", child2: "Zeynep", mom: "Annem", dad: "Babam", allowance: "Bu haftanın harçlığı", chore: "Odamı topladım", game: "30 dk oyun", items: ["Atıştırmalık", "Dondurma", "30 dk oyun", "Çıkartma", "Çizgi roman"])
        default: return names(for: "en")
        }
    }

    private static var language: String {
        let pref = Locale.preferredLanguages.first ?? "en"
        let known = ["en-GB", "zh-Hans", "zh-Hant", "pt-BR"]
        if let hit = known.first(where: { pref.hasPrefix($0) }) { return hit }
        if pref.hasPrefix("en") { return "en" }
        return String(pref.prefix(while: { $0 != "-" }))
    }
    #endif

    /// 장부를 비우고 가상의 네 식구로 다시 채운다.
    static func seedIfNeeded(context: ModelContext) {
        #if DEBUG
        guard isOn else { return }
        try? context.delete(model: MoneyTransaction.self)
        try? context.delete(model: Holding.self)
        try? context.delete(model: FamilyMember.self)
        try? context.delete(model: InvestProduct.self)
        try? context.delete(model: HouseholdItem.self)
        try? context.delete(model: FamilySettings.self)

        let lang = language
        let n = names(for: lang)
        let now = Date()
        let day: TimeInterval = 86_400

        let settings = FamilySettings()
        settings.currencyName = lang == "ko" ? "콩" : String(localized: "코인")
        settings.parentPIN = "0000"
        settings.weeklyInterestRate = 5
        settings.weeklyInflationRate = 2
        settings.wonPerCoin = 10
        settings.priceIndexHistory = [100, 102, 104.04, 106.12, 108.24]
        settings.priceIndex = 108.24
        settings.lastInflationDate = now
        settings.isSetupComplete = true
        context.insert(settings)

        let products = BankEngine.defaultProducts()
        let histories: [[Int]] = [
            [1000, 1012, 1020, 1031, 1040, 1046, 1055, 1062, 1070],
            [1000, 1045, 1100, 1062, 1150, 1198, 1171, 1230, 1262],
            [1000, 1150, 980, 1210, 1095, 1380, 1260, 1190, 1340]
        ]
        for (product, history) in zip(products, histories) {
            product.priceHistory = history
            product.price = history.last ?? product.price
            product.lastUpdate = now
            context.insert(product)
        }
        let turtle = products[0], rabbit = products[1]

        func member(_ name: String, _ emoji: String, _ role: MemberRole, balance: Int, savings: Int, offset: Double) -> FamilyMember {
            let m = FamilyMember(name: name, emoji: emoji, role: role)
            m.balance = balance
            m.savings = savings
            m.lastInterestDate = now
            m.createdAt = now.addingTimeInterval(-1000 + offset)
            context.insert(m)
            return m
        }
        let c1 = member(n.child1, "👦", .child, balance: 1240, savings: 3150, offset: 0)
        let c2 = member(n.child2, "👧", .child, balance: 860, savings: 1575, offset: 1)
        let mom = member(n.mom, "👩", .parent, balance: 0, savings: 0, offset: 2)
        _ = member(n.dad, "👨", .parent, balance: 0, savings: 0, offset: 3)

        func hold(_ m: FamilyMember, _ p: InvestProduct, _ qty: Int, cost: Int) {
            let h = Holding(member: m, product: p)
            h.quantity = qty
            h.totalCost = cost
            context.insert(h)
        }
        hold(c1, rabbit, 3, cost: 3300)
        hold(c1, turtle, 1, cost: 1020)
        hold(c2, turtle, 2, cost: 2040)

        func tx(_ m: FamilyMember, _ kind: TxKind, _ amount: Int, _ memo: String, daysAgo: Double, hour: Int, minute: Int) {
            let t = MoneyTransaction(kind: kind, amount: amount, memo: memo, member: m)
            let base = Calendar.current.startOfDay(for: now.addingTimeInterval(-daysAgo * day))
            t.date = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
            context.insert(t)
        }
        tx(c1, .allowance, 1000, n.allowance, daysAgo: 0, hour: 8, minute: 17)
        tx(c1, .receive, 300, n.chore, daysAgo: 1, hour: 10, minute: 5)
        tx(c1, .payment, 200, n.game, daysAgo: 2, hour: 18, minute: 30)
        tx(c1, .interest, 150, String(localized: "저축 이자 (주 \(5.0.cleanPercent)%, \(1)주)"), daysAgo: 3, hour: 9, minute: 0)
        tx(c1, .buy, 1150, String(localized: "\(rabbit.displayName) \(1)주 매수 (@\(1150.comma))"), daysAgo: 4, hour: 16, minute: 42)
        tx(c2, .allowance, 1000, n.allowance, daysAgo: 0, hour: 8, minute: 18)
        tx(c2, .deposit, 500, String(localized: "저축통장에 입금"), daysAgo: 2, hour: 19, minute: 10)
        tx(mom, .receive, 200, String(localized: "\(n.child1)에게 받음 · \(n.game)"), daysAgo: 2, hour: 18, minute: 30)

        let prices = [1500, 2000, 3000, 1000, 5000]
        let emojis = ["🍪", "🍦", "🎮", "⭐️", "📚"]
        for i in 0..<5 {
            let item = HouseholdItem(name: n.items[i], emoji: emojis[i], priceWon: prices[i])
            item.createdAt = now.addingTimeInterval(Double(i))
            context.insert(item)
        }
        try? context.save()
        #endif
    }
}
