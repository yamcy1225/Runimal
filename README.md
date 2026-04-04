# Runimal Apple

Runimal의 Apple 플랫폼 구현 저장소입니다.  
공유 게임 코어(`RunimalCore`) 위에 iPhone, Apple Watch, macOS SwiftUI 앱을 올린 구조입니다.

## 현재 상태

- iPhone 실기기 설치/실행 확인
- Apple Watch 실기기 설치/실행 확인
- 워치 함께 달릴 동행 sync 반응 개선 및 폰/워치 렌더 기준 1차 통일 완료
- 최근 워치 동기화 이벤트를 iPhone 러닝 화면에서 audit log 형태로 확인 가능
- 워치 단독 러닝 시작/종료 흐름 구현
- 워치 러닝 후 iPhone 보상 루프 연결
- `???` 알, 부화, 먹이 주기, 진화, 희귀 변이 루프 구현
- FIT 파일 수동 가져오기 구현
- 외부 러닝을 `운동 기록`으로 받아 지금 선택한 동행 성장에 연결
- 공유 쇼케이스, 부화 시네마틱, 문서화 완료

## 타깃

- `RunimalPhone` — iPhone 앱
- `RunimalWatch` — Apple Watch 앱
- `RunimalMac` — macOS 운영/검수 앱
- `RunimalCore` — 공유 게임 로직 Swift Package

## 핵심 루프

1. 워치에서 러닝 시작
2. 선택한 동행이 러닝 중 실시간 반응
3. 러닝 종료 후 결과를 `운동 기록`으로 저장
4. iPhone에서 기록을 알 생성, 인큐베이트, 동행 성장에 수동 배분
5. 단계 상승, 희귀 변이, 완성형 경로 진행

### 실시간 동행과 운동 기록

- 데리고 나간 동행은 러닝 중 반응하는 `실시간 동행`입니다.
- 러닝이 끝난 뒤 남는 운동 데이터는 특정 동행에 자동 귀속되지 않고 `운동 기록`으로 저장됩니다.
- 저장된 코어는 누구에게든 먹일 수 있어 외부 HealthKit / FIT 운동 데이터도 같은 규칙으로 성장 재료로 쓸 수 있습니다.

## 주요 기능

### Apple Watch

- 지금 선택한 동행 카드
- 러닝 시작하기 / 운동 끝내기
- `3 → 2 → 1` 카운트다운 시작
- 거리 / 시간 / 평균 페이스 / 심박 / 케이던스 표시
- 워치 단독 러닝 후 자동 동기화 큐
- 좌우 스와이프 페이지 구조

### iPhone

- 동행 / 러닝 / 보관함 페이지 구조
- `???` 알과 쉘 힌트
- 부화 시네마틱
- 희귀 변이 쇼케이스
- 완성형 경로 및 전용 가치 표현
- 운동 기록 카드와 지금 선택한 동행 성장
- FIT 파일 수동 가져오기 / 지우기
- 공유 쇼케이스 카드

## 문서

- [게임 컨셉 및 보상 시스템](./docs/game-concept-and-rewards.ko.md)
- [개발자용 시스템 명세](./docs/developer-system-spec.ko.md)
- [S급 전환 체크리스트](./docs/s-grade-transition-checklist.ko.md)
- [보상 연구 및 시뮬레이션](./docs/reward-research-and-simulation.ko.md)
- [오프라인 지도 오픈소스 워크플로우](./docs/offline-map-open-source-workflow.ko.md)
- [PMTiles / Protomaps 워크플로우](./docs/protomaps-pmtiles-workflow.ko.md)
- [실기기 배포 체크리스트](./docs/real-device-deploy-checklist.md)
- [릴리즈 핸드오프](./docs/release-handoff.ko.md)
- [TestFlight 릴리즈 플레이북](./docs/testflight-release-playbook.ko.md)
- [App Store 메타데이터 가이드](./docs/app-store-metadata.ko.md)
- [실시간 동행 / 운동 기록 분리 원칙](./docs/live-companion-and-run-core.ko.md)

## 로컬 개발

```bash
cd /Users/heobella/jaw-bot-2/apps/runimal-apple
xcodegen generate
swift build
```

## 빌드 예시

### iPhone

```bash
xcodebuild \
  -project RunimalApple.xcodeproj \
  -scheme RunimalPhone \
  -destination 'generic/platform=iOS' \
  build
```

### Apple Watch

```bash
xcodebuild \
  -project RunimalApple.xcodeproj \
  -scheme RunimalWatch \
  -destination 'generic/platform=watchOS' \
  build
```

### macOS

```bash
xcodebuild \
  -project RunimalApple.xcodeproj \
  -scheme RunimalMac \
  -destination 'platform=macOS' \
  build
```

## 참고

- 실기기 서명은 사용자 Apple Development Team 기준입니다.
- `project.yml`이 Xcode 프로젝트의 원본이며, 새 파일 추가 후에는 `xcodegen generate`로 다시 생성합니다.
- 데모 영상과 디자인 시안은 `demo/`, `design/` 아래에 있습니다.
- 현재 승인된 캐릭터 디자인 원칙은 `docs/world/current-character-design-lock.ko.md`에 고정합니다.
- 이 저장소는 현재 `master` 브랜치를 GitHub `yamcy1225/Runimal`에 push한 상태입니다.
