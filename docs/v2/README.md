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
- `phone-app-integration-preflight-v2.md` — app-target wiring order and JSON sidecar storage contract before touching `RunimalPhone`.
- `runtime-resource-ledger-verification-v2.md` — simulator app-target check for sidecar creation, manual spend marking, and prune/preserve behavior.
- `resource-allocation-ui-v2.md` — first post-run resource allocation card design plan plus imagegen/OpenGame prompt boundaries.
- `design-direction-v2.md` — Runimal v2 visual hierarchy, imagegen policy, and production design quality bar.
- `imagegen-briefs-v2.md` — executable expert-level prompts for Watch HUD, iPhone route detail, resource allocation, companion growth, and app icon candidates.
- `ui-upgrade-plan-v2.md` — phased path from generated candidates to SwiftUI implementation without weakening the recording/sync/resource loop.
