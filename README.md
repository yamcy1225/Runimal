# Runimal Apple

Runimal의 Apple 플랫폼 구현 저장소입니다.  
공유 게임 코어(`RunimalCore`) 위에 iPhone, Apple Watch, macOS SwiftUI 앱을 올린 구조입니다.

## 현재 상태

- iPhone 실기기 설치/실행 확인
- Apple Watch 실기기 설치/실행 확인
- 워치 단독 러닝 시작/종료 흐름 구현
- 워치 러닝 후 iPhone 보상 루프 연결
- `???` 알, 부화, 먹이 주기, 진화, 희귀 변이 루프 구현
- FIT 파일 수동 가져오기 구현
- 외부 러닝을 `러닝 코어`로 받아 메인 동행체 성장에 연결
- 공유 쇼케이스, 디코딩 시네마틱, 문서화 완료

## 타깃

- `RunimalPhone` — iPhone 앱
- `RunimalWatch` — Apple Watch 앱
- `RunimalMac` — macOS 운영/검수 앱
- `RunimalCore` — 공유 게임 로직 Swift Package

## 핵심 루프

1. 워치에서 러닝 시작
2. 러닝 결과를 `러닝 코어` 또는 보상으로 변환
3. iPhone에서 알 생성, 인큐베이트, 부화
4. 메인 동행체에 경험치 공급
5. 단계 상승, 희귀 변이, Mythic 경로 진행

## 주요 기능

### Apple Watch

- 메인 동행체 카드
- 러닝 시작하기 / 운동 끝내기
- `3 → 2 → 1` 카운트다운 시작
- 거리 / 시간 / 평균 페이스 / 심박 / 케이던스 표시
- 워치 단독 러닝 후 자동 동기화 큐
- 좌우 스와이프 페이지 구조

### iPhone

- 동행 / 러닝 / 보관함 페이지 구조
- `???` 알과 쉘 힌트
- 디코딩 부화 시네마틱
- 희귀 변이 쇼케이스
- Mythic 경로 및 전용 가치 표현
- 러닝 코어 카드와 메인 동행체 먹이 주기
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
- 데모 영상과 디자인 시안은 `demo/`, `design/` 아래에 있습니다.
- 이 저장소는 현재 `master` 브랜치를 GitHub `yamcy1225/Runimal`에 push한 상태입니다.
