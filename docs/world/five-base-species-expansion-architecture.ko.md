# Five Base Species Expansion Architecture

## 결론

Runimal의 기본 종족 값은 `5종`으로 고정한다.

- Windrunner
- Stoneback
- Sparkfang
- Mosshop
- Seedle

`Shadebit`는 독립 기본 종에서 빼고,
향후 `야간/황혼 계열 lineage` 또는 `special region form`으로 재배치한다.

## 왜 5종인가

현재 러닝 규칙 엔진은 아래 입력 축으로 종족을 판정한다.

- 거리
- 페이스
- 케이던스
- 고도 상승
- 시간대
- 경로 형태
- 환경 상태
- 경로 변화도

이 축 조합 전체를 계산해 보면,
독립 기본 종으로 자연스럽게 유지되는 수는 `5`가 가장 안정적이다.

현재 단계에서 `shadebit`는 완전 독립 종보다는
`sparkfang 계열의 야간/왜곡 분기`에 더 가깝다.

## 확장 구조

기본 종 5종에 대해 아래 3축을 둔다.

- Body Axis
- Ecology Axis
- Rhythm Axis

각 축당 3개 브랜치를 두면:

- `5 x 3 x 3 x 3 = 135 forms`

즉 기본 종은 5종이어도,
실제 수집 가능한 개체는 100종을 훨씬 넘길 수 있다.

## 샘플 구조

### Core Taxonomy

- 기본 종: 5
- 축: 3
- 축당 브랜치: 3
- 잠재 폼 수: 135

### Starter Showcase Sample

- 현재 샘플 roster: 20
- 이 값은 상한이 아니라 예시 묶음이다
- 실제 운영 수는 시즌/지역/이벤트에 따라 계속 늘어난다

## 구현 원칙

1. 기본 종은 늘리지 않는다.
2. 신규 콘텐츠는 새 기본 종이 아니라 새 branch/form으로 푼다.
3. 패치형 확장은 지역, 시즌, 희귀 변이, 협동 이벤트를 통해 확장한다.
4. 플레이어에게는 `새 러니멀`처럼 보여도 내부적으로는 form schema를 유지한다.

## 코드 뼈대

- [SpeciesExpansionModels.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/Sources/RunimalCore/SpeciesExpansionModels.swift)
- [DefaultSpeciesExpansionBlueprints.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/Sources/RunimalCore/DefaultSpeciesExpansionBlueprints.swift)
- [SpeciesExpansionEngineTests.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/Tests/RunimalCoreTests/SpeciesExpansionEngineTests.swift)

## 다음 단계

1. world content seed를 5 base species 기준으로 재편
2. shadebit를 twilight lineage 또는 special form으로 재배치
3. 샘플 roster를 도감/보관함/워치 노출 구조에 연결하되, 상한 없이 확장 가능하게 유지
