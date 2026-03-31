# Mutation Form Naming V1

## 목적
- 내부 3축 lineage 문자열은 그대로 유지한다.
- 사용자에게 보이는 이름은 더 짧고 기억하기 쉬운 codename으로 분리한다.
- 확장팩이 늘어나도 같은 규칙으로 이름을 조합할 수 있게 한다.

## 이름 규칙
- `Windrunner`: 바람과 항로 어근을 쓴다.
- `Stoneback`: 지형과 암석 어근을 쓴다.
- `Sparkfang`: 파동과 급가속 어근을 쓴다.
- `Mosshop`: 숲과 생장 어근을 쓴다.
- `Seedle`: 발아와 싹 어근을 쓴다.

## 어근 기준
- `gale`
  - Merriam-Webster에서 강한 바람 계열 의미를 확인했다.
  - https://www.merriam-webster.com/dictionary/gale
- `basalt`
  - Merriam-Webster에서 화산성 암석 의미를 확인했다.
  - https://www.merriam-webster.com/dictionary/basalt
- `surge`
  - Merriam-Webster에서 파도처럼 밀려오거나 갑자기 치솟는 움직임으로 정리된다.
  - https://www.merriam-webster.com/dictionary/surge
- `canopy`
  - Merriam-Webster에서 덮개, 숲의 상층부 의미를 확인했다.
  - https://www.merriam-webster.com/dictionary/canopy
- `germination`
  - Merriam-Webster에서 발아, 성장의 시작으로 정리된다.
  - https://www.merriam-webster.com/dictionary/germination

## 현재 조합 방식
- `Windrunner`: body prefix + ecology suffix
  - 예: `Zephyr Riverside`, `Galecrest Skyline`
- `Stoneback`: body prefix + ecology suffix
  - 예: `Talus Fault`, `Basalt Storm`
- `Sparkfang`: body prefix + rhythm suffix
  - 예: `Volt Tempo`, `Arc Surge`, `Flare Beat`
- `Mosshop`: ecology prefix + rhythm suffix
  - 예: `Canopy Bloom`, `Grove Heal`
- `Seedle`: ecology prefix + rhythm suffix
  - 예: `Sprout Step`, `Germin Root`, `Twilight Bloom`

## UI 원칙
- 메인 UI에는 `displayTitle`만 노출한다.
- 세부 lineage는 도감 상세나 디버그성 문맥에서만 `lineageSummary`로 노출한다.
- 워치에는 1줄만 쓴다.

## 다음 단계
- 시즌/지역 팩이 늘어나면 suffix 사전을 추가한다.
- 희귀 변이와 충돌할 때는 rare variant가 이름 우선권을 가진다.
