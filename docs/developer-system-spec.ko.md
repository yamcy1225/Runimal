# Runimal 개발자용 시스템 명세

## 1. 문서 범위

이 문서는 현재까지 반영된 Runimal 시스템을 개발자 관점에서 정리한 최신 구현 명세다.

대상:

- iPhone 앱
- Apple Watch 앱
- 공용 Swift 게임 코어

프로젝트 루트:

- `/Users/heobella/jaw-bot-2/apps/runimal-apple`

## 2. 아키텍처 개요

Runimal은 세 계층으로 나뉜다.

### 2.1 Shared Core

위치:

- `/Users/heobella/jaw-bot-2/apps/runimal-apple/Sources/RunimalCore`

책임:

- 러닝 요약 모델
- 알 생성 규칙
- 부화 확률 계산
- GeneratedPet 생성
- 보상 계산
- 성장/진화 공식
- 주간/시즌/레이드 로직
- 스냅샷 병합
- raidContribution 같은 장기 확장 필드 정의

### 2.2 iPhone Layer

위치:

- `/Users/heobella/jaw-bot-2/apps/runimal-apple/RunimalPhone`

책임:

- 메인 화면과 좌우 페이지 UI
- 컬렉션/보관함/Run Core 사용 결정 UI
- 부화 디코딩 시네마틱
- 진행 상태 저장
- 클라우드/볼트/충돌 처리
- Sanctuary 보상 노출

### 2.3 Watch Layer

위치:

- `/Users/heobella/jaw-bot-2/apps/runimal-apple/RunimalWatch`

책임:

- HealthKit 기반 러닝 세션
- 실시간 거리/심박/케이던스 추적
- 라이브 목표/희귀 신호 평가
- 런타임 이벤트 알림 배너
- 보상 생성 및 iPhone 전송

## 3. 핵심 도메인 모델

### 3.1 RunSummary

압축된 러닝 규칙 입력 모델.

주요 필드:

- `distanceKm`
- `averagePaceSeconds`
- `cadence`
- `elevationGainM`
- `variability`
- `aura`
- `shape`

### 3.2 CompletedRunRecord

완료된 러닝의 영속 모델.

주요 필드:

- `id`
- `startedAt`
- `endedAt`
- `distanceMeters`
- `durationSeconds`
- `averageHeartRate`
- `averagePaceSeconds`
- `cadence`
- `elevationGainM`
- `reward`
- `route`
- `raidContribution`
- `source`

### 3.3 GeneratedPet

생성 결과 패키지.

주요 필드:

- `species`
- `element`
- `palette`
- `rareVariant`
- `explanation`
- `stats`

### 3.4 PetCollectionEntry

컬렉션에 저장되는 동행체 엔트리.

주요 필드:

- `id`
- `pet`
- `level`
- `bond`
- `totalDistanceKm`
- `headline`

### 3.5 EggInventoryEntry

숨김형 알 인벤토리 모델.

주요 필드:

- `id`
- `shell`
- `title`
- `createdAt`
- `sourceRunID`
- `storedExperience`
- `hatchThreshold`
- `incubationRunIDs`
- `unlockedAchievementIDs`

중요:

- 알은 최종 펫을 직접 들고 있지 않는다.
- 최종 펫은 부화 시점에 `RunimalEggEngine.hatchPet(...)`로 계산된다.

### 3.6 MainCompanionSelection

메인 슬롯 상태.

종류:

- `.pet`
- `.egg`

## 4. 알 시스템 명세

핵심 파일:

- [RunimalEggEngine.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/Sources/RunimalCore/RunimalEggEngine.swift)
- [EggShellStyle.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/SharedUI/EggShellStyle.swift)
- [TraceEggView.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/SharedUI/TraceEggView.swift)

### 4.1 알 획득 조건

`RunimalEggEngine.opportunity(...)`가 판정한다.

허용 조건:

1. 새 업적 해금 러닝
2. 컬렉션과 알 인벤토리가 모두 빈 상태에서의 첫 성공 러닝

현재 업적 ID 예시:

- `distance-5k`
- `cadence-170`
- `climb-60`
- `night-run`

### 4.2 쉘 타입

현재 enum 값:

- `ember`
- `gale`
- `moss`
- `dusk`
- `stone`

선택 휴리스틱:

- 고도 상승량이 크면 `stone`
- 빠른 페이스 또는 고케이던스면 `ember`
- 야간 러닝이면 `dusk`
- 장거리면 `gale`
- 그 외는 `moss`

### 4.3 숨김형 알 UX

- `title`은 기본적으로 `???`
- 쉘 라벨, 스캔 헤드라인, 스캔 로그만 노출
- 실제 종족은 부화 전까지 비공개

### 4.4 부화 확률

`RunimalEggEngine.hatchPet(...)`가 계산한다.

입력:

- 알
- 원본 러닝과 인큐베이트 러닝들
- 주간 보상 ID

동작:

- 쉘별 기본 가중치 부여
- 러닝 패턴별 추가 가중치 부여
- 결정적 pseudo-random 방식으로 종족 선택
- 선택된 종족과 기존 GeneratedPet 결과를 합쳐 최종 개체 생성

## 5. 디코딩 시네마틱

핵심 파일:

- [HatchCinematicView.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/RunimalPhone/HatchCinematicView.swift)
- [HatchInterferenceBackdropView.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/SharedUI/HatchInterferenceBackdropView.swift)
- [HatchFragmentBurstView.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/SharedUI/HatchFragmentBurstView.swift)

단계:

1. `wait`
2. `decoding`
3. `interference`
4. `complete`

현재 구성 요소:

- 디코딩 로그 텍스트
- 글리치 그리드
- 간섭 배경 레이어
- 분해 조각 레이어
- 완료 직전 플래시
- 펫 생성 컷

AR 대비:

- 배경은 `HatchInterferenceBackdropView`로 분리돼 있어 향후 카메라 피드 교체가 가능하다.

## 6. 진행 상태 저장

핵심 파일:

- [PhoneProgressStore.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/RunimalPhone/PhoneProgressStore.swift)
- [PhoneProgressStore+CompanionLoop.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/RunimalPhone/PhoneProgressStore+CompanionLoop.swift)
- [PhoneProgressStore+Sanctuary.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/RunimalPhone/PhoneProgressStore+Sanctuary.swift)

저장 대상:

- journal
- completed runs
- owned companions
- egg inventory
- unlocked egg achievement IDs
- main companion selection
- growth records
- claimed weekly rewards
- season / raid claim state
- resource balances
- forge inventory
- build states
- sanctuary event
- merge / conflict policy

### 6.1 Snapshot

스냅샷 모델:

- `RunimalProgressSnapshot`

포함 상태:

- 펫/알 인벤토리
- 메인 슬롯
- 업적 해금 상태
- 러닝 기록
- raidContribution 총량
- 자원 및 메타 상태

### 6.2 초기화

리셋은 완전 빈 앱 상태가 아니라 테스트 가능한 초기 씨드 상태로 되돌린다.

## 7. Run Core 사용 흐름

핵심 UI 파일:

- [PhoneRunCoreDecisionPanel.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/RunimalPhone/PhoneRunCoreDecisionPanel.swift)

선택지:

1. 새 알 만들기
2. 메인 펫 성장
3. 메인 알 인큐베이트

원칙:

- 하나의 러닝은 한 번만 귀속된다.
- 알에 사용된 러닝은 부화 후 그 펫 소유로 넘어가며 재사용되지 않는다.

## 8. 메인 슬롯과 컬렉션

핵심 파일:

- [PhoneCompanionRosterPanel.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/RunimalPhone/PhoneCompanionRosterPanel.swift)
- [PhoneCollectionView.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/RunimalPhone/PhoneCollectionView.swift)

현재 UI 동작:

- 메인 펫 선택
- 메인 알 선택
- 알 스캔 로그 표시
- 디코딩 가능 상태에서 부화 버튼 활성화
- 위험 구역 내부에서만 초기화 버튼 노출

## 9. Sanctuary Mode

핵심 파일:

- [SanctuaryEngine.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/Sources/RunimalCore/SanctuaryEngine.swift)
- [SanctuaryModels.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/Sources/RunimalCore/SanctuaryModels.swift)
- [PhoneSanctuaryPanel.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/RunimalPhone/PhoneSanctuaryPanel.swift)

동작:

- 러닝 기록이 없는 날 접속 시 평가
- 메인 펫과 누적 거리 기반으로 Essence 또는 아이템 지급
- Oracle 역할은 보너스 발견 확률에 시너지

## 10. Watch 런타임 시스템

핵심 파일:

- [WatchRunSessionManager.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/RunimalWatch/WatchRunSessionManager.swift)
- [WatchDashboardView.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/RunimalWatch/WatchDashboardView.swift)
- [RunimalCuePlayer.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/SharedUI/RunimalCuePlayer.swift)

역할:

- HealthKit 권한 요청
- 러닝 세션 시작/종료
- 실시간 snapshot 갱신
- 쉘 추정
- 라이브 목표 계산
- 희귀 신호 계산
- 완료 보상 계산

### 10.1 런타임 알림

현재 배너/햅틱 이벤트:

- 라이브 목표 완료
- Rare Window 진입
- 러닝 종료 후 보상 확보

중복 방지:

- `dispatchedGoalIDs`
- `dispatchedSignalIDs`

화면 표시:

- `runtimeAlert`

알림 큐:

- `RunimalCuePlayer.playAlertCue(...)`

## 11. 주간 / 시즌 / 레이드

현재 코어는 다음을 포함한다.

- 주간 미션 및 주간 보상
- 시즌 보드와 시즌 해금
- 레이드 준비도 및 보상
- `raidContribution` 필드

이는 이후 비동기 글로벌 레이드 확장에 대비한 상태다.

## 12. 구현 원칙

- Shared Core는 UI에 의존하지 않는다.
- 알은 결과를 숨기고 확률 힌트만 준다.
- 랜덤은 존재하지만 플레이어 행동이 확률을 기울인다.
- Watch는 실시간 반응, iPhone은 관리와 해석에 집중한다.
- 설명문보다 그래픽, 배지, 게이지, 신호 로그가 먼저 보이게 설계한다.
