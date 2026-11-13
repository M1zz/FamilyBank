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
//  - 넓은 아이패드(거실 공용)도 가로로 편 아이폰 듀오와 같은 짝으로 선다(`WidePadPanes`).
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

// MARK: - 넓은 아이패드

/// 넓은 아이패드도 가로로 편 아이폰 듀오와 같은 짝으로 세운다: 왼쪽 고른 탭, 오른쪽 대시보드.
/// 아이패드는 접히지 않아 Fold 가 한 쪽(single)으로 재므로, regular 폭이면 여기서 펼친 자세로 바꿔 흘린다.
/// Slide Over · 좁은 분할(compact)은 아이폰처럼 한 쪽.
struct WidePadPanes<Content: View>: View {
    @Environment(\.foldLayout) private var fold
    @Environment(\.horizontalSizeClass) private var sizeClass
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .environment(\.foldLayout, layout)
            .environment(\.isWidePadPanes, layout.isUnfolded && !fold.isUnfolded)
    }

    private var layout: FoldLayout {
        guard UIDevice.current.userInterfaceIdiom == .pad, sizeClass == .regular,
              fold.windowSize != .zero else { return fold }
        return FoldLayout(posture: .innerLandscape, windowSize: fold.windowSize)
    }
}

extension EnvironmentValues {
    /// 넓은 아이패드라서 두 쪽으로 세웠는가(진짜 접는 폰이 아니라).
    @Entry var isWidePadPanes = false
}

extension View {
    /// 화면 전체를 덮는 것에 건다. 펼친 아이폰 듀오에서는 고르는 쪽 판에만 서고(접힌 선을 넘지 않게),
    /// 넓은 아이패드는 접힌 선이 없으니 화면을 다 쓴다.
    func coverConfined() -> some View { modifier(CoverConfined()) }
}

private struct CoverConfined: ViewModifier {
    @Environment(\.isWidePadPanes) private var widePad

    func body(content: Content) -> some View {
        if widePad {
            content.environment(\.foldLayout, .single)
        } else {
            content.foldConfined()
        }
    }
}
