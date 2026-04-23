# Mutation Unlock Engine V1

## 목적

이 문서는 5 기본 종 위에 `체형 / 생태 / 리듬` 3축 변이를 실제 해금 규칙으로 연결하는 1차 기준서다.

## 핵심 원칙

- 기본 종 판정은 [SpeciesRuleEngine.swift](/Users/heobella/jaw-bot-4/apps/runimal-apple/Sources/RunimalCore/SpeciesRuleEngine.swift)에서 결정한다.
- 변이 해금은 별도 엔진에서 `누적 러닝 묶음`을 해석해 branch를 고른다.
- 최종 form은 `body + ecology + rhythm` 3개 branch의 조합으로 결정한다.

## 사용 함수

- [SpeciesMutationUnlockEngine.swift](/Users/heobella/jaw-bot-4/apps/runimal-apple/Sources/RunimalCore/SpeciesMutationUnlockEngine.swift)
  - `buildProfile(from:)`
  - `resolveForm(for:preferredSpecies:blueprints:)`
  - `resolveForm(speciesID:profile:blueprints:)`

## 해석에 쓰는 누적 값

- 러닝 수
- 총 거리
- 최장 거리
- 평균 거리
- 평균 페이스
- 평균 케이던스
- 평균 고도 상승
- 평균 경로 변화도
- 시간대 비율
- 경로 형태 비율
- 환경 비율
- rare event 횟수

## branch 선택 규칙 예시

### Windrunner

- `aero-swift`: 평균 거리와 순항 페이스가 높을수록 유리
- `river-open`: 왕복형 장거리 비중이 높을수록 유리
- `draft-route`: out-and-back 비율이 높을수록 유리

### Stoneback

- `summit-core`: 평균 고도 상승과 냉기/강풍 비중이 높을수록 유리
- `storm-slope`: wind 비율이 높을수록 유리
- `climb-pulse`: climb 세션 비중이 높을수록 유리

### Sparkfang

- `burst-swift`: 짧고 빠른 세션일수록 유리
- `signal-track`: maze/freeform + 높은 변화도일수록 유리
- `surge-fang`: 고케이던스일수록 유리

### Mosshop

- `rain-wildland`: 비 오는 러닝 비중이 높을수록 유리
- `calm-loop`: loop 비율과 낮은 변화도가 높을수록 유리
- `drift-heal`: recovery pace일수록 유리

### Seedle

- `root-guard`: 반복 러닝 수와 누적 거리가 높을수록 유리
- `twilight-bud`: dusk/night 비율이 높을수록 유리
- `grow-loop`: 반복 루프와 누적 습관성이 높을수록 유리

## Shadebit 처리

- `shadebit`는 기본 종으로 해금하지 않는다.
- 변이 해금 엔진에서는 `sparkfang` 기준으로 canonicalize한다.
- 실제로는 `signal-track`, `shock-beat`, `eclipse-mark` 같은 야간/황혼 branch와 variant에서 form 감각을 만든다.

## 검증

- [SpeciesMutationUnlockEngineTests.swift](/Users/heobella/jaw-bot-4/apps/runimal-apple/Tests/RunimalCoreTests/SpeciesMutationUnlockEngineTests.swift)
  - Windrunner 장거리 왕복
  - Stoneback 오르막 강풍
  - Sparkfang 야간 신호 코스
  - Seedle 반복 성장 루프
