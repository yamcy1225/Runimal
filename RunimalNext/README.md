# RunimalNext

Placeholder app root for Runimal v2 exploration.

This directory is intentionally not wired into `project.yml` yet. It exists to keep v2 notes, target concepts, and future app-shell files physically separate from the current `RunimalPhone`, `RunimalWatch`, and `RunimalMac` targets.

First target-integration candidate:

1. Add pure `RunimalDomainV2` SwiftPM target.
2. Add `RunimalV2Tests`.
3. Prove archive and sync-domain behavior.
4. Create small Phone/Watch v2 surfaces only after the model is stable.
