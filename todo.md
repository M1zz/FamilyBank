# TODO

## 아이폰 듀오 대응 (2026-10-30, 듀오 시뮬레이터 빌드 성공 · 접힌 바깥 화면 · `-FoldPretend` 세로 화면 확인 · 실기기 확인 안 함)
- [x] 앱 루트에 `.foldAware()` (LeeoKit Fold) — 시트 · 알림창이 접힌 선을 비킨다
- [x] 부모 화면: 펴면 고르는 쪽(가로면 왼쪽, 세로면 아래) 액션 · 시장 · 기록 · 배우기 | 결과 쪽(오른쪽, 위) 대시보드. 대시보드 탭은 결과 쪽에 늘 서므로 펼친 탭 막대에는 넷만 (`Views/FoldPanes.swift`)
- [x] 자녀 폰 모드: 같은 규칙으로 결과 쪽에 내 지갑
- [x] 탭 구조를 그대로 두고 `FoldSplitView` 로 나눠, 펴고 접어도 보던 탭 · 적던 금액이 남는다
- [x] 처음 설정(온보딩) `.foldConfined()` — 선을 넘지 않는다
- [x] 툴바의 글자만 있던 닫기 · 취소 · 완료 · 추가에 아이콘(세로로 서는 툴바에서 사라지지 않게). 문자열 키는 그대로
- [ ] 가로로 편 화면 · 실기기 확인 (명령줄로는 듀오 시뮬레이터를 못 편다)
- 확인: Xcode 27.1 로 듀오 시뮬레이터에 깔고 `-ScreenshotDemo YES -DemoScreen actions -FoldPretend` 로 실행, `simctl io <id> screenshot --display=1`
