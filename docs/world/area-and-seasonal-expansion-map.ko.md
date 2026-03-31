# Runimal Area And Seasonal Expansion Map

## 1. 목적

이 문서는 Runimal 월드를 업데이트와 확장팩 단위로 넓히기 위한 지도다.

핵심은 새 기능을 그냥 추가하는 것이 아니라,
항상 `새 지역`, `새 생태`, `새 종족/변이`, `새 서사` 묶음으로 확장하는 것이다.

## 2. 기본 지역 구조

### Area 01. 도심 구역

- 현실 트리거: 생활권 러닝, 공원, 강변, 짧은 반복 코스
- 분위기: 시작, 튜토리얼, 교감의 첫 단계
- 주력 종족: Seedle, Sparkfang, Windrunner
- 핵심 보상 방향: 입문형 종족 수집, 기본 알 획득

### Area 02. 자연 구역

- 현실 트리거: 숲길, 산책로, 우천/자연 환경
- 분위기: 회복, 관찰, 부드러운 성장
- 주력 종족: Mosshop, Seedle
- 핵심 보상 방향: 회복형 진화, 평온형 희귀 변이

### Area 03. 고지대 구역

- 현실 트리거: 오르막, 계단, 높은 고도 상승
- 분위기: 인내, 돌파, 방어
- 주력 종족: Stoneback
- 핵심 보상 방향: 탱커형 파생, 고도형 특별 진화

### Area 04. 달빛 구역

- 현실 트리거: 야간 러닝, 낮은 조도, 변칙 골목 경로
- 분위기: 신비, 비밀, 그림자
- 주력 종족: Sparkfang, Seedle
- 핵심 보상 방향: 야간형 변이, 황혼 계열 form 조우

### Area 05. 특별 이벤트 구역

- 현실 트리거: 시즌 이벤트, 협동 목표, 특정 기간 조건
- 분위기: 축제, 구조, 공동체
- 주력 종족: 시즌 한정 또는 전설급
- 핵심 보상 방향: 한정 개체, 외형 아이템, 칭호

## 3. 시즌 구조

### Season 0: Quiet Signal

- 역할: 세계의 기본 규칙 소개
- 감정: 조용한 발견, 첫 교감
- 목표: 알과 동행체의 의미를 이해시키기
- 확장 요소: 기본 종 5종과 초기 희귀 변이만 노출

### Season 1: Gale Frontier

- 초점: 바람과 순항 생태권 확장
- 강화 종족: Windrunner
- 추천 콘텐츠:
  - 장거리 이벤트
  - 경로 기반 조우
  - 루프/장거리 특화 희귀 변이

### Season 2: Verdant Circuit

- 초점: 회복, 자연, 호흡 리듬
- 강화 종족: Mosshop, Seedle
- 추천 콘텐츠:
  - 산책/회복형 러닝 보상 강화
  - Zen Bloom 서사 확대
  - 숲 복원 이벤트

### Season 3: Summit Fault

- 초점: 고도와 인내
- 강화 종족: Stoneback
- 추천 콘텐츠:
  - 언덕 챌린지
  - 누적 고도 협동 목표
  - Summit Heart 계열 최상위 파생

### Season 4: Hollow Dusk

- 초점: 야간과 그림자
- 강화 종족: Sparkfang, Seedle
- 추천 콘텐츠:
  - 야간 이벤트
  - 달빛 구역 스토리
  - Eclipse Mark와 황혼 계열 확장

### Season 5: City Pulse

- 초점: 템포, 도심, 집단 리듬
- 강화 종족: Sparkfang
- 추천 콘텐츠:
  - 인터벌 미션 강화
  - 러닝 크루 협동 이벤트
  - Tempo Surge 계열 확장

## 4. 확장팩 단위 설계

각 확장팩은 최소 아래 구성으로 출시한다.

1. 신규 Area 또는 기존 Area 심화
2. 신규 Species 1~3종 또는 기존 Species 신규 Mutation Family / special form
3. 신규 Rare Variant 1~2종
4. 신규 Episode 1개 이상
5. 신규 수집 보상

## 5. 에피소드 구조

모든 시즌/지역 에피소드는 아래 흐름을 추천한다.

1. 이상 징후 감지
2. 특정 러닝 습관 요구
3. 미션 또는 누적 목표 수행
4. 러니멀 반응 변화
5. 구역 안정화 또는 신규 종 해금

## 6. 예시 에피소드

### Episode: 잠든 바람길

- 지역: 도심 구역 -> Gale Frontier 연결부
- 조건: 3회 이상 안정 장거리 러닝
- 서사: 바람길이 끊어져 Windrunner가 길을 잃음
- 보상: Windrunner 신규 파생 해금

### Episode: 이끼의 호흡

- 지역: 자연 구역
- 조건: 쿨다운/회복 러닝 누적
- 서사: 숲의 숨결이 약해져 Mosshop 집단이 잠듦
- 보상: Zen Bloom 계통 강화

### Episode: 달빛의 금

- 지역: 달빛 구역
- 조건: 야간 러닝 + 변칙 경로
- 서사: 그림자 경계가 열리며 황혼 계열 form의 흔적 발견
- 보상: Eclipse Mark 조우 확률 개방

## 7. 기술 연결용 최소 데이터

### RegionPack

- regionID
- title
- unlockCondition
- environmentBias
- activeSpecies
- activeVariants
- routeShapeBias
- narrativeSummary

### SeasonPack

- seasonID
- title
- theme
- featuredAreas
- featuredSpecies
- featuredVariants
- eventHooks

### NarrativeEpisode

- episodeID
- seasonID
- areaID
- triggerRules
- playerFacingText
- rewardPayload

## 8. 운영 원칙

- 새 시스템을 만들 때는 먼저 어느 Area/Season에 속하는지 정한다.
- 새 종족을 만들 때는 먼저 어느 환경과 감정에 대응하는지 정한다.
- 새 희귀 변이를 만들 때는 먼저 어떤 러닝 습관의 상징인지 정한다.

## 9. 최종 원칙

Runimal의 확장은 메뉴를 늘리는 방식이 아니라,
플레이어가 “이번 업데이트로 새로운 세계가 열렸다”고 느끼게 만드는 방식이어야 한다.
