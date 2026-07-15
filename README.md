# 🌱 쑥쑥용돈 (FamilyBank)

가족 안에서 쓰는 화폐 시스템으로 아이에게 금융·경제를 가르치는 iOS 앱입니다.

부모는 중앙은행이 되어 용돈을 발행하고, 자녀는 결제하고, 저축해서 이자를 받고, 모의 펀드에 투자하며 경제 원리를 몸으로 배웁니다.

## 링크

- 🌐 [소개 페이지](https://m1zz.github.io/FamilyBank/)
- 🔒 [개인정보 처리방침](https://m1zz.github.io/FamilyBank/privacy.html)
- 💬 [지원 · 문의](https://m1zz.github.io/FamilyBank/support.html)

## 주요 기능

- **우리집 화폐** — 화폐 이름을 직접 정합니다 (콩, 별, 코인 등)
- **용돈 지급/차감** — 부모 모드(PIN 보호)에서 자녀에게 돈을 주거나 회수
- **결제** — 자녀가 부모에게 결제 (간식, 게임 시간, TV 시간 등)
- **저축 이자** — 저축통장에 넣은 돈에 매주 복리 이자가 자동으로 붙음 (이자율은 부모가 설정)
- **투자 체험** — 하루에 한 번 시세가 변하는 모의 펀드 (안정형 🐢 / 보통형 🐰 / 위험형 🚀), 매수·매도, 수익률 차트
- **거래 기록** — 모든 거래를 날짜별·구성원별·종류별로 조회
- **경제 교육** — 화폐, 저축과 이자, 복리, 투자와 위험, 필요와 욕구, 기회비용, 예산 등 7가지 개념 + 복리 계산기
- **iCloud 동기화** — CloudKit으로 가족 기기 간 데이터 동기화 (설정 필요, 아래 참고)

## 요구 사항

- Xcode 16 이상
- iOS 17.0 이상 (iPhone / iPad)

## 실행 방법

1. 압축을 풀고 `FamilyBank.xcodeproj`를 Xcode에서 엽니다.
2. 시뮬레이터를 선택하고 ⌘R로 실행하면 바로 동작합니다. (iCloud 설정 전에는 자동으로 기기 로컬 저장으로 동작)

## iCloud(기기 간 동기화) 설정

CloudKit 동기화를 켜려면 Apple Developer 계정이 필요합니다.

1. Xcode에서 프로젝트 선택 → **Signing & Capabilities** 탭
2. **Team**에 본인 Apple ID 팀 선택
3. **Bundle Identifier**를 본인 고유 값으로 변경 (예: `com.본인이름.FamilyBank`)
4. iCloud Capability의 컨테이너를 `iCloud.` + 본인 번들 ID로 맞춰 줍니다 (`FamilyBank.entitlements`의 컨테이너 ID도 동일하게 수정)
5. 가족 구성원 기기에 앱을 설치하고 **같은 iCloud 가족 공유 계정** 또는 같은 Apple ID로 로그인하면 데이터가 동기화됩니다.

> 참고: 각자 다른 Apple ID를 쓰는 가족이라면 CloudKit 공유 데이터베이스 구성이 추가로 필요합니다. 기본 구성은 같은 iCloud 계정으로 로그인된 기기 간 동기화입니다.

## 구조

```
FamilyBank/
├── FamilyBankApp.swift      # 앱 진입점, SwiftData + CloudKit 컨테이너 설정
├── Models.swift             # 구성원·거래·투자상품·보유·설정 모델
├── BankEngine.swift         # 이자 계산, 시세 변동(랜덤워크), 모든 거래 로직
└── Views/
    ├── RootView.swift       # 온보딩/메인 분기, 탭 구성
    ├── OnboardingView.swift # 최초 설정 (화폐 이름 → PIN → 가족 등록)
    ├── HomeView.swift       # 가족별 자산 현황
    ├── MemberDetailView.swift
    ├── PayView.swift        # 결제
    ├── SavingsView.swift    # 저축 입출금 + 복리 미리보기
    ├── InvestView.swift     # 투자 상품 목록/차트/매수·매도
    ├── HistoryView.swift    # 거래 기록
    ├── EducationView.swift  # 경제 교육 + 복리 계산기
    ├── ParentModeView.swift # PIN 잠금 부모 모드 (용돈·구성원·상품·설정 관리)
    └── Components.swift     # 공용 UI 컴포넌트
```

## 경제 시스템 설계

- **부모 = 중앙은행**: 용돈 지급은 화폐 발행, 차감은 회수입니다.
- **저축 이자**: 주 단위 복리. 앱을 열 때 밀린 주차만큼 자동 정산됩니다.
- **투자 시세**: 하루 1회 랜덤워크(변동성 + 상승 경향)로 변동. 위험이 클수록 변동폭이 큽니다.
- **거래 기록**: 모든 돈의 이동이 장부에 남아 소비 습관을 되돌아볼 수 있습니다.
