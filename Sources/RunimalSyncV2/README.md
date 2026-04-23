# RunimalSyncV2

Draft sync boundary for Runimal v2.

Owns transport-independent sync semantics:

- watch-local archive must exist before queueing
- sync envelopes are retryable and auditable
- phone ingest is idempotent
- WatchConnectivity is an adapter, not the domain model

Not yet declared in `Package.swift`.
