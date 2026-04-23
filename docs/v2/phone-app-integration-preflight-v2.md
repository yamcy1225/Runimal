# Phone App Integration Preflight V2

This note defines the next safe app-target wiring step without changing `RunimalPhone` or `project.yml` yet.

## Current tested SwiftPM boundary

The v2 phone ingest path now has three tested pieces:

1. `RunimalPhoneAdapterV2.ingestPlan(for:)`
   - converts `CompletedRunArchive` into a `WorkoutSessionArchive` persistence candidate;
   - creates an unspent `RunResource` candidate;
   - reports insert/replace disposition and audit notes.
2. `RunimalPhoneAdapterV2.IngestApplication.apply(_:)`
   - inserts/replaces the archive candidate by `runID`;
   - upserts the resource into `RunResourceLedger`;
   - preserves spent resources on duplicate sync.
3. `RunimalRewardV2.RunResourceLedgerCodec`
   - encodes/decodes `RunResourceLedgerSnapshot` as deterministic JSON;
   - reserves `run-resource-ledger-v2.json` as the new phone-side resource ledger file.

## Proposed phone storage mapping

Keep existing files intact:

- `workout-archives.json` remains the archive persistence file.
- `completed-runs.json` remains the current completed-run/growth-facing file.

Add one new sidecar file when app wiring begins:

- `run-resource-ledger-v2.json`
  - schema: `RunResourceLedgerSnapshot`
  - contents: unspent/spent `RunResource` values + `SpendIntent` history
  - lifecycle: written after archive ingest succeeds

## App-target wiring order

When the app target is intentionally modified, use this order:

1. Add `RunimalPhoneAdapterV2` and `RunimalRewardV2` to the relevant app target dependency flow in `project.yml` only if XcodeGen supports the local SwiftPM product wiring cleanly.
2. Run `xcodegen generate`.
3. Add a small phone-side persistence wrapper that reads/writes `run-resource-ledger-v2.json` beside existing phone persistence files.
4. In the existing workout archive ingest path, build an `IngestPlan`, apply it to the archive list + ledger, persist archives, then persist the ledger.
5. Do **not** create `CompletedRunRecord` or spend resources during receipt. Spending remains a separate user-intent action.
6. Run SwiftPM tests and `xcodebuild` for `RunimalPhone`.

## Guardrails

- Do not replace `PhoneWorkoutArchivePersistence` in the first app wiring pass.
- Do not migrate `completed-runs.json` in the first app wiring pass.
- Do not introduce SwiftData/CoreData for the ledger until JSON sidecar persistence proves the loop.
- If XcodeGen product wiring is noisy, stop at a thin app-local wrapper and keep the SwiftPM modules as the source of truth until the build is stable.

## Implemented first wiring pass

The first app-target pass now keeps the existing `WorkoutSessionArchive` payload intact and only adds the v2 resource sidecar:

1. `RunimalPhone` depends on `RunimalPhoneAdapterV2` and `RunimalRewardV2`.
2. `PhoneRunResourceLedgerPersistence` reads/writes `run-resource-ledger-v2.json` beside existing phone support files.
3. `PhoneProgressStore` loads/saves `RunResourceLedger` with the rest of progress.
4. `PhoneDashboardStore.ingestLatestWorkoutArchive()` applies a core-archive ingest plan, preserving the existing archive `runID` while upserting the v2 unspent resource.
5. `PhoneProgressStore` prunes unspent resource sidecars when their source workout archives are deleted or cleared as imported external runs.

This pass intentionally still does not create a `CompletedRunRecord` or spend a resource during workout receipt.

## Delete/clear integrity rule

The v2 sidecar is tied to the source archive, not to the current growth record. When a run/archive is removed before the player spends its resource, the unspent `RunResource` must be removed too. Spent resources are preserved for now so future reward audit/history work cannot accidentally erase spend intent evidence.
