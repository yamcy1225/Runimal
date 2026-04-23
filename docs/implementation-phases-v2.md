# Runimal v2 Implementation Phases

## Phase A — documentation and skeleton

Goal: create a safe rebuild lane beside v1.

Work:

- Add rebuild guidance and docs.
- Add v2 folders without changing app target membership.
- Draft domain/sync/reward/export skeletons.

Completion criteria:

- Required v2 docs exist.
- New directories are physically separated from v1 code.
- Existing `project.yml` and `Package.swift` are not disrupted.

Verification:

- `git status --short`
- `find`/`ls` confirms skeleton.
- `swift test` if feasible.

Risks:

- Skeleton can become fake architecture. Mitigation: next phase must add compile-tested domain models.

## Phase B — asset inventory and inheritance plan

Goal: decide what to keep, wrap, isolate, or redesign.

Work:

- Maintain `docs/asset-inventory-v2.md` as the migration ledger.
- Mark archive candidates rather than deleting.
- Identify the first v2 code path: workout archive model and watch-local persistence.

Completion criteria:

- Every major top-level area has category A/B/C/D.
- Offline maps, demo assets, world docs, and tooling have a documented v2 role.

Verification:

- Inventory references actual file paths.
- No destructive changes.

Risks:

- Underestimating hidden dependencies. Mitigation: verify with search/tests before moving code.

## Phase C — common iPhone/Watch domain model

Goal: define v2's pure workout model.

Work:

- Convert draft `RunimalDomainV2` models into a SwiftPM target.
- Add tests for sample collection, metric summary, path simplification, archive envelope schema, and record-resource conversion.
- Define adapters to/from v1 `WorkoutSessionArchive` and `CompletedRunRecord`.

Completion criteria:

- `RunimalDomainV2` builds as a library target.
- `RunimalV2Tests` has green pure-domain tests.
- No Phone/Watch target integration yet.

Verification:

- `swift test --filter RunimalV2Tests` once target exists.
- Existing `swift test` remains green.

Risks:

- Premature replacement of `RunimalCore`. Mitigation: wrap v1 models first.

## Phase D — Watch recording start/end/save boundary

Goal: prove the watch can complete a run and persist a local v2 archive before sync.

Work:

- Extract an interface around `WatchRunSessionManager` lifecycle.
- Add a watch-local archive store boundary.
- Ensure `endRun()` writes local archive before sync queue operations.
- Keep HealthKit route saving as a separate side effect.

Completion criteria:

- A completed watch run produces a durable local archive envelope every time.
- Failure to reach phone does not lose the archive.
- Existing live companion reactions still work.

Verification:

- Unit tests for archive store where possible.
- Simulator/manual watch flow: start -> end -> archive exists -> queued sync state visible.
- Inspect WatchConnectivity audit events.

Risks:

- Watch storage constraints. Mitigation: compact summary + chunked raw samples; package cleanup after phone ack.

## Phase E — automatic phone sync boundary

Goal: make sync durable, observable, and retryable.

Work:

- Introduce `RunimalSyncV2` queue state.
- Preserve current WatchConnectivity transfers as adapter logic.
- Add ack/retry semantics for archive envelopes.
- Phone canonicalizes packages only once complete.

Completion criteria:

- Phone eventually ingests a watch-local archive after reconnection.
- Duplicate delivery does not duplicate run records.
- Audit trail exposes what happened.

Verification:

- Unit tests for queue state transitions.
- Manual watch offline/online scenario.
- Existing `PhoneWorkoutArchivePersistence` behavior remains compatible.

Risks:

- WatchConnectivity may deliver userInfo/file parts out of order. Mitigation: package completeness check and idempotent ingest.

## Phase F — GPS path rendering structure

Goal: make route display path-first rather than map-tile-first.

Work:

- Promote a v2 path rendering model: normalized polyline, bounds, quality flags, sample count.
- Reuse `RunimalRoutePreviewShape`/`RoutePreviewShape` ideas where suitable.
- Keep offline map/PMTiles as optional archive candidate.

Completion criteria:

- Workout detail can render route from GPS points without map tiles.
- Poor GPS/no route states have clear fallbacks.

Verification:

- Snapshot or preview tests when practical.
- Manual route sample rendering with stored archives.

Risks:

- Over-focusing on map visuals. Mitigation: metrics and path quality first.

## Phase G — workout list/detail/growth connection

Goal: make phone experience centered on reliable records.

Work:

- Rebuild workout list/detail around canonical archive + completed run resource.
- Keep manual spend actions: feed, incubate, forge.
- Preserve live companion potential as bonus metadata.

Completion criteria:

- User sees synced workouts with distance/time/pace/HR/cadence/elevation/path.
- User can spend an unassigned run resource manually.
- Live companion does not auto-own the record.

Verification:

- Unit tests for spent/unspent state.
- Manual phone flow using watch-synced and FIT-imported records.

Risks:

- Existing large `PhoneDashboardStore` remains too broad. Mitigation: introduce v2 archive store facade before UI rewrite.

## Phase H — FIT/export/simulation/self-check inheritance

Goal: keep valuable external/tooling assets without bloating the critical path.

Work:

- Wrap FIT import/export under `RunimalExportV2`.
- Keep `RunimalCLI`, `RunimalSelfCheck`, `RunimalRewardSimulation` as tooling.
- Reassign macOS target to QA/balance/content role.

Completion criteria:

- FIT import creates the same unassigned run resource type as watch runs.
- Export path works from canonical archive.
- Tooling remains documented and runnable.

Verification:

- Existing FIT import/export manual checks.
- `swift run RunimalSelfCheck`
- `swift run RunimalRewardSimulation` when needed.

Risks:

- External dependency drift (`FitDataProtocol`). Mitigation: lock behavior with tests before refactor.

## Phase I — expert design and prototype track

Goal: raise Runimal v2 visual/product quality to expert level without compromising the reliable workout loop.

Work:

- Define a v2 art-direction brief: running-first readability, premium companion identity, GPS path expression, post-run reward emotion, and App Store presentation.
- Use `$imagegen` for original visual exploration: moodboards, app icons, companion silhouettes, route/result cards, onboarding key art, and marketing frames.
- Use OpenGame externally for non-shipping interaction prototypes: reward-loop feel, companion reaction loops, post-run result card flow, and growth-resource comprehension.
- Curate generated candidates and prototypes into accepted/rejected design records with rationale.
- Translate accepted directions into implementation-ready SwiftUI components, vector/bitmap assets, design tokens, asset catalog tasks, or UX specs.
- Keep generated bitmap assets and OpenGame web prototypes out of production until reviewed for accessibility, watch readability, brand fit, copyright safety, implementation cost, and SwiftUI translation feasibility.

Completion criteria:

- A design/prototype brief exists before generating assets or web prototypes.
- Generated candidates are stored or referenced with prompt, date, purpose, and review decision.
- OpenGame prototypes produce decision artifacts, not direct app dependencies.
- At least one accepted direction maps to concrete SwiftUI/asset-catalog/UX work.
- Watch in-run screens remain metric-first and readable.

Verification:

- Visual review against the v2 product priorities.
- Accessibility/readability check for Watch and Phone surfaces.
- Prototype review: identify what should be translated, rejected, or deferred.
- Implementation feasibility review before asset adoption.

Risks:

- Generated art or prototypes may distract from workout reliability. Mitigation: keep this phase after recording/sync foundations or run it as a parallel non-blocking design track.
- Bitmap candidates may not translate cleanly into app UI. Mitigation: require a translation step into SwiftUI/vector/design tokens.
- OpenGame prototypes may create web-code bias. Mitigation: treat outputs as reference artifacts only; do not import code into Swift targets by default.
- Visuals may drift from Runimal identity. Mitigation: compare against `docs/world/current-character-design-lock.ko.md` and existing design assets before adoption.
