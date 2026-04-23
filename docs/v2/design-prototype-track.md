# Runimal v2 Design and Prototype Track

This track keeps expert visual design and game-loop prototyping powerful but non-destructive. It must not compromise the first-priority recording/sync loop.

## Tools

- `$imagegen`: original bitmap candidate generation for moodboards, icons, companion silhouettes, route/result-card art, onboarding/key art, and marketing frames.
- OpenGame (`/Users/heobella/tools/OpenGame`, CLI `opengame` 0.6.0): external web-game prototype tool for testing reward-loop feel, companion reactions, result-card flow, and simple growth interactions.

## Guardrails

- Generated images are candidates, not production assets.
- OpenGame output is reference/prototype material, not Swift app code.
- No OpenGame dependency should be added to `Package.swift`, `project.yml`, or app targets without a later explicit migration plan.
- Watch in-run UI remains metric-first and readable.
- Path display remains GPS path drawing-first, not map-tile-first.

## Artifact policy

For each generated design/prototype artifact, record:

1. Purpose
2. Prompt or prototype brief
3. Date/tool/version
4. Accepted/rejected/deferred decision
5. Rationale
6. SwiftUI/asset-catalog translation task, if accepted

## First useful experiments

1. App icon and companion silhouette directions that respect `docs/world/current-character-design-lock.ko.md`.
2. Post-run result card visual hierarchy: distance/time/pace/path first, growth decision second.
3. Companion reaction loop prototype: emotional feedback without auto-consuming the workout record.
4. Growth resource comprehension prototype: user clearly understands an unassigned run resource can be spent manually.
