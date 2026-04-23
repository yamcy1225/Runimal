# Runimal v2 Image Generation Briefs

이 문서는 Runimal v2 UI/아트 디렉션을 높이기 위한 `$imagegen` / Codex image generation용 실행 브리프다. 모든 결과물은 production asset이 아니라 후보 레퍼런스이며, 채택 전 접근성/가독성/구현 비용 리뷰를 거친다.

## Global negative constraints

Use these constraints for every prompt:

- No copied characters, no existing game UI imitation, no brand logos, no watermark.
- Avoid clutter, lootbox/gacha feel, casino visuals, excessive neon bloom, illegible tiny text, fake map tiles as the main visual.
- Do not let mascot art hide the running metrics.
- Prefer SwiftUI-translatable shapes, clear spacing, and accessible contrast.

## Brief 1 — Apple Watch Running HUD

```text
Use case: ui-mockup
Asset type: Apple Watch in-run HUD art direction
Primary request: Original Runimal v2 Apple Watch running HUD concept focused on instant readability during a real outdoor run.
Scene/background: black OLED watch display, subtle premium sport-game surface, no map tile background.
Subject: huge distance and current pace numerals, elapsed time, heart rate, cadence, GPS status, tiny companion orb/silhouette that never distracts.
Style/medium: high-fidelity SwiftUI-like app mockup, premium fitness UI with restrained cute running game identity.
Composition/framing: 1:1 watch screen, distance and pace dominate, secondary metric chips below, tiny companion in the corner.
Lighting/mood: crisp dark mode, high contrast, calm energetic mood.
Color palette: deep black, off-white numerals, restrained mint/lime accent, small warm companion accent.
Quality: high
Constraints: readable at Apple Watch size; no clutter; no map tiles; no fake brand logos; no watermark.
Avoid: oversized mascot, RPG battle HUD, neon overload, illegible micro labels.
```

Acceptance criteria:

- 거리/페이스가 가장 크게 보인다.
- companion은 10–15% 이하의 시각 비중이다.
- 실제 Watch 러닝 중 2초 glance로 읽을 수 있다.

## Brief 2 — iPhone Post-Run Detail / GPS Path Drawing

```text
Use case: ui-mockup
Asset type: iPhone post-run workout detail screen
Primary request: Original Runimal v2 iPhone workout detail concept where GPS path drawing is the central proof of the run.
Scene/background: dark mode mobile app screen, route path line art over a quiet abstract terrain grid, not a map tile product.
Subject: GPS path drawing, distance, total time, average pace, heart rate, cadence, elevation, sync status, audit-friendly saved workout card.
Style/medium: polished SwiftUI-like mobile UI, premium sports app with subtle game warmth.
Composition/framing: phone portrait screen, route path hero card on top, metrics in clean rows, growth resource card below separated by spacing.
Lighting/mood: calm post-run completion, clear and trustworthy.
Color palette: charcoal, warm off-white, mint route line, amber resource accent.
Quality: high
Constraints: path drawing must be central; workout archive and growth resource must be visually separate; no map-tile dominance; no watermark.
Avoid: busy dashboard, auto-feed implication, lootbox reward screen, fake map labels.
```

Acceptance criteria:

- route line이 화면의 시각 중심이다.
- 저장/동기화된 운동 기록과 성장 리소스가 분리되어 보인다.
- 지표가 장식보다 우선한다.

## Brief 3 — Post-Run Resource Allocation Card

```text
Use case: ui-mockup
Asset type: post-run growth resource allocation card
Primary request: Original Runimal v2 resource allocation UI showing a completed run as an unspent resource that the user manually assigns.
Scene/background: iPhone dark mode card stack after a run, no casino or lootbox styling.
Subject: unspent run card with distance/time/pace/path evidence, three explicit actions: feed companion, prepare egg incubation, forge new egg.
Style/medium: premium fitness RPG UI, clear product UX, SwiftUI-translatable cards and chips.
Composition/framing: central unspent run card, action choices below, companion reaction small and separate from the run record.
Lighting/mood: satisfying but controlled; user agency first.
Color palette: dark graphite, off-white text, mint route, amber resource token, soft companion accent.
Quality: high
Constraints: manual spend model must be obvious; no auto-consumption; no lootbox; no random reward chest; no watermark.
Avoid: gambling cues, bursting coins, oversized treasure chest, confetti hiding metrics.
```

Acceptance criteria:

- 사용자가 “이 기록을 어디에 쓸지 선택한다”는 점이 즉시 보인다.
- 운동 기록의 증거성이 유지된다.
- companion reaction은 별도 레이어로 보인다.

## Brief 4 — Companion Growth / Feeding Screen

```text
Use case: ui-mockup
Asset type: companion growth and feeding screen art direction
Primary request: Original Runimal v2 companion growth screen after the user chooses to spend a completed run resource.
Scene/background: cozy dark mode training sanctuary, minimal and readable, not fantasy clutter.
Subject: small athletic companion silhouette, growth progress, selected run resource receipt, before/after level preview, clear confirmation action.
Style/medium: charming but mature mobile game UI, vector-friendly mascot shapes, SwiftUI-like layout.
Composition/framing: companion on one side, resource receipt and growth preview on the other, confirmation button at bottom.
Lighting/mood: warm encouragement, trustworthy transaction, no gacha excitement.
Color palette: charcoal, cream, soft green, gentle amber, one companion species accent.
Quality: high
Constraints: companion must be original and simple enough for Watch translation; transaction must feel auditable; no copied creature designs.
Avoid: monster-collection imitation, lootbox reveal, complex fantasy background, too many stats.
```

Acceptance criteria:

- 성장 전/후가 이해된다.
- “운동 기록을 소비한다”는 UX가 숨겨지지 않는다.
- mascot이 작은 화면용 silhouette로 재해석 가능하다.

## Brief 5 — App Icon Direction

```text
Use case: logo-brand
Asset type: Runimal v2 app icon exploration
Primary request: Original Runimal v2 app icon direction combining running path, companion presence, and reliable fitness tracking.
Scene/background: iOS app icon square with rounded-corner safe composition.
Subject: simple GPS route line forming a subtle companion paw/runner spark shape, premium dark background, no text.
Style/medium: vector-friendly icon concept, clean modern app icon, not childish.
Composition/framing: centered symbol, strong silhouette at small size, no detailed mascot face.
Lighting/mood: energetic, trustworthy, polished.
Color palette: deep navy/black, mint route stroke, small amber life accent.
Quality: high
Constraints: no text, no existing logos, no watermark, must read at small app icon size.
Avoid: complex illustration, copied animal logo, generic running shoe icon.
```

Acceptance criteria:

- 40px 수준에서도 silhouette가 유지된다.
- 러닝 기록과 companion 정체성이 함께 느껴진다.
- production 전 vector translation이 가능하다.

## Batch generation plan

Generate one candidate per brief first. Review against `docs/v2/design-direction-v2.md`, then iterate only on accepted directions.

Suggested output names:

- `runimal-v2-watch-hud-concept.png`
- `runimal-v2-phone-route-detail-concept.png`
- `runimal-v2-resource-allocation-concept.png`
- `runimal-v2-companion-growth-concept.png`
- `runimal-v2-app-icon-concept.png`
