# Runimal Internal System Lexicon

## 1. 목적

이 문서는 플레이어에게 보이는 친근한 표현과,
개발팀이 내부적으로 유지해야 하는 시스템 용어를 분리하기 위한 기준서다.

원칙은 단순하다.

- 플레이어에게는 따뜻하고 직관적인 용어를 보여준다.
- 내부 코드와 설계에서는 데이터 일관성이 높은 용어를 유지한다.

## 2. 핵심 매핑

| 플레이어 노출 용어 | 내부 시스템 용어 | 설명 |
| --- | --- | --- |
| 러니멀 파트너 | `Main Companion`, `Player Carrier Role` | 플레이어는 세계관상 파트너지만, 시스템상 메인 슬롯과 상호작용하는 주체 |
| 활력 에너지 | `Resonance`, `Run Reward Energy` | 러닝으로 생성되는 성장 기반 에너지 |
| 러니멀 알 | `EggInventoryEntry`, `Run Core -> Egg` | 유저에게는 알로 보이지만, 내부적으로는 러닝 데이터 기반 부화 대상 |
| 탐험 구역 | `Region Pack`, `Area Layer` | 플레이어는 구역으로 인식, 내부는 지역 팩 단위로 관리 |
| 무기력 현상 | `Lethargy State`, `World Depletion` | 세계관 재난 상태 |
| 특별한 진화 | `RareVariant`, `Mutation Family`, `Evolution Branch` | 희귀 개체와 변이 계통을 유저에게 부드럽게 표현 |
| 성장 씨앗 | `Growth Seed`, `Growth Value`, `XP Input` | 러닝 데이터에서 환산된 성장 자원 |
| 안내소 요원 | `Guide NPC`, `Tutorial Operator` | 온보딩/가이드용 NPC |
| 협동 미션 | `Season Event`, `Raid`, `Community Objective` | 외부 표현은 협동 미션, 내부는 이벤트/레이드 시스템 |

## 3. 반드시 내부 용어를 유지해야 하는 항목

아래는 코드, 모델, 저장 포맷, 동기화 페이로드에서 유지해야 한다.

- `PetSpecies`
- `PetElement`
- `RareVariant`
- `RunTimeAura`
- `RouteShape`
- `EnvironmentCondition`
- `EggShellType`
- `MainCompanionSelection`
- `CompletedRunRecord`
- `WorkoutSessionArchive`

이 값은 UI 카피에 맞춰 이름을 바꾸더라도,
모델명과 저장 키는 함부로 바꾸지 않는 편이 안정적이다.

## 4. 플레이어 노출 용어 정책

### 4.1 유지해도 되는 내부 용어

아래는 비교적 직관적이라 플레이어 노출에도 사용할 수 있다.

- 시즌
- 페이스
- 케이던스
- 심박
- 거리
- 고도

### 4.2 숨기거나 번역해야 하는 내부 용어

아래는 그대로 보여주면 차갑거나 개발 냄새가 난다.

- resonance
- variant trigger
- genome parameter
- route variability
- mutation family
- live snapshot
- canonical archive

## 5. 추천 카피 규칙

### 5.1 시스템 설명 카피

- 내부: `rare variant unlocked`
- 외부: `특별한 진화가 깨어났어요`

### 5.2 진행 상태 카피

- 내부: `egg progress ratio`
- 외부: `알이 깨어날 준비를 하고 있어요`

### 5.3 성능/메트릭 카피

- 내부: `cadence`, `heartRate`
- 외부: 그대로 사용 가능

### 5.4 확장 콘텐츠 카피

- 내부: `raid`, `event region`
- 외부: `협동 미션`, `특별 이벤트 구역`

## 6. 영역별 언어 사용 기준

### 워치 UI

- 짧고 즉각적이어야 한다.
- 행동 중심 문장 사용
- 측정값은 직관적 유지
- 장문 세계관 설명 금지

예시:

- `러닝 시작하기`
- `알이 반응하고 있어요`
- `밤의 기운이 짙어졌어요`

### iPhone 홈

- 감정과 목표를 함께 전달
- 오늘의 동행, 이번 러닝의 의미, 다음 진화 힌트 제시

### 보관함 / 도감

- 수집 욕구 자극
- 종족, 성향, 특별한 진화 배경 설명

### 이벤트 / 시즌 패널

- 약간 더 서사적이어도 된다.
- 다만 규칙 설명은 구체적이어야 한다.

## 7. 종족명 정책

종족명은 현재 영문 고유명사를 유지하는 것이 좋다.

이유:

- 브랜드 고유성 확보
- 캐릭터 상품화 용이
- 글로벌 확장 대응

대신 설명 문구는 한국어로 충분히 풀어준다.

예시:

- `Windrunner`
  - 바람과 순항을 사랑하는 장거리형 러니멀

## 8. 내부 설계에서 주의할 점

업로드된 초안처럼 감성 용어를 강화하는 것은 좋지만,
아래 둘은 분리해야 한다.

1. 스토리 용어
2. 데이터 모델 용어

스토리 용어가 데이터 모델을 침범하면,

- 저장 포맷이 자주 바뀌고
- 번역 작업이 어려워지며
- QA와 디버깅이 불편해진다

따라서 추천 방식은 아래다.

- 모델은 현재 기술 용어 유지
- UI 문자열 레이어에서만 친근한 이름 사용
- 문서에는 두 언어를 항상 병기

## 9. 최종 원칙

플레이어는 따뜻한 동행 세계를 경험해야 하고,
개발팀은 안정적인 시스템 명세를 유지해야 한다.

Runimal의 언어 체계는 그 둘 사이를 연결하는 번역 레이어여야 한다.
