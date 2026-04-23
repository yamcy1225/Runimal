# RunimalPhoneAdapterV2

Phone-side v2 ingest seam for archives that were already durably saved on Apple Watch and delivered to iPhone.

This module is deliberately SwiftPM-only for now. It does **not** import `RunimalPhone` and does not mutate app stores. Instead it returns:

- a `RunimalCore.WorkoutSessionArchive` candidate compatible with the existing phone archive persistence shape;
- an unspent `RunimalDomainV2.RunResource` candidate that keeps growth assignment separate from ingest;
- duplicate/replace disposition and audit notes for the future app wiring step.

Next integration step: wire this adapter behind the current `PhoneDashboardStore` ingest path after app-target tests define the exact persistence and growth-store calls.
