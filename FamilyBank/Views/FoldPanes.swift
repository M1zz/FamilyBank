//
//  FoldPanes.swift
//  쑥쑥용돈
//
//  아이폰 듀오를 폈을 때 접힌 선 양쪽에 무엇이 서는가.
//  자리 셈 · 시트 가드 · 탭 막대는 LeeoKit Fold 모듈이 하고, 여기는 이 앱의 짝만 정한다.
//
//  - 부모 화면: 고르는 쪽(가로면 왼쪽, 세로면 아래)에 액션 · 시장 · 기록 · 배우기 중 고른 탭,
//    결과 쪽(오른쪽, 위)에 대시보드. 용돈을 주거나 결제하면 옆의 대시보드가 바로 바뀐다.
//    대시보드 탭은 따로 서지 않고, 펼친 탭 막대에는 넷만 선다.
//  - 자녀 폰 모드: 같은 규칙으로 결과 쪽에 내 지갑.
//  - 접혀 있거나 보통 아이폰이면 `FoldTab` 은 그 탭만 그린다 — 지금 화면 그대로.
//    탭 구조가 그대로라 펴고 접어도 보던 화면 · 적던 금액이 남는다.
//

import SwiftUI
import LeeoKit

/// 펼친 화면의 탭 한 장: 고르는 쪽에 그 탭 | 결과 쪽에 `result`.
struct FoldTab<Choose: View, Result: View>: View {
    @ViewBuilder let choose: () -> Choose
    @ViewBuilder let result: () -> Result

    var body: some View {
        FoldSplitView {
            choose()
        } result: {
            result()
                // 결과 쪽 판 안에서는 접히지 않은 화면처럼 선다.
                .environment(\.foldLayout, .single)
        }
        .foldTabBarRoom()
    }
}

extension View {
    /// 펼쳤을 때 결과 쪽에 늘 서 있는 탭(`resultTab`)에 있었다면 `fallback` 으로 옮긴다.
    func foldResultTabRedirect(_ tab: Binding<Int>, resultTab: Int, fallback: Int) -> some View {
        modifier(FoldResultTabRedirect(tab: tab, resultTab: resultTab, fallback: fallback))
    }
}

private struct FoldResultTabRedirect: ViewModifier {
    @Environment(\.foldLayout) private var fold
    @Binding var tab: Int
    let resultTab: Int
    let fallback: Int

    func body(content: Content) -> some View {
        content.onChange(of: fold.isUnfolded, initial: true) { _, unfolded in
            if unfolded, tab == resultTab { tab = fallback }
        }
    }
}
