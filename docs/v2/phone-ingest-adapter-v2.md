# Phone Ingest Adapter V2

`RunimalPhoneAdapterV2` is the first phone-side bridge for the selective-inheritance v2 rebuild.

## Purpose

The existing iPhone app already has useful persistence and dashboard flows:

- `PhoneWorkoutArchivePersistence` stores `WorkoutSessionArchive` arrays and completed run records.
- `PhoneDashboardStore+WorkoutArchive` canonicalizes incoming workout archives and merges them into the phone state.
- `PhoneProgressStore` stores workout archives by `runID` and keeps completed run/growth state separate.

The v2 adapter preserves those assets without wiring into the app target yet. It accepts a `RunimalDomainV2.CompletedRunArchive` and returns a pure ingest plan.

## Output contract

`RunimalPhoneAdapterV2.ingestPlan(for:options:)` returns:

1. `archiveForPersistence`: a `RunimalCore.WorkoutSessionArchive` candidate that can later be passed to the existing phone archive persistence/store path.
2. `runResource`: an unspent `RunimalDomainV2.RunResource` whose `archiveID` points to the v2 archive and whose `liveCompanionID` preserves the live companion context only as metadata.
3. `disposition`: `.insertNewArchive` or `.replaceExistingArchive` based on existing phone archive `runID`s.
4. `auditEvents`: simple codes/messages for future phone-side audit log wiring.

## Explicit non-goals in this phase

- No import of `RunimalPhone`.
- No mutation of `PhoneDashboardStore`, `PhoneProgressStore`, or persistence files.
- No automatic `CompletedRunRecord` creation.
- No automatic reward/growth spending.
- No `project.yml` or app-target wiring.

## Why this seam matters

V2’s product rule is that completed workouts become reliable, durable resources first. Growth happens later when the player spends a resource. The adapter therefore validates the boundary between:

- **record/archive ingest**: trustworthy persistence candidate;
- **growth loop**: later allocation of an unspent `RunResource`.

## Next integration step

After app-target tests are scoped, the phone app can wire this plan into the existing ingest path:

1. receive `CompletedRunArchive` from v2 sync;
2. build `RunimalPhoneAdapterV2.IngestPlan`;
3. replace/insert `archiveForPersistence` through the existing archive persistence path;
4. store the unspent `RunResource` through `RunimalRewardV2.RunResourceLedger`;
5. create `CompletedRunRecord` only at the explicitly chosen reward/growth boundary.

## Tested application seam

`RunimalPhoneAdapterV2.IngestApplication.apply(_:)` now proves the app-facing ordering without importing `RunimalPhone`: archive insert/replace first, then `RunResourceLedger` upsert. Duplicate sync replaces the archive candidate but reuses the existing resource, and duplicate sync after spending preserves the spent resource.
