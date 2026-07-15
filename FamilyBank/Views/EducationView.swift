//
//  EducationView.swift
//  쑥쑥용돈
//
//  배우기: 부모가 아이에게 경제를 가르쳐 주기 위한 단계별 가이드
//  각 단계 = 학습 목표 → 설명 스크립트 → 질문 → 앱으로 함께 해보기 → 핵심 한 줄
//

import SwiftUI
import Charts

struct Lesson: Identifiable {
    let id = UUID()
    let step: Int
    let emoji: String
    let title: String
    /// 이 단계에서 아이가 알게 되는 것
    let goal: String
    /// 아이에게 그대로 읽어 줘도 되는 눈높이 설명
    let script: String
    /// 아이에게 던져 볼 질문들
    let questions: [String]
    /// 앱 기능과 연결된 실습 활동
    let activity: String
    /// 한 줄 정리
    let keyPoint: String
}

struct EducationView: View {
    let settings: FamilySettings

    private let lessons: [Lesson] = [
        Lesson(step: 1, emoji: "💰", title: "돈은 왜 필요할까?",
               goal: "돈이 왜 생겨났고 어떤 일을 하는지 알기",
               script: "네가 물고기를 갖고 있는데 신발이 필요하다고 해 보자. 신발 가게 아저씨가 물고기를 싫어하면 바꿀 수가 없겠지? 옛날 사람들도 이게 너무 불편했어. 그래서 누구나 좋아하는 '돈'을 만들었단다.\n\n돈은 세 가지 일을 해. 첫째, 뭐든지 바꿀 수 있어(교환). 둘째, 물건마다 얼마짜리인지 잴 수 있어(가치 재기). 셋째, 모아 뒀다가 나중에 쓸 수 있어(저장).",
               questions: [
                "만약 세상에 돈이 없다면 어떤 일이 생길까?",
                "우리집 코인으로는 뭘 바꿀 수 있을까?"
               ],
               activity: "시장 탭 → 우리집 가게 가격표를 함께 보면서, 물건마다 가격이 다른 이유를 이야기해 보세요.",
               keyPoint: "돈은 바꾸고, 재고, 모아 두는 도구예요."),

        Lesson(step: 2, emoji: "💎", title: "좋은 돈의 조건",
               goal: "아무거나 돈이 될 수 없는 이유(화폐의 속성) 알기",
               script: "왜 길가의 모래는 돈이 될 수 없을까? 아무 데나 잔뜩 있으니까! 좋은 돈이 되려면 다섯 가지 시험을 통과해야 해.\n\n① 오래 가야 해(썩으면 안 돼) ② 갖고 다니기 쉬워야 해(소는 무거워서 탈락!) ③ 잘게 나눌 수 있어야 해 ④ 흔하지 않아야 해 ⑤ 모두가 '이건 진짜 돈이야'라고 믿어야 해.\n\n우리집 코인도 엄마 아빠가 아무 때나 마구 찍어내지 않고 약속을 지키니까 가치가 있는 거야.",
               questions: [
                "레고 블록은 돈이 될 수 있을까? 다섯 가지 시험을 통과할까?",
                "우리집 코인은 왜 가치가 있을까?"
               ],
               activity: "집에 있는 물건 3개를 골라 '돈이 될 수 있을까?' 게임을 해 보세요. 다섯 조건에 O/X를 매겨 봅니다.",
               keyPoint: "희소하고 모두가 믿어야 돈이 돼요."),

        Lesson(step: 3, emoji: "🛒", title: "필요와 욕구",
               goal: "꼭 필요한 것과 갖고 싶은 것 구분하기",
               script: "'필요'는 없으면 곤란한 것이야. 밥, 옷, 학용품 같은 거지. '욕구'는 있으면 신나지만 없어도 사는 데 문제없는 것이야. 장난감, 게임 아이템 같은 거란다.\n\n둘 다 소중해! 하지만 순서가 중요해. 필요한 걸 먼저 챙기고, 남는 돈으로 계획을 세워서 욕구를 채우는 거야.",
               questions: [
                "요즘 사고 싶은 것들 중에 '필요'는 뭐고 '욕구'는 뭘까?",
                "필요한 걸 안 사고 욕구부터 채우면 어떤 일이 생길까?"
               ],
               activity: "우리집 가게 물품을 함께 보면서 하나씩 '필요'와 '욕구'로 나눠 보세요.",
               keyPoint: "필요 먼저, 욕구는 그다음!"),

        Lesson(step: 4, emoji: "⚖️", title: "기회비용",
               goal: "선택하면 포기하는 것이 생긴다는 것 알기",
               script: "1,000코인이 있는데 과자도 사고 싶고 스티커도 사고 싶어. 그런데 돈은 한 번 쓸 만큼만 있어. 어떡하지? 하나를 고르면 다른 하나는 포기해야 해.\n\n이때 포기한 것을 '기회비용'이라고 불러. 돈뿐만 아니라 시간도 그래. 게임을 1시간 하면, 그 시간에 할 수 있었던 다른 일을 포기한 거야.",
               questions: [
                "지난번에 뭘 사느라 뭘 포기했었지?",
                "게임 1시간의 기회비용은 뭘까?"
               ],
               activity: "아이가 가게에서 결제하기 전에, \"이 돈으로 살 수 있는 다른 것 한 가지\"를 꼭 말해 보게 하세요.",
               keyPoint: "모든 선택에는 포기한 것이 숨어 있어요."),

        Lesson(step: 5, emoji: "🏦", title: "저축과 이자",
               goal: "저축하면 돈이 늘어나는 원리 알기",
               script: "은행에 돈을 맡기면 은행이 '맡겨 줘서 고마워!' 하면서 덤을 줘. 그 덤이 '이자'야.\n\n지갑에 넣어 둔 돈은 아무리 기다려도 안 늘어나. 그런데 저축통장에 넣으면 매주 이자가 붙어서 돈이 자라나. 당장 쓰지 않을 돈을 어디에 두면 좋을까?",
               questions: [
                "1,000코인을 이자 5%로 맡기면 일주일 뒤 얼마가 될까?",
                "지갑에 둔 돈과 저축한 돈, 뭐가 다를까?"
               ],
               activity: "아이 지갑의 절반을 저축통장에 넣어 보세요. 일주일 뒤 이자가 붙은 걸 함께 확인하면 효과 만점!",
               keyPoint: "당장 안 쓸 돈은 저축통장으로!"),

        Lesson(step: 6, emoji: "⛄️", title: "복리의 마법",
               goal: "이자에 이자가 붙으면 눈덩이처럼 커진다는 것 알기",
               script: "눈덩이를 굴리면 어떻게 되지? 구를수록 점점 빨리 커지지? 복리가 딱 그거야.\n\n1,000코인에 이자 50이 붙으면 1,050이 돼. 다음 주에는 1,050 전체에 이자가 붙어. 이자가 벌어 온 돈에도 또 이자가 붙는 거야! 처음엔 티가 안 나지만 시간이 지날수록 눈덩이처럼 불어나.",
               questions: [
                "저축을 일찍 시작한 사람과 늦게 시작한 사람, 나중에 누가 더 부자가 될까?"
               ],
               activity: "아래 '복리 계산기'에서 기간을 4주에서 52주로 늘려 보세요. 그래프가 점점 가팔라지는 걸 함께 관찰!",
               keyPoint: "일찍, 꾸준히 — 이게 복리의 비밀이에요."),

        Lesson(step: 7, emoji: "🎈", title: "인플레이션",
               goal: "물가가 오르면 돈의 힘이 줄어든다는 것 알기",
               script: "작년에 1,000원이던 과자가 올해 1,100원이 됐어. 과자가 커진 것도 아닌데! 이렇게 물건값이 오르는 걸 '인플레이션'이라고 해.\n\n내 돈의 숫자는 그대로인데 살 수 있는 게 줄어들어. 풍선에서 바람이 빠지듯 돈의 힘이 약해지는 거야. 그래서 돈을 지갑에 가만히 두면 조금씩 손해란다. 이자를 받거나 투자해서 물가보다 빨리 불려야 돈의 힘을 지킬 수 있어.",
               questions: [
                "물가가 오르면 지갑에 돈을 그냥 두는 게 좋을까?",
                "우리집 물가지수는 지금 얼마일까?"
               ],
               activity: "시장 탭에서 물가지수와 물가 추이 그래프를 함께 보고, 아래 '인플레이션 체험'으로 실험해 보세요.",
               keyPoint: "물가가 오르면 돈의 힘은 줄어요. 그래서 저축과 투자가 필요해요."),

        Lesson(step: 8, emoji: "🍎", title: "수요와 공급",
               goal: "가격이 어떻게 정해지는지 알기",
               script: "비 오는 날 우산 장수를 생각해 봐. 우산을 사려는 사람은 많은데 우산이 몇 개 없으면? 값을 올려도 팔려. 반대로 여름이 끝난 수영복은? 사려는 사람이 없어서 싸게 팔아야 해.\n\n이렇게 가격은 '사려는 마음(수요)'과 '팔려는 양(공급)'이 밀고 당기면서 정해져. 투자 상품 가격이 오르내리는 것도 같은 원리야.",
               questions: [
                "크리스마스에 인기 장난감이 비싸지는 이유는 뭘까?",
                "모두가 팔고 싶어 하는 물건의 가격은 어떻게 될까?"
               ],
               activity: "시장 탭에서 투자 상품 가격이 매일 변하는 걸 보며 '사려는 사람이 많으면 오른다'를 이야기해 보세요.",
               keyPoint: "가격은 사려는 마음과 팔려는 양이 만나서 정해져요."),

        Lesson(step: 9, emoji: "📈", title: "투자와 위험",
               goal: "고수익에는 고위험이 따른다는 것 알기",
               script: "투자는 돈을 심는 거야. 씨앗이 잘 자라면 큰 나무가 되지만, 시들 수도 있어. 저축과 달리 투자는 돈이 늘 수도, 줄 수도 있단다.\n\n꼭 기억할 규칙: 크게 벌 수 있는 것일수록 크게 잃을 수도 있어. 그리고 계란을 한 바구니에 다 담으면 떨어뜨렸을 때 전부 깨져. 나눠 담아야 해(분산투자). 잃어도 괜찮은 만큼만 심는 거야.",
               questions: [
                "거북이 펀드와 로켓 펀드, 어떤 게 더 위험할까? 왜?",
                "잃어도 괜찮은 돈은 얼마일까?"
               ],
               activity: "아이와 함께 적은 돈으로 상품 2개에 나눠 투자해 보세요. 매일 가격을 같이 확인하면서 오르내림에 익숙해지게 해 주세요.",
               keyPoint: "수익이 크면 위험도 커요. 나눠 담고, 잃어도 되는 만큼만!"),

        Lesson(step: 10, emoji: "📝", title: "예산 세우기",
               goal: "돈을 계획해서 나눠 쓰는 습관 만들기",
               script: "용돈을 받자마자 계획 없이 쓰면 금방 사라져 버려. 그래서 미리 계획을 세우는 거야. 이걸 '예산'이라고 해.\n\n예를 들면 이렇게 나눠 봐. 저축 30, 필요한 것 40, 하고 싶은 것 20, 투자 도전 10. 꼭 이대로가 아니어도 돼. 네가 직접 정하는 게 중요해!",
               questions: [
                "이번 주 용돈을 어떻게 나누고 싶어?",
                "지난주에는 어디에 돈을 제일 많이 썼을까?"
               ],
               activity: "용돈 주는 날, 아이가 직접 저축·투자·소비 비율을 정해서 실행하게 하세요. 일주일 뒤 기록 탭을 함께 보며 돌아봅니다.",
               keyPoint: "계획이 있는 돈이 오래 가요.")
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(lessons) { lesson in
                        NavigationLink {
                            LessonDetailView(lesson: lesson)
                        } label: {
                            HStack(spacing: 12) {
                                Text(lesson.emoji)
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(lesson.step)단계 · \(lesson.title)")
                                        .font(.subheadline.weight(.semibold))
                                    Text(lesson.goal)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } header: {
                    Text("부모 가이드 📖")
                } footer: {
                    Text("아이와 함께 1단계부터 차근차근. 각 단계는 '설명해 주기 → 물어보기 → 함께 해보기' 순서로 10분이면 충분해요.")
                }

                Section("함께 실험하기 · 복리 계산기 🧮") {
                    CompoundCalculatorView(settings: settings)
                }

                Section("함께 실험하기 · 인플레이션 체험 🎈") {
                    InflationSimulatorView(settings: settings)
                }
            }
            .navigationTitle("🎓 배우기")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - 가이드 상세

struct LessonDetailView: View {
    let lesson: Lesson

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 헤더
                HStack {
                    Text(lesson.emoji)
                        .font(.system(size: 48))
                    VStack(alignment: .leading) {
                        Text("\(lesson.step)단계")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.tint)
                        Text(lesson.title)
                            .font(.title2.weight(.bold))
                    }
                }

                // 학습 목표
                guideCard(icon: "🎯", title: "오늘 배울 것") {
                    Text(lesson.goal)
                        .font(.subheadline)
                }

                // 설명 스크립트
                guideCard(icon: "🗣️", title: "아이에게 이렇게 말해 보세요") {
                    Text(lesson.script)
                        .font(.body)
                        .lineSpacing(6)
                }

                // 질문
                guideCard(icon: "💬", title: "이렇게 물어보세요") {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(lesson.questions, id: \.self) { q in
                            HStack(alignment: .top, spacing: 8) {
                                Text("❝")
                                    .font(.headline)
                                    .foregroundStyle(.tint)
                                Text(q)
                                    .font(.subheadline)
                            }
                        }
                    }
                }

                // 함께 해보기
                guideCard(icon: "🙌", title: "앱으로 함께 해보기", tint: .green) {
                    Text(lesson.activity)
                        .font(.subheadline)
                        .lineSpacing(4)
                }

                // 핵심 한 줄
                HStack(spacing: 10) {
                    Text("⭐️")
                        .font(.title3)
                    Text(lesson.keyPoint)
                        .font(.subheadline.weight(.bold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.yellow.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func guideCard<Content: View>(icon: String, title: String, tint: Color = .accentColor,
                                          @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(icon)
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(tint)
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - 복리 계산기

struct CompoundCalculatorView: View {
    let settings: FamilySettings

    @State private var principal: Double = 1000
    @State private var rate: Double = 5
    @State private var weeks: Double = 12

    private var projection: [ChartPoint] {
        var result: [ChartPoint] = [ChartPoint(id: 0, value: Int(principal))]
        var current = principal
        for week in 1...Int(weeks) {
            current *= (1 + rate / 100)
            result.append(ChartPoint(id: week, value: Int(current.rounded())))
        }
        return result
    }

    private var finalAmount: Int { projection.last?.value ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("처음 금액: \(Int(principal).comma) \(settings.currencyName)")
                    .font(.subheadline.weight(.medium))
                Slider(value: $principal, in: 100...50000, step: 100)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("주간 이자율: \(rate.cleanPercent)%")
                    .font(.subheadline.weight(.medium))
                Slider(value: $rate, in: 1...20, step: 0.5)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("기간: \(Int(weeks))주")
                    .font(.subheadline.weight(.medium))
                Slider(value: $weeks, in: 4...52, step: 1)
            }

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

            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(weeks))주 뒤: \(finalAmount.comma) \(settings.currencyName)")
                    .font(.headline)
                    .foregroundStyle(.purple)
                Text("이자로만 \((finalAmount - Int(principal)).comma) \(settings.currencyName)을(를) 벌었어요!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - 인플레이션 체험 계산기

/// 지갑에 그냥 둔 돈 vs 저축한 돈의 '실질 가치(구매력)'를 비교해서
/// 물가가 오르면 왜 저축·투자가 필요한지 보여준다.
struct InflationSimulatorView: View {
    let settings: FamilySettings

    @State private var inflationRate: Double
    @State private var interestRate: Double
    @State private var weeks: Double = 26

    private let principal: Double = 1000

    init(settings: FamilySettings) {
        self.settings = settings
        _inflationRate = State(initialValue: max(0.5, settings.weeklyInflationRate))
        _interestRate = State(initialValue: max(0.5, settings.weeklyInterestRate))
    }

    /// 주차별 (지갑에 둔 돈의 실질 가치, 저축한 돈의 실질 가치)
    private struct SimPoint: Identifiable {
        let id: Int
        let series: String
        let value: Int
    }

    private var points: [SimPoint] {
        var result: [SimPoint] = []
        for week in 0...Int(weeks) {
            let priceLevel = pow(1 + inflationRate / 100, Double(week))
            let wallet = principal / priceLevel
            let saved = principal * pow(1 + interestRate / 100, Double(week)) / priceLevel
            result.append(SimPoint(id: week, series: "지갑에 둔 돈", value: Int(wallet.rounded())))
            result.append(SimPoint(id: week, series: "저축한 돈", value: Int(saved.rounded())))
        }
        return result
    }

    private var walletFinal: Int {
        Int((principal / pow(1 + inflationRate / 100, weeks)).rounded())
    }
    private var savedFinal: Int {
        Int((principal * pow(1 + interestRate / 100, weeks) / pow(1 + inflationRate / 100, weeks)).rounded())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("1,000 \(settings.currencyName)의 '진짜 힘'은 어떻게 변할까요?")
                .font(.subheadline.weight(.medium))

            VStack(alignment: .leading, spacing: 4) {
                Text("주간 물가 상승률: \(inflationRate.cleanPercent)%")
                    .font(.subheadline.weight(.medium))
                Slider(value: $inflationRate, in: 0.5...10, step: 0.5)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("주간 저축 이자율: \(interestRate.cleanPercent)%")
                    .font(.subheadline.weight(.medium))
                Slider(value: $interestRate, in: 0.5...20, step: 0.5)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("기간: \(Int(weeks))주")
                    .font(.subheadline.weight(.medium))
                Slider(value: $weeks, in: 4...52, step: 1)
            }

            Chart(points) { point in
                LineMark(
                    x: .value("주", point.id),
                    y: .value("실질 가치", point.value)
                )
                .foregroundStyle(by: .value("구분", point.series))
                .interpolationMethod(.catmullRom)
            }
            .chartForegroundStyleScale([
                "지갑에 둔 돈": Color.orange,
                "저축한 돈": Color.blue
            ])
            .frame(height: 160)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(weeks))주 뒤 살 수 있는 것의 가치")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 16) {
                    Label("지갑: \(walletFinal.comma)", systemImage: "wallet.pass.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.orange)
                    Label("저축: \(savedFinal.comma)", systemImage: "building.columns.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.blue)
                }
                Text(savedFinal > walletFinal
                     ? "지갑에 그냥 둔 돈은 힘이 줄었지만, 저축한 돈은 지켜냈어요! 💪"
                     : "이자율이 물가 상승률보다 낮으면 저축해도 돈의 힘이 줄어요. 이자율을 올려 보세요!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}
