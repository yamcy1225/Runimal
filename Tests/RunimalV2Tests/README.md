# RunimalV2Tests

Placeholder for v2 tests.

First tests to add after `Package.swift` integration:

1. `WorkoutArchiveEnvelope` encodes/decodes with schema version.
2. Route path preserves source sample count and poor-GPS flag.
3. Run resource remains unspent and unassigned after archive creation.
4. Sync envelope state transitions are idempotent.
5. FIT/HealthKit imported records enter the same resource path.

This folder is intentionally not declared as a SwiftPM test target yet.
