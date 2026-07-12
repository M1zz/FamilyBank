//
//  InviteView.swift
//  FamilyBank — 우리집 은행
//
//  자녀 초대: 초대장 카드 + QR 코드 + 공유 시트
//

import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins

// MARK: - QR 코드 생성

enum QRCodeMaker {
    static func image(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        // 픽셀이 선명하게 보이도록 확대
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - 초대장 내용 (재사용 가능)

struct InviteCardView: View {
    let member: FamilyMember
    let settings: FamilySettings

    private var inviteMessage: String {
        """
        🏦 \(member.name)님, 우리집 은행에 초대해요!

        우리집 화폐 '\(settings.currencyName)'(으)로 함께해요:
        • 용돈을 모으고 결제해요 💸
        • 저축하면 매주 이자 \(settings.weeklyInterestRate.cleanPercent)%를 받아요 🏦
        • 투자 상품으로 경제를 배워요 📈

        부모님 기기와 같은 iCloud 계정으로 로그인한 기기에서 FamilyBank 앱을 열면 바로 함께할 수 있어요!
        """
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 초대 카드
                VStack(spacing: 12) {
                    Text(member.emoji)
                        .font(.system(size: 64))
                    Text("\(member.name)님을\n우리집 은행에 초대해요!")
                        .font(.title3.weight(.bold))
                        .multilineTextAlignment(.center)
                    Text("화폐 '\(settings.currencyName)' · 주간 이자 \(settings.weeklyInterestRate.cleanPercent)%")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(
                    LinearGradient(colors: [Color.blue.opacity(0.12), Color.purple.opacity(0.12)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                // QR 코드
                VStack(spacing: 10) {
                    if let qr = QRCodeMaker.image(from: inviteMessage) {
                        Image(uiImage: qr)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    Text("자녀 기기의 카메라로 스캔하면 초대장이 보여요")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // 공유 버튼
                ShareLink(item: inviteMessage) {
                    Label("초대장 보내기", systemImage: "paperplane.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)

                Text("💡 메시지, 카카오톡 등으로 초대장을 보낼 수 있어요.\n같은 iCloud 계정으로 로그인한 기기라면 데이터가 자동으로 함께 보여요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

// MARK: - 단독 초대 시트 (대시보드에서 재초대용)

struct InviteSheet: View {
    let member: FamilyMember
    let settings: FamilySettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            InviteCardView(member: member, settings: settings)
                .navigationTitle("💌 초대장")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("닫기") { dismiss() }
                    }
                }
        }
    }
}
