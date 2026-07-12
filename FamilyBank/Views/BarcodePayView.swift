//
//  BarcodePayView.swift
//  FamilyBank — 우리집 은행
//
//  바코드 결제: 부모가 물품 바코드를 띄우고, 자녀가 카메라로 찍으면 코인이 빠져나간다
//

import SwiftUI
import SwiftData
import UIKit
import AVFoundation

/// 바코드에 담는 결제 페이로드: "FBPAY:<물품 uid>"
enum PayCode {
    static let prefix = "FBPAY:"

    static func encode(_ item: HouseholdItem) -> String { prefix + item.uid }

    static func decodeUID(_ code: String) -> String? {
        guard code.hasPrefix(prefix) else { return nil }
        let uid = String(code.dropFirst(prefix.count))
        return uid.isEmpty ? nil : uid
    }
}

// MARK: - 물품 바코드 목록 (부모용)

struct ItemBarcodeListSheet: View {
    let settings: FamilySettings

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \HouseholdItem.createdAt) private var items: [HouseholdItem]

    private var activeItems: [HouseholdItem] { items.filter { $0.isActive } }

    var body: some View {
        NavigationStack {
            List {
                if activeItems.isEmpty {
                    Text("등록된 물품이 없어요. 먼저 '물품 추가'로 가게에 물품을 등록해 주세요.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(activeItems) { item in
                        NavigationLink {
                            ItemBarcodeView(item: item, settings: settings)
                        } label: {
                            HStack(spacing: 12) {
                                Text(item.emoji)
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.subheadline.weight(.medium))
                                    Text("\(settings.coinPrice(forWon: item.priceWon).comma) \(settings.currencyName)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("🏷️ 물품 바코드")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .onAppear {
                // 예전 데이터에 uid가 없으면 발급
                var changed = false
                for item in items where item.uid.isEmpty {
                    item.uid = UUID().uuidString
                    changed = true
                }
                if changed { try? context.save() }
            }
        }
    }
}

// MARK: - 물품 바코드 (가격표처럼 크게)

struct ItemBarcodeView: View {
    let item: HouseholdItem
    let settings: FamilySettings

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 10) {
                Text(item.emoji)
                    .font(.system(size: 64))
                Text(item.name)
                    .font(.title2.weight(.bold))
                Text("\(settings.coinPrice(forWon: item.priceWon).comma) \(settings.currencyName)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.tint)
                Text("실제 가격 \(item.priceWon.comma)원")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let qr = QRCodeMaker.image(from: PayCode.encode(item)) {
                Image(uiImage: qr)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 240, height: 240)
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            }

            Text("자녀가 '찍어서 결제'로 이 바코드를 찍으면\n지갑에서 \(settings.currencyName)이 빠져나가요")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
        .navigationTitle("바코드")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 찍어서 결제 (자녀용 스캐너)

struct ScanPayView: View {
    @Bindable var payer: FamilyMember
    let settings: FamilySettings

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \HouseholdItem.createdAt) private var items: [HouseholdItem]
    @Query(sort: \FamilyMember.createdAt) private var members: [FamilyMember]

    @State private var scannedItem: HouseholdItem?
    @State private var showResult = false
    @State private var resultMessage = ""
    @State private var didSucceed = false

    /// 가게 주인 = 결제자가 아닌 첫 번째 부모
    private var shopkeeper: FamilyMember? {
        members.first { !$0.isChild && $0 !== payer }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                QRScannerView { code in
                    handleScan(code)
                }
                .ignoresSafeArea()

                // 스캔 가이드
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.9), lineWidth: 3)
                        .frame(width: 240, height: 240)
                    Text("물품 바코드를 네모 안에 맞춰 주세요")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.55), in: Capsule())
                        .padding(.top, 16)
                    Spacer()
                    Text("내 지갑: \(payer.balance.comma) \(settings.currencyName)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.black.opacity(0.55), in: Capsule())
                        .padding(.bottom, 24)
                }
            }
            .navigationTitle("📷 찍어서 결제")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .confirmationDialog(confirmTitle, isPresented: Binding(
                get: { scannedItem != nil },
                set: { if !$0 { scannedItem = nil } }
            ), titleVisibility: .visible) {
                Button("결제하기") { performPay() }
                Button("취소", role: .cancel) { scannedItem = nil }
            }
            .alert(didSucceed ? "결제 완료! 🎉" : "결제 실패", isPresented: $showResult) {
                Button("확인") {
                    if didSucceed { dismiss() }
                }
            } message: {
                Text(resultMessage)
            }
        }
    }

    private var confirmTitle: String {
        guard let item = scannedItem else { return "" }
        return "\(item.emoji) \(item.name) — \(settings.coinPrice(forWon: item.priceWon).comma) \(settings.currencyName)을(를) 낼까요?"
    }

    private func handleScan(_ code: String) {
        // 확인 창이나 결과 창이 떠 있는 동안은 무시
        guard scannedItem == nil, !showResult else { return }
        guard let uid = PayCode.decodeUID(code),
              let item = items.first(where: { $0.uid == uid && $0.isActive }) else { return }
        scannedItem = item
    }

    private func performPay() {
        guard let item = scannedItem else { return }
        let price = settings.coinPrice(forWon: item.priceWon)
        let ok = BankEngine.pay(from: payer,
                                to: shopkeeper,
                                amount: price,
                                memo: "\(item.emoji) \(item.name) (바코드)",
                                context: context)
        didSucceed = ok
        resultMessage = ok
            ? "\(item.name)을(를) 샀어요! 남은 지갑: \(payer.balance.comma) \(settings.currencyName)"
            : "지갑에 돈이 부족해요! 잔액: \(payer.balance.comma) \(settings.currencyName)"
        scannedItem = nil
        showResult = true
    }
}

// MARK: - QR 카메라 스캐너 (AVFoundation)

struct QRScannerView: UIViewRepresentable {
    var onCode: (String) -> Void

    func makeUIView(context: Context) -> ScannerPreviewView {
        let view = ScannerPreviewView()
        view.onCode = onCode
        view.start()
        return view
    }

    func updateUIView(_ uiView: ScannerPreviewView, context: Context) {
        uiView.onCode = onCode
    }

    static func dismantleUIView(_ uiView: ScannerPreviewView, coordinator: ()) {
        uiView.stop()
    }
}

final class ScannerPreviewView: UIView, AVCaptureMetadataOutputObjectsDelegate {
    var onCode: ((String) -> Void)?

    private let session = AVCaptureSession()
    private var isConfigured = false
    private var lastCode: String?
    private var lastCodeAt = Date.distantPast

    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    private var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

    func start() {
        backgroundColor = .black
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndRun()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else { return }
                DispatchQueue.main.async { self?.configureAndRun() }
            }
        default:
            break  // 거부됨 — 검은 화면 (설정에서 허용 필요)
        }
    }

    func stop() {
        let session = self.session
        DispatchQueue.global(qos: .userInitiated).async {
            if session.isRunning { session.stopRunning() }
        }
    }

    private func configureAndRun() {
        if !isConfigured {
            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else { return }
            session.addInput(input)

            let output = AVCaptureMetadataOutput()
            guard session.canAddOutput(output) else { return }
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]

            previewLayer.session = session
            previewLayer.videoGravity = .resizeAspectFill
            isConfigured = true
        }
        let session = self.session
        DispatchQueue.global(qos: .userInitiated).async {
            if !session.isRunning { session.startRunning() }
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = object.stringValue else { return }
        // 같은 코드 연속 인식 방지 (1.5초)
        let now = Date()
        if code == lastCode, now.timeIntervalSince(lastCodeAt) < 1.5 { return }
        lastCode = code
        lastCodeAt = now
        onCode?(code)
    }
}
