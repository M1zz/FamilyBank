//
//  EducationView.swift
//  FamilyBank — 우리집 은행
//
//  경제 교육: 개념 배우기 + 복리 계산기
//

import SwiftUI
import Charts

struct Lesson: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let summary: String
    let content: String
}

struct EducationView: View {
    let settings: FamilySettings

    private let lessons: [Lesson] = [
        Lesson(emoji: "💰", title: "돈은 왜 필요할까?",
               summary: "물물교환에서 화폐까지",
               content: "아주 옛날에는 물고기와 쌀을 직접 바꾸는 '물물교환'을 했어요. 하지만 서로 원하는 물건이 다르면 교환이 어려웠지요. 그래서 사람들은 모두가 가치를 인정하는 '돈(화폐)'을 만들었어요.\n\n돈에는 세 가지 역할이 있어요. 첫째, 물건과 바꿀 수 있어요(교환 수단). 둘째, 물건의 가치를 잴 수 있어요(가치 척도). 셋째, 모아 두었다가 나중에 쓸 수 있어요(가치 저장).\n\n우리집 화폐도 마찬가지예요. 열심히 모아서 원하는 것과 바꿔 보세요!"),
        Lesson(emoji: "💎", title: "좋은 돈의 조건",
               summary: "아무거나 돈이 될 수 없는 이유",
               content: "옛날 사람들은 조개껍데기, 소금, 금을 돈으로 썼어요. 그런데 왜 모래나 나뭇잎은 돈이 되지 못했을까요? 좋은 돈이 되려면 다섯 가지 조건이 필요하기 때문이에요.\n\n① 오래 가야 해요(내구성) — 며칠 만에 썩으면 모아 둘 수 없어요.\n② 들고 다니기 쉬워야 해요(휴대성) — 소는 가치 있지만 주머니에 못 넣죠!\n③ 나눌 수 있어야 해요(분할성) — 작은 물건을 살 때는 돈도 잘게 나눠져야 해요.\n④ 흔하지 않아야 해요(희소성) — 아무 데나 있는 모래가 돈이면 아무도 일하지 않을 거예요.\n⑤ 모두가 믿어야 해요(신뢰) — 다들 받아 주지 않으면 종이 조각일 뿐이에요.\n\n우리집 화폐도 마찬가지예요. 부모님이 아무 때나 마구 찍어내지 않고 약속을 지키기 때문에 가치가 있는 거랍니다."),
        Lesson(emoji: "🎈", title: "인플레이션",
               summary: "물가가 오르면 내 돈의 힘이 줄어요",
               content: "작년에 과자 한 봉지가 1,000이었는데 올해는 1,100이 되었다면? 물건 값이 오르는 것을 '인플레이션(물가 상승)'이라고 해요.\n\n물가가 오르면 내 돈의 숫자는 그대로여도 살 수 있는 것이 줄어들어요. 즉, 돈의 '힘(구매력)'이 약해지는 거예요. 풍선에서 바람이 빠지듯이요!\n\n인플레이션은 왜 생길까요? 사고 싶은 사람은 많은데 물건이 부족하거나, 돈이 세상에 너무 많이 풀리면 물가가 올라요. 돈이 흔해지면 돈의 가치가 떨어지거든요(희소성 기억나죠?).\n\n그래서 돈을 지갑에 그냥 두면 조금씩 손해예요. 이자를 주는 저축이나 투자로 물가 상승보다 빠르게 돈을 불려야 돈의 힘을 지킬 수 있어요. 아래 인플레이션 체험 계산기로 직접 확인해 보세요!"),
        Lesson(emoji: "🍎", title: "수요와 공급",
               summary: "가격은 누가 정할까?",
               content: "물건의 가격은 '사고 싶은 마음(수요)'과 '팔려는 양(공급)'이 만나서 정해져요.\n\n사고 싶은 사람은 많은데 물건이 조금밖에 없으면? 가격이 올라가요. 비 오는 날 우산 가게를 생각해 보세요. 반대로 물건은 많은데 사려는 사람이 없으면 가격이 내려가요. 여름이 끝난 뒤의 수영복처럼요.\n\n투자 상품의 가격도 똑같아요. 사려는 사람이 많으면 오르고, 팔려는 사람이 많으면 내려가요.\n\n똑똑한 소비자는 이걸 이용해요. 모두가 살 때보다, 아무도 관심 없을 때 사면 같은 물건을 더 싸게 살 수 있답니다!"),
        Lesson(emoji: "🏦", title: "저축과 이자",
               summary: "은행에 돈을 맡기면 왜 돈이 늘어날까?",
               content: "은행에 돈을 맡기는 것을 '저축(예금)'이라고 해요. 은행은 돈을 맡겨 줘서 고맙다는 뜻으로 '이자'를 줘요.\n\n예를 들어 1,000을 저축하고 이자율이 5%라면, 일주일 뒤에는 1,050이 돼요. 아무것도 하지 않아도 50이 늘어난 거예요!\n\n지갑에 돈을 그냥 두면 이자가 붙지 않아요. 당장 쓰지 않을 돈은 저축통장에 넣어 두는 것이 현명해요."),
        Lesson(emoji: "⛄️", title: "복리의 마법",
               summary: "이자가 이자를 낳는다!",
               content: "복리는 '이자에도 이자가 붙는 것'이에요.\n\n1,000을 이자율 5%로 저축하면 1주 뒤 1,050이 돼요. 2주 뒤에는 1,050의 5%인 52가 붙어서 1,102가 돼요. 이자(50)에도 이자(2)가 붙었죠?\n\n처음에는 차이가 작지만 시간이 지날수록 눈덩이처럼 커져요. 그래서 '일찍, 꾸준히' 저축하는 사람이 결국 부자가 된답니다. 아래 복리 계산기로 직접 실험해 보세요!"),
        Lesson(emoji: "📈", title: "투자와 위험",
               summary: "높은 수익에는 높은 위험이 따라요",
               content: "투자는 돈을 더 불리기 위해 주식이나 펀드 같은 상품을 사는 거예요. 저축과 달리 투자는 돈이 늘어날 수도, 줄어들 수도 있어요.\n\n중요한 규칙: 수익이 클 수 있는 상품일수록 위험도 커요(고수익 = 고위험). 🐢 안정형은 조금씩 꾸준히, 🚀 위험형은 크게 오르내려요.\n\n투자의 지혜: 한 상품에 모든 돈을 넣지 말고 나눠 담으세요(분산투자). 그리고 잃어도 괜찮은 만큼만 투자하세요!"),
        Lesson(emoji: "🛒", title: "필요와 욕구",
               summary: "사고 싶은 것 vs 꼭 필요한 것",
               content: "'필요'는 살아가는 데 꼭 있어야 하는 것이에요. 밥, 옷, 학용품 같은 것들이죠.\n'욕구'는 있으면 좋지만 없어도 되는 것이에요. 장난감, 게임 아이템, 군것질 같은 것들이에요.\n\n돈을 쓰기 전에 스스로에게 물어보세요. \"이건 필요한 걸까, 갖고 싶은 걸까?\"\n\n욕구를 위한 소비가 나쁜 것은 아니에요. 하지만 필요한 것을 먼저 챙기고, 남은 돈으로 계획을 세워 욕구를 채우는 것이 현명한 소비예요."),
        Lesson(emoji: "⚖️", title: "기회비용",
               summary: "하나를 선택하면 다른 하나를 포기하는 것",
               content: "1,000이 있는데 과자(1,000)도 사고 싶고 스티커(1,000)도 사고 싶다면? 둘 중 하나만 골라야 해요.\n\n과자를 선택하면 포기한 스티커가 바로 '기회비용'이에요. 모든 선택에는 포기하는 것이 숨어 있답니다.\n\n돈을 쓸 때는 항상 생각해 보세요. \"이 돈으로 할 수 있는 다른 일은 뭘까? 그것보다 이게 더 좋을까?\" 이런 습관이 현명한 결정을 만들어요."),
        Lesson(emoji: "📝", title: "예산 세우기",
               summary: "계획이 있는 돈이 오래 간다",
               content: "예산은 '돈을 어떻게 쓸지 미리 세우는 계획'이에요.\n\n용돈을 받으면 이렇게 나눠 보세요.\n· 저축 (미래를 위해): 30%\n· 필요한 것: 40%\n· 하고 싶은 것: 20%\n· 투자 도전: 10%\n\n기록도 중요해요! '기록' 탭에서 내가 어디에 돈을 썼는지 살펴보고, 다음 계획을 더 좋게 만들어 보세요.")
    ]

    var body: some View {
        NavigationStack {
            List {
                Section("경제 개념 배우기") {
                    ForEach(lessons) { lesson in
                        NavigationLink {
                            LessonDetailView(lesson: lesson)
                        } label: {
                            HStack(spacing: 12) {
                                Text(lesson.emoji)
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(lesson.title)
                                        .font(.subheadline.weight(.semibold))
                                    Text(lesson.summary)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                Section("복리 계산기 🧮") {
                    CompoundCalculatorView(settings: settings)
                }

                Section("인플레이션 체험 🎈") {
                    InflationSimulatorView(settings: settings)
                }
            }
            .navigationTitle("🎓 배우기")
        }
    }
}

// MARK: - 개념 상세

struct LessonDetailView: View {
    let lesson: Lesson

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(lesson.emoji)
                        .font(.system(size: 48))
                    VStack(alignment: .leading) {
                        Text(lesson.title)
                            .font(.title2.weight(.bold))
                        Text(lesson.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(lesson.content)
                    .font(.body)
                    .lineSpacing(6)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
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
