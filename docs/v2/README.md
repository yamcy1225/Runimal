# Runimal v2 Notes

This directory indexes rebuild-specific notes. The canonical v2 documents currently live at:

- `../rebuild-plan-v2.md`
- `../architecture-v2.md`
- `../implementation-phases-v2.md`
- `../asset-inventory-v2.md`

The first v2 lane is intentionally non-destructive: define new boundaries beside v1, then integrate only after tests prove the recording/sync/resource loop.

Additional v2 notes:

- `design-prototype-track.md` — `$imagegen` and OpenGame guardrails for expert design/prototype work.
- `design-briefs-v2.md` — first expert-level `$imagegen` prompt briefs and OpenGame prototype briefs.
- `watch-adapter-v2.md` — tested boundary from v1 `WorkoutSessionArchive` to v2 `CompletedRunArchive` / sync envelope.
- `phone-ingest-adapter-v2.md` — tested boundary from v2 `CompletedRunArchive` to phone persistence candidate + unspent run resource.
- `resource-ledger-v2.md` — tested unspent/spent run-resource ledger and phone ingest application ordering.
