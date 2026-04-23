# Runimal v2 Asset Inventory

Legend:

- A — 반드시 유지할 자산
- B — 리팩터링 후 계승할 자산
- C — 보류/격리할 자산
- D — 과감히 재설계할 자산

## Summary

| Area | Category | v2 decision |
| --- | --- | --- |
| `README.md` | B | Keep as v1 baseline, update only with v2 index after skeleton stabilizes. |
| `project.yml` | A | XcodeGen source of truth; do not break. Add v2 target membership only in explicit integration phase. |
| `Package.swift` | A/B | Preserve existing products; later add v2 pure modules/tests deliberately. |
| `Sources/RunimalCore` | A/B | Keep tested engines and archive codecs; wrap workout/growth concepts into v2 boundaries. |
| `Tests/RunimalCoreTests` | A | Keep regression safety for existing core behavior. Add v2 tests beside, not instead. |
| `RunimalWatch` | B/D | Keep HealthKit/GPS/session lessons; redesign into smaller recording, persistence, sync, live companion boundaries. |
| `RunimalPhone` | B/D | Keep archive ingest, FIT, growth decisions; redesign broad dashboard/store coupling. |
| `RunimalMac` | B/C | Keep as QA/balance/content tooling; not primary user app. |
| `SharedUI` | B | Reuse simple visual atoms and path shapes; separate v2 UI primitives in `SharedUIV2`. |
| `docs/live-companion-and-run-core.ko.md` | A | Product rule lock: live companion != auto-owned workout record. |
| Offline map / PMTiles docs and code | C | Archive candidate; preserve but keep outside first v2 critical path. |
| `demo/` and `design/` | C/B | Preserve as marketing/design reference; only migrate assets that directly support v2. |
| `$imagegen` design capability | B | Use as a v2 expert-design accelerator for original asset candidates, not as unchecked production art. |
| OpenGame CLI/tooling | B/C | Use externally for web-game loop and interaction prototypes; do not add as a Runimal app dependency. |
| `app_store/`, release docs | C | Keep for release history; revisit once v2 product surface stabilizes. |

## A. v2에서 반드시 유지할 자산

### Xcode/build structure

- `project.yml`: declares `RunimalPhone`, `RunimalWatch`, `RunimalMac`, local `RunimalPackage`, `FitDataProtocol`, entitlements, bundle IDs, and schemes.
- `Package.swift`: keeps shared package and CLI/self-check/simulation targets.
- `RunimalPhone/RunimalPhone.entitlements`
- `RunimalWatch/RunimalWatch.entitlements`

Rationale: target identity, signing, package products, and XcodeGen flow are operational assets.

### Proven domain rules and tests

- `docs/live-companion-and-run-core.ko.md`
- `Sources/RunimalCore/WorkoutArchiveModels.swift`
- `Sources/RunimalCore/WorkoutArchiveCanonicalizer.swift`
- `Sources/RunimalCore/WorkoutSessionPackageCodec.swift`
- `Sources/RunimalCore/RunCoreGrowthBalanceEngine.swift`
- `Sources/RunimalCore/WorkoutExportWriters.swift`
- `Tests/RunimalCoreTests/WorkoutArchiveCanonicalizerTests.swift`
- `Tests/RunimalCoreTests/WorkoutSessionPackageCodecTests.swift`
- Existing growth/species/reward tests in `Tests/RunimalCoreTests/`

Rationale: these encode actual run archive, package, reward, and growth behavior. v2 should wrap first, replace only after tests.

### Watch run capability reference

- `RunimalWatch/WatchRunSessionManager.swift`: HealthKit workout session, route builder, CLLocation, pedometer cadence, live metrics, archive creation.
- `RunimalWatch/WatchConnectivityManager.swift`: queueing completed runs, summaries, archives, archive package file transfers, audit trail.

Rationale: this is the most important implementation proof for watch-only running and later sync.

## B. 리팩터링 후 계승할 자산

### Phone archive and run-resource handling

- `RunimalPhone/PhoneConnectivityManager.swift`
- `RunimalPhone/PhoneWorkoutArchivePersistence.swift`
- `RunimalPhone/PhoneDashboardStore+WorkoutArchive.swift`
- `RunimalPhone/PhoneDashboardStore+RunActions.swift`
- `RunimalPhone/PhoneRunDeckView.swift`
- `RunimalPhone/PhoneRunRecordDetailSheet.swift`
- `RunimalPhone/PhoneRunCoreDecisionPanel.swift`
- `RunimalPhone/PhoneRunCoreUsage.swift`

Keep the behavior, but split responsibilities into archive inbox, workout list/detail, growth spending, and sync audit.

### FIT / export / external workout path

- `RunimalPhone/PhoneFITImportManager.swift`
- `RunimalPhone/PhoneFITExportWriter.swift`
- `RunimalPhone/PhoneWorkoutExportManager.swift`
- `RunimalPhone/PhoneHealthKitManager.swift`
- `Sources/RunimalCore/WorkoutExportDiagnostics.swift`
- `Sources/RunimalCore/WorkoutExportWriters.swift`

Keep because external workouts already enter the same run-resource rule path. Move behind `RunimalExportV2` later.

### Shared visual/game assets

- `SharedUI/PixelPetView.swift`
- `SharedUI/GameSurface.swift`
- `SharedUI/RunimalProgressBar.swift`
- `SharedUI/RunimalRoutePreviewShape.swift`
- `SharedUI/RunimalFeedbackProfileLoader.swift`
- `SharedUI/AssetCatalog/feedback-profiles.json`

Reuse cautiously. v2 first needs readable run metrics and GPS path preview; decorative visuals are secondary.

### Tooling

- `RunimalMac/`
- `Sources/RunimalCLI/`
- `Sources/RunimalSelfCheck/`
- `Sources/RunimalRewardSimulation/`
- `docs/reward-research-and-simulation.ko.md`

Keep as operations, QA, balance, and simulation support.

## C. 보류/격리할 자산

### Offline maps / PMTiles / Protomaps

- `docs/offline-map-open-source-workflow.ko.md`
- `docs/protomaps-pmtiles-workflow.ko.md`
- `RunimalPhone/PhoneOfflineMapPackManager.swift`
- `RunimalPhone/PhoneOfflineMapPackPanel.swift`
- `RunimalPhone/PhoneOfflineMapValidationPanel.swift`
- `RunimalPhone/PhoneMBTilesMetadataReader.swift`
- `RunimalWatch/WatchOfflineMapPackCatalog.swift`
- `RunimalWatch/WatchOfflineMapPackStorage.swift`
- `RunimalWatch/WatchOfflineMapPreviewCard.swift`
- `RunimalWatch/WatchMBTilesTileReader.swift`
- `RunimalWatch/WatchPMTilesTileReader.swift`

Decision: archive candidate, not delete. v2 route display should start with GPS path drawing, bounds, quality, and workout metrics.

### Demo/design/release surfaces

- `demo/`
- `design/`
- `app_store/`
- release/TestFlight/App Store docs
- `$imagegen`-produced candidate assets and prompts, once created
- OpenGame-generated prototypes, screenshots, videos, and findings, once created

Decision: preserve as evidence and marketing/reference assets. Do not let them drive the first v2 architecture. Use `$imagegen` to raise visual quality through curated, original design candidates, and use OpenGame to quickly test game-loop/interaction ideas outside the app. Adopt only the underlying product decisions after review for readability, brand fit, accessibility, copyright safety, implementation cost, and SwiftUI feasibility.

### Extra game meta systems

- raid/combat/season/world/cosmetic panels and docs.

Decision: preserve; reattach only after recording/sync/growth-resource path is reliable.

## D. 과감히 재설계할 자산

### Broad app stores and dashboard coupling

- `PhoneDashboardStore` currently owns health, FIT, location, connectivity, offline maps, planner, progress, vault, cloud mirror, world packs, telemetry, and UI-facing computed state.
- `WatchRunSessionManager` currently mixes workout lifecycle, live companion reaction, route capture, pedometer, weather, events, haptics, mutation reaction, archive building, and demo capture.

v2 redesign:

- Introduce smaller services: recording, archive store, sync queue, workout inbox, growth spending, path rendering.
- Keep current files as reference until each boundary is tested.

### Product information hierarchy

v2 should prioritize workout reliability and readable metrics over decorative panels, raids, offline maps, and content catalog panels.

### Sync semantics

Current code already queues WatchConnectivity transfers. v2 should make the queue state explicit and durable:

- archive stored locally first
- sync envelope created
- transfer started
- phone ack received
- cleanup safe only after ack

## Open migration questions

1. Should `RunimalDomainV2` become a SwiftPM target before any app integration? Recommended: yes.
2. Should existing `WorkoutSessionArchive` be the v2 archive format? Recommended: wrap first, then migrate field names/schema if necessary.
3. Should FIT import produce full `WorkoutSessionArchive`, not just `CompletedRunRecord`? Recommended: yes in v2.
4. Should macOS read real archive fixtures? Recommended: yes as QA tooling.
5. Should offline maps be moved to an archive folder? Recommended: document as archive candidate first; move only after grep/build impact review.
