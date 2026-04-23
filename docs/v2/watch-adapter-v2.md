# Watch Adapter V2 Boundary

`RunimalWatchAdapterV2` is the first bridge from proven v1 watch assets into the v2 domain model.

## Why this exists

`RunimalWatch/WatchRunSessionManager.swift` already performs the risky device work:

- HealthKit workout session lifecycle
- CoreLocation route capture
- cadence/pedometer sampling
- local `WorkoutSessionArchive` creation
- canonical raw/display route processing through `WorkoutArchiveCanonicalizer`
- WatchConnectivity handoff through the existing queue

The v2 rebuild should not replace that loop first. Instead, it should wrap the archived output and prove a cleaner boundary with tests.

## Current mapping

`WorkoutSessionArchive` -> `RunimalDomainV2.CompletedRunArchive`

- `archive.id` -> `CompletedRunArchive.id`
- `archive.runID` -> `CompletedRunArchive.runID`
- `elapsedTimeSeconds`, `movingTimeSeconds`, distance, pace, HR, cadence, elevation -> `RunMetricSummary`
- `effectiveRawTrackPoints` -> `RoutePath.rawPoints`
- `effectiveDisplayTrackPoints` -> `RoutePath.displayPoints`
- source device -> `createdOnDevice`
- live companion metadata remains optional and non-consuming
- v1 archive id is preserved in `previousCoreArchiveID`

If a legacy archive id is not a UUID string, the adapter maps it to a deterministic UUID and keeps the original id in `previousCoreArchiveID`.

## Non-goals for this phase

- Do not import HealthKit, CoreLocation, WatchKit, SwiftUI, or app target types.
- Do not replace `WatchRunSessionManager`.
- Do not wire v2 modules into `project.yml` app targets yet.
- Do not change WatchConnectivity transport behavior yet.

## Next safe step

Add a Phone-side adapter that accepts `CompletedRunArchive` and decides how it becomes a stored workout archive / unspent run resource in the existing phone progress store.
