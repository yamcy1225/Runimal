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
