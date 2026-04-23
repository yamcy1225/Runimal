# Runimal v2 UI Upgrade Plan

이 계획은 image generation 후보를 실제 앱 UI 개선으로 번역하는 순서를 정의한다. 목표는 보기 좋은 목업을 만드는 것이 아니라, Watch 단독 러닝 루프와 iPhone 기록/성장 루프를 더 신뢰할 수 있게 만드는 것이다.

## Phase 0 — Baseline capture

Deliverables:

- iPhone `RunimalPhone` 첫 화면 / 기록 상세 / 성장 배분 화면 캡처
- Apple Watch `RunimalWatch` 대시보드 / 러닝 중 stats / live pulse 화면 캡처
- 현재 화면의 metric hierarchy 메모

Validation:

- 실기기 설치/실행이 가능해야 한다.
- 캡처는 `output/ui-baseline/` 또는 QA 문서에 보존한다.

## Phase 1 — Imagegen candidate generation

Deliverables:

- `output/imagegen/`에 후보 이미지 또는 prompt artifact 저장
- 각 후보별 prompt, 생성일, 용도, 리뷰 결과 기록

Validation:

- Watch HUD 후보는 거리/페이스 판독을 통과해야 한다.
- Phone 후보는 route path drawing 중심 구조여야 한다.
- Growth 후보는 manual spend 개념을 흐리지 않아야 한다.

## Phase 2 — Design decision extraction

Deliverables:

- 색상 토큰 후보: background, primaryMetric, routeLine, resourceAccent, companionAccent
- typography scale 후보: Watch hero metric / secondary chip / caption
- layout rules: route hero ratio, action card spacing, companion max footprint

Validation:

- SwiftUI로 구현 가능한 primitive만 채택한다.
- bitmap 자체를 앱에 복붙하지 않는다.

## Phase 3 — Watch readability pass

Target files likely affected later:

- `RunimalWatch/WatchRunStatsPanel.swift`
- `RunimalWatch/WatchRunPulseCard.swift`
- `SharedUI/RunimalProgressBar.swift`
- `SharedUI/GameSurface.swift`

Rules:

- 거리/현재 페이스가 companion보다 먼저 읽힌다.
- live companion 반응은 보조 cue로 유지한다.
- GPS 상태와 Health metrics를 숨기지 않는다.

Validation:

- Apple Watch 실기기에서 화면 진입.
- 작은 화면에서 2초 glance 판독 확인.
- 러닝 루프 시작/종료/저장 기능 회귀 없음.

## Phase 4 — Phone route-detail pass

Target files likely affected later:

- `RunimalPhone/PhoneRunRecordDetailSheet.swift`
- `RunimalPhone/PhoneRecentRunCard.swift`
- `SharedUI/RunimalRoutePreviewShape.swift`

Rules:

- GPS path drawing을 지도 타일보다 우선한다.
- 저장/동기화 상태를 기록 신뢰성의 일부로 보인다.
- export/FIT/manual import 기능과 충돌하지 않는다.

Validation:

- 기록 상세 화면에서 거리/시간/평균 페이스/심박/케이던스/상승고도 확인.
- route path preview가 비어 있는 기록에서도 graceful fallback.

## Phase 5 — Resource allocation UX pass

Target files likely affected later:

- `RunimalPhone/PhoneRunCoreDecisionPanel.swift`
- `RunimalPhone/PhoneRunResourceLedgerPersistence.swift`
- `RunimalPhone/PhoneDashboardStore+RunActions.swift`

Rules:

- unspent/spent 상태를 명시한다.
- companion feed / egg forge / egg incubation은 명확히 다른 액션이다.
- 이미 소비된 기록 삭제/보존 규칙을 흔들지 않는다.

Validation:

- `swift test --filter RunimalPhoneSpendApplicationV2Tests`
- `swift test`
- simulator runtime check `RUNIMAL_RUNTIME_CHECK=resource-ledger-v2`

## Phase 6 — Production asset review

Only after accepted design decisions:

- 필요한 bitmap만 asset catalog 후보로 승격한다.
- 가능한 경우 SwiftUI/vector로 재구현한다.
- accessibility contrast와 small-size icon review를 진행한다.

## Current status

- `image_generation = true` is enabled in Codex config.
- In this session, no live image tool namespace is exposed and `OPENAI_API_KEY` is not available, so this pass prepares executable briefs and JSONL instead of generating final image files.
