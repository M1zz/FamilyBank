//
//  FamilyBankRoadmap.swift
//  FamilyBank (쑥쑥용돈)
//
//  **앞으로 만들 것**의 원본. 부모 모드 ▸ 은행 설정 ▸ 앞으로 만들 기능(`LeeoRoadmapView`)이 이 목록을 그대로 보여 준다.
//
//  ⚠️ 개발하다 "이건 다음에" 가 생기면 **여기에 한 줄을 더한다.** 코드의 TODO 주석으로만 남기지 않는다.
//     - 새 항목: `.planned`. 손대기 시작하면 `.building`. 내보내면 `.shipped("1.2.0")`.
//     - id 는 한 번 정하면 바꾸지 않는다(문구는 바꿔도 된다).
//     - 문구는 사용자 말로 쓴다(내부 이름 · 기술 용어 금지). 영어는 FamilyBank/Localizable.xcstrings 에 넣는다
//       (영어가 빠지면 영어 쓰는 사람에게 한국어가 보인다).
//     - 사용자에게 보일 만한 것만 적는다. 리팩터링 · 시험 · 빌드 설정은 `.sprintcommander/tasks.json` 의 몫이다.
//

import SwiftUI
import LeeoKit

extension FamilyBankSpec {
    static var roadmap: [LeeoRoadmapItem] {[
        // MARK: 다음에 만들어요
        .init(id: "a11y.voiceover", status: .building,
              title: NSLocalizedString("VoiceOver로 더 편하게", comment: "Roadmap item: better VoiceOver support"),
              detail: NSLocalizedString("VoiceOver가 잔액과 단추를 빠짐없이, 알맞은 순서로 읽어 줘요.", comment: "Roadmap item detail: better VoiceOver support")),
        .init(id: "a11y.largetext", status: .building,
              title: NSLocalizedString("큰 글씨에 맞춘 화면", comment: "Roadmap item: layouts for larger text"),
              detail: NSLocalizedString("글자 크기를 키워도 잘리지 않고 보기 좋게 다시 배치돼요.", comment: "Roadmap item detail: layouts for larger text")),
        .init(id: "a11y.contrast", status: .building,
              title: NSLocalizedString("보기 편한 색과 대비", comment: "Roadmap item: better colors and contrast"),
              detail: NSLocalizedString("대비를 높이거나 색을 구별하기 어려워도 잔액과 기록을 알아볼 수 있어요.", comment: "Roadmap item detail: better colors and contrast")),
        .init(id: "a11y.motion", status: .building,
              title: NSLocalizedString("움직임 줄이기", comment: "Roadmap item: respect Reduce Motion"),
              detail: NSLocalizedString("움직임 줄이기를 켜면 화면 효과가 차분해져요.", comment: "Roadmap item detail: respect Reduce Motion")),
        .init(id: "lang.english", status: .planned,
              title: NSLocalizedString("영어 지원", comment: "Roadmap item: English language"),
              detail: NSLocalizedString("앱을 영어로도 쓸 수 있어요.", comment: "Roadmap item detail: English language")),
        .init(id: "lang.more", status: .planned,
              title: NSLocalizedString("더 많은 언어", comment: "Roadmap item: more languages"),
              detail: NSLocalizedString("더 많은 나라 말로 앱을 쓸 수 있게 해요.", comment: "Roadmap item detail: more languages")),
        .init(id: "whatsnew", status: .planned,
              title: NSLocalizedString("업데이트 소식", comment: "Roadmap item: what's new after an update"),
              detail: NSLocalizedString("업데이트 뒤 처음 열 때 무엇이 새로 생겼는지 알려 줘요.", comment: "Roadmap item detail: what's new after an update")),
        .init(id: "tips", status: .planned,
              title: NSLocalizedString("쓰는 요령 알려 주기", comment: "Roadmap item: in-app tips"),
              detail: NSLocalizedString("알아 두면 편한 기능을 알맞은 때에 살짝 알려 줘요.", comment: "Roadmap item detail: in-app tips")),
        .init(id: "haptics", status: .planned,
              title: NSLocalizedString("손끝으로 느끼는 반응", comment: "Roadmap item: haptic feedback"),
              detail: NSLocalizedString("용돈을 받거나 물건을 샀을 때 가볍게 떨려서 알려 줘요.", comment: "Roadmap item detail: haptic feedback")),
        .init(id: "widgets", status: .planned,
              title: NSLocalizedString("홈 화면 위젯", comment: "Roadmap item: home screen widgets"),
              detail: NSLocalizedString("앱을 열지 않고 홈 화면에서 아이의 잔액을 바로 확인해요.", comment: "Roadmap item detail: home screen widgets")),
        .init(id: "shortcuts", status: .planned,
              title: NSLocalizedString("Siri와 단축어", comment: "Roadmap item: Siri and Shortcuts"),
              detail: NSLocalizedString("Siri에게 물어 아이의 잔액을 바로 확인해요.", comment: "Roadmap item detail: Siri and Shortcuts")),
        .init(id: "backup", status: .planned,
              title: NSLocalizedString("백업과 내보내기", comment: "Roadmap item: backup and export"),
              detail: NSLocalizedString("우리집 은행 기록을 파일로 저장하고 다시 불러올 수 있어요.", comment: "Roadmap item detail: backup and export")),
        .init(id: "notifications", status: .planned,
              title: NSLocalizedString("용돈 알림", comment: "Roadmap item: notifications"),
              detail: NSLocalizedString("용돈 주는 날이나 이자가 붙을 때 알림으로 알려 줘요.", comment: "Roadmap item detail: notifications")),
        .init(id: "fold", status: .planned,
              title: NSLocalizedString("펼치는 아이폰 화면", comment: "Roadmap item: foldable iPhone layout"),
              detail: NSLocalizedString("펼치는 아이폰에서 넓은 화면을 두 쪽으로 나눠 써요.", comment: "Roadmap item detail: foldable iPhone layout")),
        .init(id: "autosave", status: .planned,
              title: NSLocalizedString("쓰던 내용 이어 쓰기", comment: "Roadmap item: keep unsaved drafts"),
              detail: NSLocalizedString("적다가 앱이 꺼져도 쓰던 내용이 남아 있어요.", comment: "Roadmap item detail: keep unsaved drafts")),
    ]}
}

// MARK: - 화면

/// 은행 설정 ▸ 앞으로 만들 기능. "이런 기능이 있으면 좋겠어요" 는 기능 제안으로 시작하는 피드백 창을 연다.
struct RoadmapScreen: View {
    @State private var showFeedback = false

    var body: some View {
        LeeoRoadmapView<FamilyBankSpec>(onSuggest: { showFeedback = true })
            .sheet(isPresented: $showFeedback) {
                NavigationStack {
                    LeeoFeedbackView<FamilyBankSpec>(initialType: .feature)
                }
            }
    }
}
