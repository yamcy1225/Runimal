# Species Rule Engine V1

## 목적

이 문서는 `runimal-world-master-bible.ko.md`의 1번 작업인
`현재 6종의 종족 바이블 세부화`를 실제 게임 규칙으로 내린 기준서다.

이번 버전은 감성 문구가 아니라,
러닝 기록이 어떤 종족으로 해석되는지에 대한 판정 규칙을 고정한다.

## 조사 기반

이번 규칙은 브라우저 자동화로 직접 확인한 러닝 자료를 참고해 잡았다.

- PubMed 검색 결과:
  - running cadence 관련 검색 결과에서 `cadence <170 spm`이 낮은 케이던스 기준선으로 반복 언급됨
  - trail/performance 검색 결과에서 고도 상승이 별도 퍼포먼스 변수로 독립적으로 다뤄짐
- Runner's World 기사:
  - max heart rate는 개인별 측정 기반이 가장 정확하다는 점 확인

## 이번 단계에서 채택한 해석 원칙

1. 절대값으로 비교해도 무리가 적은 지표를 우선 사용한다.
2. 개인 max HR가 없는 심박은 주 규칙에서 제외한다.
3. 종족 판정은 단일 if문이 아니라 가중치 합산으로 처리한다.
4. 알 껍질 편향은 남기되, 실제 러닝 패턴이 더 강하면 그쪽이 이기게 만든다.

## 밴드 기준

### 거리

- short: 4km 미만
- standard: 4km 이상 8km 미만
- long: 8km 이상 12km 미만
- endurance: 12km 이상

### 페이스

- fast: 5:30/km 미만
- tempo: 5:30/km 이상 6:30/km 미만
- steady: 6:30/km 이상 8:00/km 미만
- recovery: 8:00/km 이상

### 케이던스

- low: 165 spm 미만
- steady: 165 이상 171 미만
- quick: 171 이상 176 미만
- surge: 176 이상

### 고도 상승

- flat: 40m 미만
- rolling: 40m 이상 120m 미만
- climb: 120m 이상

### 경로 변화도

- stable: 0.10 미만
- adaptive: 0.10 이상 0.17 미만
- chaotic: 0.17 이상

## 종족별 핵심 법칙

### Windrunner

- 장거리, 왕복 루트, 바람, 낮/새벽, 안정적 리듬에서 강함
- 가장 대표적인 long-distance species

### Stoneback

- climb, cold, low cadence, 언덕형 패턴에서 강함
- 장거리보다 `버티는 러닝`에 더 큰 가중치

### Sparkfang

- fast pace, surge cadence, heat, 짧고 강한 러닝에서 강함
- rare event와 결합 시 추가 보정

### Mosshop

- rain, steady pace, balanced cadence, loop route에서 강함
- 회복/안정형 종족

### Shadebit

- night, dusk, maze, chaotic variability에서 강함
- 변칙성과 저조도 환경을 반영

### Seedle

- 짧고 느린 회복 러닝, 초반 패턴에서 강함
- 데이터가 부족한 초기 플레이어 보호용 기본 종족

## 제외한 것

### 심박

현재 `CompletedRunRecord`에는 평균 심박만 있고,
개인별 max HR 또는 zone 기준이 없다.

그래서 이번 버전에서는 심박을 메인 종족 판정에서 제외했다.
다음 단계에서는 아래 둘 중 하나가 들어오면 심박 축을 붙인다.

1. 사용자 max HR
2. 사용자 resting HR + 추정 zone

## 코드 반영 위치

- 종족 규칙 엔진:
  - `Sources/RunimalCore/SpeciesRuleEngine.swift`
- 기본 종족 판정 연결:
  - `Sources/RunimalCore/GameEngine.swift`
- 알 부화 편향 연결:
  - `Sources/RunimalCore/RunimalEggEngine.swift`
- 회귀 테스트:
  - `Tests/RunimalCoreTests/SpeciesRuleEngineTests.swift`

## 다음 단계

1. 변이 트리 해금 규칙으로 확장
2. 지역/시즌 판정과 종족 판정을 연결
3. 심박 zone 데이터가 확보되면 species/variant 규칙에 심박 축 추가
