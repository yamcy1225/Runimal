# Runimal v2 Rebuild Plan

## Why this is a selective rebuild, not a rewrite

Runimal already has a working Apple-platform base: iPhone, Apple Watch, macOS, shared Swift package code, core tests, watch-side run lifecycle, WatchConnectivity sync payloads, workout archives, FIT import/export, reward simulation, self-check tooling, and product documentation. A blank rewrite would discard too much verified behavior.

Runimal v2 should therefore be rebuilt by extracting the durable product loop and placing it behind clearer boundaries:

1. Keep the proven workout/growth principles.
2. Wrap or migrate useful v1 code into v2 modules gradually.
3. Isolate exploratory or presentation-heavy features that distract from the reliable running loop.
4. Create new v2 directories beside existing targets before changing target membership.

## Current baseline observed

- `README.md` states iPhone and Apple Watch real-device install/run were confirmed.
- `project.yml` declares `RunimalPhone`, `RunimalWatch`, and `RunimalMac`, all depending on the local `RunimalPackage` product `RunimalCore`.
- `Package.swift` declares `RunimalCore`, `RunimalCLI`, `RunimalSelfCheck`, `RunimalRewardSimulation`, and `RunimalCoreTests`.
- `RunimalWatch/WatchRunSessionManager.swift` owns HealthKit workout sessions, route builder setup, GPS route capture, cadence/pedometer support, run start/end, completed record creation, and `WorkoutSessionArchive` creation.
- `RunimalWatch/WatchConnectivityManager.swift` queues live snapshots, completed run records, full workout archives, and archive package files through WatchConnectivity.
- `RunimalPhone/PhoneConnectivityManager.swift` receives watch payloads, decodes workout archive packages, and persists audit trail state.
- `RunimalPhone/PhoneDashboardStore+WorkoutArchive.swift` ingests canonical archives into phone progress.
- `RunimalPhone/PhoneFITImportManager.swift` imports FIT files into the same `CompletedRunRecord` rule path.
- `docs/live-companion-and-run-core.ko.md` explicitly protects the live-companion vs run-core split.

## Scope for this rebuild track

In scope:

- v2 documentation and migration boundaries.
- A v2 skeleton that does not disturb existing v1 app targets.
- A domain model draft for reliable recording, watch-local persistence, later phone sync, path rendering, and growth-resource conversion.
- Inventory of reusable, refactorable, isolatable, and redesign-needed assets.
- A small-success implementation roadmap.

Out of scope for the first rebuild pass:

- Replacing existing app target entry points.
- Deleting offline map, demo, world, or raid assets.
- Rewriting HealthKit/FIT/WatchConnectivity code in place.
- Shipping polished UI or complete gameplay expansion.
- Changing signing, bundle IDs, or Xcode target membership.

## v2 strategy

### Phase 0: protect and document

- Add this plan and companion architecture documents.
- Add root `AGENTS.md` rebuild rules.
- Create separate v2 folders and placeholder files.
- Leave `project.yml` and `Package.swift` untouched until a tested target-integration step.

### Phase 1: domain-first minimal recording loop

- Define v2-neutral run session, sample, metric summary, route path, archive envelope, and sync state models.
- Decide which v1 `WorkoutSessionArchive`, `WorkoutTrackPoint`, `CompletedRunRecord`, and `RunRewardSummary` models are wrapped versus superseded.
- Add tests for pure domain transformations before app-target integration.

### Phase 2: watch boundary

- Wrap the current watch run session lifecycle behind a v2 recording service boundary.
- Require watch-local archive persistence before sync attempts.
- Ensure failed/late phone availability cannot lose a completed workout.

### Phase 3: sync boundary

- Redefine sync as durable outbound archive envelopes, retry state, delivery audit, and phone-side canonical ingest.
- Preserve WatchConnectivity as the first implementation, but keep a protocol boundary for future transport changes.

### Phase 4: phone archive and growth boundary

- Rebuild phone list/detail around workout records first.
- Keep growth as a manual spend action using unassigned workout resources.
- Only then reattach companion, egg, mutation, world, and seasonal systems.

### Phase 5: imports/exports/tooling

- Preserve FIT import/export and simulation/self-check assets.
- Rehome macOS into QA/balance/content tools rather than primary consumer UI.

### Phase 6: expert design and prototype production

- Add a deliberate design track powered by `$imagegen` for original Runimal v2 visual exploration.
- Use image generation for moodboards, app-icon exploration, companion silhouette studies, route/result-card art direction, App Store/marketing frames, and high-fidelity visual references.
- Use OpenGame as a separate, external prototyping tool for web-game loop experiments, reward interaction sketches, and companion/result-card UX probes.
- Keep generated assets and OpenGame prototypes outside the shipping app until curated, reviewed, and translated into SwiftUI/vector/asset-catalog decisions.
- Design/prototype output must serve the running loop: watch readability, phone workout clarity, GPS path expression, companion identity, and post-run growth comprehension.

## Deliverables

- `AGENTS.md` with v2 rebuild constraints.
- `docs/rebuild-plan-v2.md`.
- `docs/architecture-v2.md`.
- `docs/implementation-phases-v2.md`.
- `docs/asset-inventory-v2.md`.
- `docs/v2/` index and notes.
- `RunimalNext/` app-root placeholder.
- `Sources/RunimalDomainV2/`, `Sources/RunimalSyncV2/`, `Sources/RunimalRewardV2/`, `Sources/RunimalExportV2/` skeletons.
- `SharedUIV2/` and `Tests/RunimalV2Tests/` placeholders.
- Design workflow notes for `$imagegen`-assisted expert-level visual production and OpenGame-assisted interaction prototyping.

## Migration stance on `RunimalCore`

Do not immediately replace `RunimalCore`. v2 should initially wrap and selectively import its stable concepts:

- Keep: reward math, species/growth engines, archive canonicalizer, package codec, world content resources, tested model behavior.
- Wrap: `CompletedRunRecord`, `WorkoutSessionArchive`, `WorkoutTrackPoint`, `RunRewardSummary` into clearer v2 domain names and boundaries.
- Redesign: app-store-facing persistence orchestration, sync lifecycle, route rendering ownership, and UI state stores.
