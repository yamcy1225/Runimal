# Runimal v2 Imagegen Output

This directory stores candidate outputs and prompt artifacts for Runimal v2 UI/art direction.

Rules:

- Images here are candidate references, not production assets.
- Do not wire these files into `project.yml`, `Package.swift`, or asset catalogs without a later review step.
- Record the prompt, date, tool/model, intended screen, and decision for every generated image.
- Prefer translating accepted ideas into SwiftUI/vector/asset-catalog primitives.

Current prepared artifacts:

- `runimal-v2-ui-briefs.jsonl` — batch-ready prompts for Watch HUD, iPhone route detail, resource allocation, companion growth, and app icon exploration.

Expected generated filenames:

- `runimal-v2-watch-hud-concept.png`
- `runimal-v2-phone-route-detail-concept.png`
- `runimal-v2-resource-allocation-concept.png`
- `runimal-v2-companion-growth-concept.png`
- `runimal-v2-app-icon-concept.png`

## Generated candidate batch — 2026-04-23

Generated via Codex native image generation in CLI 0.123.0 with `image_generation = true`; `$imagegen` CLI and `OPENAI_API_KEY` were not used.

| Candidate | File | Initial read |
| --- | --- | --- |
| Watch in-run HUD | `runimal-v2-watch-hud-concept.png` | Strong metric-first direction: distance and pace dominate, companion footprint is small enough to remain non-blocking. |
| iPhone route detail | `runimal-v2-phone-route-detail-concept.png` | Strong route-first hierarchy with metrics and saved/synced cues; useful reference for `PhoneRunRecordDetailSheet` and `RunimalRoutePreviewShape`. |
| Resource allocation | `runimal-v2-resource-allocation-concept.png` | Best reference for manual-spend UX: unspent run, route evidence, and three explicit spend choices are visually separated. |
| Companion growth | `runimal-v2-companion-growth-concept.png` | Good transaction/audit framing, but production copy should use Runimal terms such as run resource / companion growth instead of generic “Energy Gel”. |
| App icon | `runimal-v2-app-icon-concept.png` | Clear path+paw silhouette candidate; should be vector-redrawn and small-size tested before asset-catalog adoption. |

Adoption rule: treat all files above as reference candidates only. Production work should extract layout, hierarchy, palette, and icon silhouette decisions into SwiftUI/vector assets after accessibility and watch-size review.

## Pixel / handheld virtual pet candidate batch — 2026-04-23

Generated via Codex native image generation in CLI 0.123.0 after the user requested a Tamagotchi-adjacent direction. This batch intentionally avoids direct Tamagotchi branding, device shapes, or copied characters; it translates the preference into Runimal's existing `PixelPetView`, `GameSurface`, `GameBoyPalette`, and `RunimalVisualTile` language.

Prompt artifact:

- `runimal-v2-ui-pixel-briefs.jsonl` — reproducible prompt notes for the pixel Watch HUD, route detail, resource allocation, companion growth, and app icon candidates.

| Candidate | File | Initial read |
| --- | --- | --- |
| Pixel Watch in-run HUD | `runimal-v2-watch-hud-pixel-concept.png` | Strongest immediate production reference: the huge distance/time/pace/HR hierarchy keeps the workout screen readable while the companion stays decorative. |
| Pixel iPhone route detail | `runimal-v2-phone-route-detail-pixel-concept.png` | Good GPS path drawing reference: route-first composition, top metric chips, pet reaction, and history thumbnails fit the v2 record-detail direction. |
| Pixel resource allocation | `runimal-v2-resource-allocation-pixel-concept.png` | Good manual-spend reference: run evidence, unspent resources, allocation targets, and confirmation are separated without gacha/lootbox cues. |
| Pixel companion growth | `runimal-v2-companion-growth-pixel-concept.png` | Good auditability reference: growth preview and receipt/log are visibly separate; production copy should normalize spelling and Runimal terms. |
| Pixel app icon | `runimal-v2-app-icon-pixel-concept.png` | Strong silhouette reference for path+paw+tiny companion; should be redrawn as vector/pixel asset and small-size tested before adoption. |

Adoption note: this batch is the preferred design direction if Runimal moves toward a nostalgic digital-pet identity. Production should not embed the bitmap mockups directly; extract palette, panel rhythm, pixel borders, metric hierarchy, and companion silhouettes into SwiftUI/vector/pixel assets.
