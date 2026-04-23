# Run Resource Ledger V2

`RunimalRewardV2.RunResourceLedger` is the first pure storage boundary for v2's resource-first growth loop.

## Locked behavior

- A completed run archive can produce one unspent `RunResource`.
- Re-delivery of the same archive must not create duplicate resources.
- Re-delivery of an already-spent archive resource must not resurrect it as unspent.
- Spending requires a `SpendIntent` whose `archiveID` matches the resource.
- The ledger records spend intents separately from ingest so phone receipt and growth allocation stay distinct.

## Relationship to phone ingest

`RunimalPhoneAdapterV2.IngestApplication.apply(_:)` combines two pure operations:

1. insert or replace a `WorkoutSessionArchive` candidate by `runID`;
2. upsert the unspent `RunResource` candidate into `RunResourceLedger`.

This gives the app integration a tested, deterministic boundary before mutating `PhoneDashboardStore`, `PhoneProgressStore`, or `project.yml`. The first app-target pass now uses this boundary for archive receipt, and the spend boundary below for user-chosen growth actions.

## Next app integration candidate

When moving into the app target, preserve the same ordering:

1. persist/replace the archive candidate;
2. upsert the run resource ledger;
3. log audit events;
4. only later, when the user chooses a target, spend the run resource into the growth loop.

## Phone spend seam

`RunimalPhoneAdapterV2.SpendApplication.apply(_:)` is the pure companion to ingest:

1. locate the `RunResource` by archive ID;
2. create a `SpendIntent` for companion feed, egg forge, or egg incubation;
3. mark the resource spent and append the intent;
4. return audit events without importing `RunimalPhone`.

`PhoneProgressStore` uses this seam after the existing growth action succeeds. Old records with no sidecar remain valid; v2 records with an already-spent sidecar are blocked from being consumed again.

## JSON persistence contract

`RunimalRewardV2.RunResourceLedgerSnapshot` wraps the ledger with `schemaVersion` and `savedAt`. `RunimalRewardV2.RunResourceLedgerCodec` encodes it with sorted, pretty JSON and reserves `run-resource-ledger-v2.json` as the app-side sidecar filename.
