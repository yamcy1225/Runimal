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

This still does not wire into `RunimalPhone`. It gives the future app integration a tested, deterministic boundary before touching `PhoneDashboardStore`, `PhoneProgressStore`, or `project.yml`.

## Next app integration candidate

When moving into the app target, preserve the same ordering:

1. persist/replace the archive candidate;
2. upsert the run resource ledger;
3. log audit events;
4. only later, when the user chooses a target, spend the run resource into the growth loop.
