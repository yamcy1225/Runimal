# Runimal v2 Architecture Draft

## Architecture principle

Runimal v2 should be organized around a reliable workout archive pipeline, not around visual panels. The app may keep the emotional companion layer, but the system spine must be:

`Watch recording -> watch-local archive -> durable sync envelope -> phone canonical archive -> unassigned run resource -> manual growth/export`

## Proposed responsibility split

### RunimalDomainV2

Owns product-neutral running domain concepts.

Responsibilities:

- Run identity and lifecycle state.
- Recorded metric samples: timestamp, coordinate, accuracy, speed, heart rate, cadence, altitude.
- Derived summaries: distance, elapsed time, moving time, current pace, average pace, average heart rate, average cadence, elevation gain.
- GPS path rendering model independent of map tiles.
- Archive envelope and schema-version policy.
- Conversion policy to/from existing `WorkoutSessionArchive` and `CompletedRunRecord`.

Initial stance:

- Wrap existing `WorkoutSessionArchive` concepts rather than deleting them.
- Use v2 naming to make the product loop legible.

### RunimalSyncV2

Owns transport-independent sync contracts.

Responsibilities:

- Watch outbound queue model.
- Delivery state: pending, transferring, acknowledged, failed retryable, failed terminal.
- Sync audit events.
- Archive package envelope metadata.
- Phone-side ingest boundary.
- WatchConnectivity adapter as implementation detail.

Initial stance:

- Keep current `WatchConnectivityManager` and `PhoneConnectivityManager` as reference implementations.
- Extract the desired durable queue semantics before modifying those managers.

### RunimalRewardV2

Owns post-run growth resource rules.

Responsibilities:

- Convert canonical workout records into run-resource candidates.
- Preserve manual spending: feed companion, incubate egg, forge egg.
- Preserve live companion potential as a bonus, not ownership lock.
- Delegate detailed balance to existing `RunimalCore` engines until v2 tests prove replacements.

Initial stance:

- Keep existing reward/growth engines in `RunimalCore`.
- Add a thinner v2 facade that prevents UI stores from coupling directly to every engine.

### RunimalExportV2

Owns import/export and external-record interoperability.

Responsibilities:

- FIT import adapter boundary.
- FIT/JSON export adapter boundary.
- HealthKit imported-run normalization.
- Diagnostics for route/sample loss and metric availability.

Initial stance:

- Preserve `PhoneFITImportManager`, `PhoneFITExportWriter`, `PhoneWorkoutExportManager`, and core export writers.
- Move them behind a v2 export/import boundary later.

### SharedUIV2

Owns v2 reusable UI surfaces.

Responsibilities:

- Watch-readable metric tiles.
- GPS path drawing preview components.
- Phone workout list/detail primitives.
- Companion reaction components that do not own workout persistence.

Initial stance:

- Reuse visual atoms from `SharedUI` where they are simple and stable.
- Avoid carrying over offline-map-heavy UI into the first v2 loop.

### RunimalDesignV2

Owns expert-level visual direction and asset-candidate production. This can start as documentation and asset folders before becoming code.

Responsibilities:

- Define v2 visual principles for running-first usability, premium companion identity, route-result expression, and App Store presentation.
- Use `$imagegen` to create original moodboards, app-icon studies, companion silhouettes, route/result-card art references, onboarding/key-art explorations, and marketing frames.
- Curate generated bitmap assets before adoption; no generated image should enter production without accessibility, readability, brand-fit, and implementation-cost review.
- Translate accepted visual direction into SwiftUI components, vector assets, asset catalog entries, or design tokens.
- Keep prompt logs and acceptance/rejection rationale for any generated visual candidate.

Initial stance:

- `$imagegen` is a design accelerator, not a replacement for product judgment.
- In-run Watch screens remain metric-first and legible; generated art belongs mainly to identity, companion, post-run, onboarding, icon, and marketing surfaces.

### RunimalPrototypeLabV2

Owns non-shipping interaction prototypes and game-loop experiments.

Responsibilities:

- Use OpenGame externally to prototype reward loops, companion reaction concepts, post-run result cards, simple growth interactions, and onboarding/game-feel experiments.
- Export findings as short design notes, screenshots, videos, or SwiftUI translation tasks rather than importing web prototype code into Runimal.
- Keep OpenGame output out of `RunimalPhone`, `RunimalWatch`, `RunimalMac`, `SharedUI`, `Sources`, and `project.yml` unless a later plan explicitly migrates a proven idea.

Initial stance:

- OpenGame is a reference/prototype accelerator, not a production dependency.
- Prototype success means clearer product decisions, not reusable code by default.

### Phone app boundary

Responsibilities:

- Archive inbox and workout record list/detail.
- Manual growth spend flows.
- FIT import/export UI.
- Watch sync status and audit visibility.
- Optional companion/game pages after recording is reliable.

Current reference assets:

- `PhoneConnectivityManager.swift`
- `PhoneDashboardStore+WorkoutArchive.swift`
- `PhoneDashboardStore+RunActions.swift`
- `PhoneWorkoutArchivePersistence.swift`
- `PhoneRunDeckView.swift`
- `PhoneRunRecordDetailSheet.swift`

### Watch app boundary

Responsibilities:

- HealthKit authorization.
- Start/end outdoor running workout.
- Capture GPS path, route samples, heart rate, cadence, elevation, pace.
- Save every completed workout locally before sync.
- Queue sync envelopes without depending on phone availability.
- Display only high-value in-run metrics and live companion reactions.

Current reference assets:

- `WatchRunSessionManager.swift`
- `WatchConnectivityManager.swift`
- `WatchRunStatsPanel.swift`
- `WatchRunPulseCard.swift`
- `WatchLaunchPageCard.swift`

### Tooling / macOS boundary

Responsibilities:

- Balance lab.
- QA replay.
- Device checklist.
- Content catalog/authoring.
- Simulation and self-check runners.

Current reference assets:

- `RunimalMac/`
- `Sources/RunimalCLI/`
- `Sources/RunimalSelfCheck/`
- `Sources/RunimalRewardSimulation/`
- `Tests/RunimalCoreTests/`

## Data flow draft

1. Watch starts a v2 recording session.
2. Watch collects metric samples and path samples.
3. On finish, watch writes a local archive envelope first.
4. Watch derives a compact completed-run resource for immediate UI/reward feedback.
5. Watch queues the full archive envelope plus package parts for phone sync.
6. Phone receives envelope/package parts and canonicalizes them once complete.
7. Phone stores the archive and exposes an unassigned run resource.
8. User manually spends the run resource on companion growth, egg forging, or incubation.
9. Export/import adapters transform external records into the same unassigned resource path.

## Boundary decisions

- `RunimalCore` is not deleted. v2 wraps it first.
- `RunimalDomainV2` owns names and invariants for the recording loop.
- `RunimalSyncV2` owns sync semantics; WatchConnectivity remains an adapter.
- `RunimalRewardV2` owns manual-spend policy; existing engines remain calculation backends.
- `RunimalExportV2` owns FIT/HealthKit interoperability boundaries.
- `RunimalDesignV2` owns expert-level art direction and `$imagegen` candidate generation, while production UI remains SwiftUI/accessibility driven.
- `RunimalPrototypeLabV2` owns OpenGame-assisted game-loop and interaction prototypes as external references, not app dependencies.
- Offline map code is not part of the first v2 critical path.

## Target integration plan

Do not add v2 source folders to `project.yml` or `Package.swift` in this first skeleton pass. The next integration step should choose one small compile surface:

1. Add `RunimalDomainV2` as a SwiftPM library target.
2. Add `RunimalV2Tests` as a SwiftPM test target.
3. Add pure domain tests only.
4. Only after green tests, decide whether Phone/Watch app targets import `RunimalDomainV2`.
