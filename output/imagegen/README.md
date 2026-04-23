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

## Species-locked pixel candidate batch — 2026-04-23

Generated after reviewing the Runimal character/world guides, including `docs/world/current-character-design-lock.ko.md`, `docs/world/base-species-visual-framework.ko.md`, `docs/world/species-color-identity.ko.md`, `docs/world/species-and-mutation-bible.ko.md`, `docs/world/species-visual-anatomy-bible.ko.md`, `docs/world/five-base-species-expansion-architecture.ko.md`, `docs/world/runimal-world-master-bible.ko.md`, and the external Runimal World research note under `/Users/heobella/Downloads/`.

This batch corrects the previous pixel batch: the UI can retain LCD / handheld virtual-pet styling, but Runimal characters must follow the five base species, fixed species colors, distinct silhouettes, and five rare-variant overlay rules.

Prompt artifact:

- `runimal-v2-ui-species-locked-briefs.jsonl` — prompt records and source-doc links for the species-locked matrix and UI candidates.

| Candidate | File | Initial read |
| --- | --- | --- |
| 5 species × 5 rare variants matrix | `runimal-v2-species-variant-matrix-pixel-concept.png` | Best validation image for species identity: base colors/silhouettes remain visible while Tempo Surge, Zen Bloom, Summit Heart, Eclipse Mark, and Loop Sigil act as overlays. |
| Species-locked Watch HUD | `runimal-v2-watch-hud-species-locked-pixel-concept.png` | Keeps Watch metrics first while the companion reads closer to Windrunner/Aeralith than a generic green pet. |
| Species-locked route detail | `runimal-v2-phone-route-detail-species-locked-pixel-concept.png` | Strong Stoneback/Summit Heart direction: route evidence, audited result, species identity, and rare overlay are separated. |
| Species-locked allocation | `runimal-v2-resource-allocation-species-locked-pixel-concept.png` | Better roster/choice reference: all five species chips are visible and manual spending stays separate from variant/growth. |
| Species-locked growth | `runimal-v2-companion-growth-species-locked-pixel-concept.png` | Strong Mosshop/Zen Bloom reference: growth stages, rare variant card, resource receipt, and audit log are not conflated. |

Adoption note: use this batch over the earlier generic pixel batch when translating Runimal companions into SwiftUI. Character implementation must preserve species silhouette, species base color, and variant-as-overlay separation before UI chrome polish.

## Base evolution pixel candidate batch — 2026-04-23

Generated after reviewing `docs/companion-evolution-levels.ko.md`, `docs/world/current-character-design-lock.ko.md`, `docs/world/base-species-visual-framework.ko.md`, `docs/world/species-color-identity.ko.md`, and `Sources/RunimalCore/SpeciesVisualBlueprints.swift`. This batch focuses on clean base-species growth only: no rare variants, no Shadebit, no seasonal overlays.

Prompt artifact:

- `runimal-v2-ui-evolution-briefs.jsonl` — prompt records for the 5 species × 5 growth-stage matrix and one per-species evolution sheet.

| Candidate | File | Initial read |
| --- | --- | --- |
| 5 species × 5 stages matrix | `runimal-v2-evolution-matrix-5x5-pixel-concept.png` | Best overview of all 25 base states: Egg, Infant, Young, Teen/Companion Complete, and Adult/Signature Form for each base species. |
| Windrunner evolution | `runimal-v2-windrunner-evolution-pixel-concept.png` | Strong crest/side-fin/tail-flow continuity for the long-distance cruising species. |
| Stoneback evolution | `runimal-v2-stoneback-evolution-pixel-concept.png` | Strong low, broad, shell-backed growth continuity for the endurance/guard species. |
| Sparkfang evolution | `runimal-v2-sparkfang-evolution-pixel-concept.png` | Strong prankish infant to sharp pursuit-form progression for the tempo/sprint species. |
| Mosshop evolution | `runimal-v2-mosshop-evolution-pixel-concept.png` | Strong round body, leaf-canopy, and core-glow continuity for the recovery species. |
| Seedle evolution | `runimal-v2-seedle-evolution-pixel-concept.png` | Strong seed-core to sprout-tail progression for the starter/adaptation species. |

Adoption note: these images are reference candidates only. Production should translate the accepted silhouettes back into `SpeciesVisualRenderProfile`, `DefaultSpeciesVisualBlueprints.growthStageBlueprints`, and SwiftUI/vector/pixel assets rather than embedding generated bitmaps directly.
