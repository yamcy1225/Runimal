# Runimal v2 Rebuild Worktree Guidance

This worktree is for rebuilding Runimal v2 by analyzing the existing Runimal assets, preserving proven value, and creating a clearer architecture for a reliable iPhone + Apple Watch running game.

## Purpose

- Treat the current repository as a working Runimal v1/v1.5 asset base, not disposable prototype code.
- Build Runimal v2 through selective inheritance: keep verified domain value, isolate exploratory assets, and create new v2 boundaries beside the existing app targets.
- The primary product loop is: Apple Watch starts a run -> records GPS/metrics locally -> saves every completed workout on watch -> automatically syncs to iPhone later -> iPhone turns unassigned workout records into growth resources.

## Non-destructive rebuild rules

- Do not overwrite existing `RunimalPhone`, `RunimalWatch`, `RunimalMac`, `SharedUI`, `Sources/RunimalCore`, or `Tests/RunimalCoreTests` implementations without an explicit migration step.
- Start v2 work in clearly separated paths such as `RunimalNext/`, `Sources/RunimalDomainV2/`, `Sources/RunimalSyncV2/`, `Sources/RunimalRewardV2/`, `Sources/RunimalExportV2/`, `SharedUIV2/`, and `Tests/RunimalV2Tests/`.
- Large deletion, broad file moves, risky renames, target removal, or `project.yml` target rewiring require an explicit warning with rationale first.
- `project.yml` is the source of truth for Xcode project generation. If v2 files become app-target sources, update `project.yml` deliberately and run `xcodegen generate`.
- `Package.swift` contains reusable verification assets (`RunimalCLI`, `RunimalSelfCheck`, `RunimalRewardSimulation`). Do not remove them during v2 work; decide whether each becomes tooling, tests, or archive.

## Product priorities

1. Workout recording reliability
2. Watch-local save stability
3. Automatic phone sync stability
4. GPS path drawing and workout-detail clarity
5. Growth loop integration
6. Secondary imports/exports/tooling
7. Decorative game/system expansion

## Architectural guardrails

- Preserve the split between `live companion` and post-run `workout/run core` resources.
- A live companion may react during a run, but a completed workout must remain an unassigned resource until the player spends it.
- Prefer GPS path rendering over map-tile-centered product decisions.
- Treat offline maps / PMTiles / Protomaps as archive candidates unless a specific v2 requirement reactivates them.
- Treat macOS as QA, balance lab, content/tooling, simulation, and release-support surface rather than the primary user app.
- Use `$imagegen` as an expert-design production tool when v2 needs original visual assets, moodboards, app-icon studies, companion silhouettes, marketing frames, or UI art direction references; do not use it for code-native UI that should be built directly in SwiftUI.
- Any generated bitmap asset must be treated as a design candidate until reviewed against Runimal's product priorities, accessibility, readability during running, and existing character/world constraints.
- Use OpenGame only as an external prototyping/reference tool for web-game loop experiments, reward UX sketches, and interaction probes. Do not add OpenGame as a Runimal app dependency or mix generated web code into Swift targets without an explicit migration plan.

## Verification expectations

- For documentation/skeleton-only changes: run a lightweight filesystem/status check and, when practical, `swift test` to confirm existing targets still build.
- For Swift target changes: run `swift test`; if app target membership changes, run `xcodegen generate` and target-specific `xcodebuild` checks where feasible.
- Every report should include changed files, simplifications made, verification evidence, and remaining risks.
