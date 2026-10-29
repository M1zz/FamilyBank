//
//  Components.swift
//  쑥쑥용돈
//
//  공용 UI 컴포넌트와 표시 도우미
//

import SwiftUI
import UIKit

// MARK: - 키보드 내리기 (빈 곳 탭)

/// 윈도우에 탭 제스처를 설치해서, 입력 필드 밖을 탭하면 키보드를 내린다.
/// cancelsTouchesInView = false 라서 버튼 등 다른 터치를 막지 않고,
/// 윈도우 단위라 시트(sheet) 안의 입력 필드에도 똑같이 동작한다.
private final class KeyboardDismissInstallerView: UIView, UIGestureRecognizerDelegate {
    static let gestureName = "FamilyBank.KeyboardDismissTap"

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window,
              !(window.gestureRecognizers?.contains { $0.name == Self.gestureName } ?? false)
        else { return }

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.name = Self.gestureName
        tap.cancelsTouchesInView = false
        tap.delegate = self
        window.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard(_ gesture: UITapGestureRecognizer) {
        gesture.view?.endEditing(true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldReceive touch: UITouch) -> Bool {
        // 입력 필드 자체를 탭할 때는 키보드를 유지한다
        var view = touch.view
        while let current = view {
            if current is UITextField || current is UITextView { return false }
            view = current.superview
        }
        return true
    }
}

private struct KeyboardDismissInstaller: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = KeyboardDismissInstallerView()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

extension View {
    /// 화면의 다른 곳을 탭하면 키보드가 내려간다 (앱 루트에 한 번만 적용)
    func dismissKeyboardOnTap() -> some View {
        background(KeyboardDismissInstaller())
    }
}

// MARK: - 아주 큰 글씨 배치

/// 평소엔 가로로, 손쉬운 사용 글자 크기에서는 세로로 쌓는다 — 숫자가 잘리거나 한 글자씩 꺾이지 않게.
struct AdaptiveStack<Content: View>: View {
    var alignment: HorizontalAlignment = .center
    var verticalAlignment: VerticalAlignment = .center
    var spacing: CGFloat? = nil
    @ViewBuilder var content: Content

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: alignment, spacing: spacing))
            : AnyLayout(HStackLayout(alignment: verticalAlignment, spacing: spacing))
        layout { content }
    }
}

extension View {
    /// 화면에 다 들어가면 그대로, 아주 큰 글씨로 넘치면 스크롤되게
    func scrollIfNeeded() -> some View {
        ViewThatFits(in: .vertical) {
            self
            ScrollView { self }
        }
    }
}

extension DynamicTypeSize {
    /// 카드 격자의 열 수 — 아주 큰 글씨에서는 한 줄에 하나
    var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: isAccessibilitySize ? 1 : 2)
    }
}

// MARK: - 차트용 데이터 포인트

struct ChartPoint: Identifiable {
    let id: Int      // 인덱스(주차/일차)
    let value: Int   // 금액/가격
}

func chartPoints(_ values: [Int]) -> [ChartPoint] {
    values.enumerated().map { ChartPoint(id: $0.offset, value: $0.element) }
}

// MARK: - 거래 종류별 색상

extension TxKind {
    var color: Color {
        switch self {
        case .allowance: return .pink
        case .payment: return .orange
        case .receive: return .green
        case .deposit: return .blue
        case .withdraw: return .cyan
        case .interest: return .purple
        case .buy: return .indigo
        case .sell: return .teal
        case .deduct: return .red
        }
    }
}

// MARK: - 금액 표시

struct MoneyText: View {
    let amount: Int
    let currencyName: String
    var font: Font = .title2

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(amount.comma)
                .font(font.weight(.bold))
                .monospacedDigit()
            Text(currencyName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - 카드 배경

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

extension View {
    func card() -> some View { modifier(CardBackground()) }
}

// MARK: - 금액 입력 필드

struct AmountField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.numberPad)
            .textFieldStyle(.roundedBorder)
            .onChange(of: text) { _, newValue in
                text = newValue.filter { $0.isNumber }
            }
    }

    var amount: Int { Int(text) ?? 0 }
}

// MARK: - 거래 한 줄 표시

struct TransactionRow: View {
    let tx: MoneyTransaction
    let currencyName: String
    var showMemberName: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: tx.kind.icon)
                .font(.callout)
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(tx.kind.color.gradient, in: Circle())
                .accessibilityLabel(Text(LocalizedStringKey(tx.kind.rawValue)))

            VStack(alignment: .leading, spacing: 2) {
                Text(tx.displayMemo)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if showMemberName, let name = tx.member?.name {
                        Text(name)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Text(tx.date, format: .dateTime.month().day().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("\(tx.kind.isIncome ? "+" : "-")\(tx.amount.comma)")
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(tx.kind.isIncome ? Color.green : Color.red)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - PIN 입력 화면

struct PINEntryView: View {
    let title: String
    let correctPIN: String
    let onSuccess: () -> Void

    @State private var input = ""
    @State private var shake = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text(title)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            // PIN 점 표시
            HStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(i < input.count ? Color.accentColor : Color(.systemGray4))
                        .frame(width: 16, height: 16)
                }
            }
            .offset(x: shake ? -8 : 0)
            .accessibilityElement()
            .accessibilityLabel(Text("입력한 숫자"))
            .accessibilityValue(Text(verbatim: "\(input.count)/4"))

            // 숫자 패드
            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(1...3, id: \.self) { col in
                            let n = row * 3 + col
                            padButton("\(n)") { append("\(n)") }
                        }
                    }
                }
                HStack(spacing: 12) {
                    padButton(" ") {}.hidden()
                    padButton("0") { append("0") }
                    Button {
                        if !input.isEmpty { input.removeLast() }
                    } label: {
                        Image(systemName: "delete.left")
                            .font(.title2)
                            .frame(width: 72, height: 56)
                    }
                    .accessibilityLabel(Text("지우기"))
                }
            }
            // 버튼 크기가 고정이라 숫자가 넘치지 않을 만큼만 키운다 (이미 큰 글씨)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .padding()
    }

    private func padButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.title.weight(.medium))
                .frame(width: 72, height: 56)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func append(_ digit: String) {
        guard input.count < 4 else { return }
        input += digit
        if input.count == 4 {
            if input == correctPIN {
                onSuccess()
            } else {
                // 흔들림은 눈으로만 알 수 있으니 VoiceOver 에는 말로 알린다
                AccessibilityNotification.Announcement(String(localized: "PIN이 맞지 않아요. 다시 입력해 주세요.")).post()
                if !reduceMotion {
                    withAnimation(.spring(duration: 0.15)) { shake = true }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation { shake = false }
                    input = ""
                }
            }
        }
    }
}
