# Runimal v2 Design Direction

Runimal v2의 시각 방향은 “운동 기록 앱으로 먼저 신뢰받고, 운동 후에 러닝 게임으로 확장되는 경험”이다. `$imagegen` / Codex image generation 결과물은 이 방향을 빠르게 탐색하기 위한 후보 레퍼런스이며, 그대로 production asset으로 채택하지 않는다.

## Core stance

- **운동 중:** 스포츠 워치 UI처럼 즉시 읽힌다. 장식은 한눈 판독을 방해하지 않는 선에서만 허용한다.
- **운동 직후:** GPS path drawing과 핵심 지표가 주인공이다. 캐릭터/성장 요소는 기록의 의미를 설명하는 보조 레이어다.
- **성장 루프:** 완료된 운동 기록은 자동 소비되지 않는 `unspent run resource`로 보인다. 사용자는 기록을 어디에 쓸지 직접 선택한다.
- **브랜드 톤:** 귀엽고 생동감 있지만, 과한 네온/가챠/복잡한 RPG HUD가 아니라 “프리미엄 러닝 게임”에 가깝다.

## Visual hierarchy

### Apple Watch in-run

1. 거리
2. 현재 페이스
3. 경과 시간
4. 심박수 / 케이던스 / GPS 상태
5. live companion 반응

Watch 화면에서 companion은 “러닝 중 동행감”을 주되 기록/지표를 가리지 않는다. companion 영역은 작은 orb, silhouette, micro animation cue 정도로 제한한다.

### iPhone post-run detail

1. GPS path drawing
2. 거리 / 시간 / 평균 페이스 / 심박 / 케이던스 / 상승고도
3. 저장/동기화 상태
4. 성장 리소스 카드
5. companion 반응 / 선택 가능한 소비 액션

지도 타일은 배경 맥락일 수 있지만 핵심 제품축은 아니다. v2는 선형 GPS path를 기록 증거이자 시각 정체성으로 삼는다.

### Growth allocation

- “운동 기록”과 “성장 소비”를 시각적으로 분리한다.
- 소비 전 상태는 `unspent`, 소비 후 상태는 `spent`로 명확히 표현한다.
- 버튼 문구는 보상 획득보다 사용자의 선택을 강조한다: `동행 성장에 사용`, `알 부화 준비`, `새 알 만들기`.

## Image generation usage policy

- 생성 이미지는 `output/imagegen/`에 후보로 저장한다.
- 각 후보는 prompt, 생성 일자, 용도, 채택/보류/폐기 판단을 함께 남긴다.
- 생성 이미지를 그대로 앱에 넣지 않는다. SwiftUI, vector, asset catalog로 번역 가능한 구조만 채택한다.
- 기존 캐릭터/상표/게임 UI를 모방하지 않는다.
- Watch 화면 후보는 실제 Apple Watch 크기에서 판독 가능해야 한다.

## Design quality bar

Accepted candidates must pass all of these checks:

- 2초 안에 주요 수치가 읽힌다.
- OLED/dark mode에서 대비가 충분하다.
- companion이 metric hierarchy를 침범하지 않는다.
- GPS path drawing이 기록의 중심으로 보인다.
- 성장 카드는 가챠/lootbox처럼 보이지 않는다.
- SwiftUI로 재현 가능한 레이아웃이다.

## Species-locked companion art direction

The pixel / handheld virtual-pet direction is acceptable only if companion art remains locked to the Runimal world guides:

- Base species are five: Windrunner/Aeralith, Stoneback/Cragmantle, Sparkfang/Cinderlash, Mosshop/Mossveil, and Seedle/Dawnsprig.
- Shadebit is a twilight special form, not a sixth base species.
- Species identity must come from silhouette, body proportion, cheek/body line, top accent, and fixed base color rather than arbitrary decoration.
- Rare variants are overlays/signatures, not replacement species: Tempo Surge, Zen Bloom, Summit Heart, Eclipse Mark, and Loop Sigil must sit on top of the base species color and silhouette.
- Growth stage and variant state must be shown as separate concepts in the UI.
- Labels, badges, and roster chips must never cover the character.

Current source-of-truth docs for companion UI work:

- `docs/world/current-character-design-lock.ko.md`
- `docs/world/base-species-visual-framework.ko.md`
- `docs/world/species-color-identity.ko.md`
- `docs/world/species-and-mutation-bible.ko.md`
- `docs/world/species-visual-anatomy-bible.ko.md`
- `docs/world/five-base-species-expansion-architecture.ko.md`
- `docs/world/runimal-world-master-bible.ko.md`

Design candidates that do not preserve these constraints should be treated as mood references only, not production references.
