# Runimal v2 Resource Allocation UI

This is the first design pass after the phone-side resource ledger became runtime-verifiable. The UI goal is not decoration: it must make the manual-spend model obvious so users trust that a completed run is preserved as an audit record while a separate resource can be allocated once.

## Product rule

A completed run has two concepts:

1. **Workout archive** — immutable evidence: route, time, distance, pace, heart rate, cadence, elevation.
2. **Run resource** — spendable growth material derived from that archive; it starts unspent and can be spent once.

The UI must never imply that receiving/syncing a workout automatically feeds a companion.

## Screen placement

Primary placement: post-run detail / run record detail sheet.

Secondary placement: collection/growth tab summary card showing unspent resources count and next recommended allocation.

Avoid adding this to the watch in-run screen. The watch remains recording-first and glanceable.

## Proposed card hierarchy

### 1. Evidence header

- Mini GPS path drawing, not a map tile.
- Distance / duration / average pace as the first row.
- Heart rate / cadence / elevation as compact chips.
- Label: `운동 기록 보존됨`.

### 2. Resource state capsule

States:

- `미사용 러닝 코어` — available, primary CTA enabled.
- `이미 배분됨` — spent, show target and timestamp/audit note when available.
- `레거시 기록` — no v2 sidecar; allow current v1 behavior but do not claim v2 audit completeness.
- `동기화 확인 중` — archive present but sidecar status not loaded yet.

### 3. Allocation choices

Show choices only for unspent v2 resources:

- `동행 성장에 사용`
- `새 알 생성`
- `선택한 알 부화 준비`

Each choice should preview expected effect before spending. The spend happens only after confirmation/action success.

### 4. Post-spend receipt

After spend, show a calm receipt instead of lootbox energy:

- target type and name;
- source run ID/date;
- preserved metrics link;
- note: `운동 기록은 그대로 보존되고, 성장 코어만 사용되었습니다.`

## Visual direction

- Premium fitness RPG, not casino/lootbox.
- Route line is the hero visual; resource crystal/card is a secondary layer.
- Use one strong accent color from the companion/species, but keep metric text high contrast.
- Small motion is allowed only on confirmation; no idle pulsing that competes with metrics.

## `$imagegen` prompt seed

Use when `OPENAI_API_KEY` is available and the team wants bitmap exploration:

> Original mobile UI concept for Runimal v2 post-run resource allocation, GPS path line drawing as the main evidence, distance time average pace heart rate cadence elevation visible, separate unspent run core card, user chooses companion growth or egg incubation, premium fitness RPG, Korean mobile app sensibility, high contrast dark mode, no lootbox, no map tiles, clean expert product design.

Acceptance filter:

- The route and metrics are readable before the companion art.
- The spendable resource is visually separate from the workout archive.
- The design does not look like a gacha pull or random reward screen.
- It can be translated into SwiftUI with existing `GameBoyPalette`, `RunimalRoutePreviewShape`, and detail-sheet components.

## OpenGame prototype brief

OpenGame is available as an external prototype CLI (`opengame` 0.6.0), but must stay outside `Package.swift`, `project.yml`, and app targets.

Prototype prompt:

> Build a tiny web prototype for Runimal v2 resource allocation. Show a post-run card with route evidence and metrics, an unspent run core, three allocation choices, preview-before-spend behavior, and a spent receipt. Avoid lootbox/gacha language. Prioritize comprehension over animation.

Prototype success criteria:

1. A user can explain that the workout archive remains saved after spending.
2. A user can see whether a run core is unspent/spent/legacy.
3. The design makes double-spend impossible from the visible state.
4. The prototype reveals whether route-first or resource-first hierarchy is clearer.

## SwiftUI translation plan

1. Add a small `RunResourceState` view model in the phone UI layer.
2. Reuse `RunimalRoutePreviewShape` for path evidence.
3. Add `RunResourceAllocationCard` beside existing run detail actions.
4. Gate CTAs with the existing `canSpendRunResourceIfPresent(runID:)` rule.
5. Record spend result and show a receipt state after successful feed/forge/incubate.

Do not implement production UI until the hardware watch→phone sidecar flow has been verified or a simulator fixture can fully mimic that flow in visible UI.
