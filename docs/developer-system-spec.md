# Runimal Developer System Spec

## 1. Scope

This document describes the current Runimal system from an implementation point of view.

Primary targets:

- iPhone app
- Apple Watch app
- shared Swift game core

Primary project root:

- `/Users/heobella/jaw-bot-2/apps/runimal-apple`

## 2. Architecture Overview

Runimal is split into three layers.

### 2.1 Shared Core

Location:

- `/Users/heobella/jaw-bot-2/apps/runimal-apple/Sources/RunimalCore`

Responsibilities:

- game rules
- egg creation and hatch weighting
- reward calculation
- progression and evolution math
- weekly and seasonal systems
- build, resonance, challenge, and raid logic
- snapshot merge and cloud conflict logic

This layer should remain UI-independent.

### 2.2 iPhone App Layer

Location:

- `/Users/heobella/jaw-bot-2/apps/runimal-apple/RunimalPhone`

Responsibilities:

- home base UI
- collection UI
- run reward decisions
- progress persistence
- vault/cloud mirror adapters
- phone-side connectivity ingest

### 2.3 Watch App Layer

Location:

- `/Users/heobella/jaw-bot-2/apps/runimal-apple/RunimalWatch`

Responsibilities:

- run session lifecycle
- live run feedback
- reward generation trigger
- watch-side sync payload delivery

## 3. Core Domain Objects

## 3.1 RunSummary

Purpose:

- compact rule-evaluation input
- seed archive generation
- pet generation source for non-live flows

Key fields:

- `distanceKm`
- `averagePaceSeconds`
- `cadence`
- `elevationGainM`
- `variability`
- `aura`
- `shape`

## 3.2 CompletedRunRecord

Purpose:

- durable record of a completed workout
- primary source for Run Core usage, eggs, and growth

Key fields:

- `id`
- `startedAt`
- `endedAt`
- `distanceMeters`
- `durationSeconds`
- `averageHeartRate`
- `averagePaceSeconds`
- `cadence`
- `elevationGainM`
- `reward`
- `route`
- `source`

## 3.3 GeneratedPet

Purpose:

- generated species package used by roster and reward systems

Key fields:

- `species`
- `element`
- `palette`
- `rareVariant`
- `explanation`
- `stats`

## 3.4 PetCollectionEntry

Purpose:

- roster entry shown in collection

Key fields:

- `id`
- `pet`
- `level`
- `bond`
- `totalDistanceKm`
- `headline`

## 3.5 EggInventoryEntry

Purpose:

- hidden egg inventory object

Key fields:

- `id`
- `shell`
- `title`
- `createdAt`
- `sourceRunID`
- `storedExperience`
- `hatchThreshold`
- `incubationRunIDs`
- `unlockedAchievementIDs`

Important:

- egg entries no longer store a final pet
- final pet is resolved only at hatch time

## 3.6 MainCompanionSelection

Purpose:

- single active target selector

Kinds:

- `.pet`
- `.egg`

## 4. Egg System

## 4.1 Engine

Core file:

- [RunimalEggEngine.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/Sources/RunimalCore/RunimalEggEngine.swift)

Main responsibilities:

- determine egg eligibility
- determine shell type
- determine threshold and starting XP
- compute newly unlocked achievement IDs
- compute weighted hatch result from contributing runs

## 4.2 Egg Eligibility

Method:

- `RunimalEggEngine.opportunity(...)`

An egg is eligible when:

1. the run unlocked at least one new egg achievement
2. or the roster and egg inventory were empty and this is the first successful recovery run

Current achievement-style IDs:

- `distance-5k`
- `cadence-170`
- `climb-60`
- `night-run`

These IDs are persisted so the same achievement does not repeatedly grant egg eligibility.

## 4.3 Shell Types

Enum:

- `EggShellType`

Current values:

- `ember`
- `gale`
- `moss`
- `dusk`
- `stone`

Selection heuristic:

- elevation-heavy -> stone
- aggressive pace/cadence -> ember
- night -> dusk
- long distance -> gale
- otherwise -> moss

## 4.4 Hatch Resolution

Method:

- `RunimalEggEngine.hatchPet(...)`

Inputs:

- egg
- source run + incubation runs
- claimed weekly reward IDs

Behavior:

- builds weighted species scores from shell and run pattern
- chooses a species through deterministic pseudo-random resolution
- rebuilds a `GeneratedPet` from combined summary context
- replaces species with selected weighted species

Design result:

- mostly random
- player behavior still biases outcome

## 5. Progress Persistence

Primary store:

- [PhoneProgressStore.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/RunimalPhone/PhoneProgressStore.swift)

Extension:

- [PhoneProgressStore+CompanionLoop.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/RunimalPhone/PhoneProgressStore+CompanionLoop.swift)

Persistent state includes:

- journal
- completed runs
- owned companions
- egg inventory
- unlocked egg achievement IDs
- claimed weekly rewards
- main selection
- growth records
- resource balances
- build states
- season and raid claim state
- verification and merge policy state

## 5.1 Snapshot Model

Snapshot type:

- `RunimalProgressSnapshot`

Snapshot now includes:

- `eggInventory`
- `unlockedEggAchievementIDs`
- `mainCompanionSelection`
- all major progression state

## 5.2 Reset Behavior

Reset method:

- `resetProgress(from:)`

Reset clears:

- companions
- eggs
- progression
- rewards
- resources
- diagnostics

Then reseeds baseline archive data.

## 6. Companion Loop Flow

## 6.1 Main Pet Flow

When the main selection is a pet:

- `PhoneRunCoreDecisionPanel` allows `메인 펫 성장`
- `PhoneProgressStore.feed(...)` applies XP and bonuses

## 6.2 Main Egg Flow

When the main selection is an egg:

- `PhoneRunCoreDecisionPanel` allows `메인 알 키우기`
- `incubateMainEgg(with:)` adds XP and run ownership

## 6.3 Egg Creation Flow

Method:

- `forgeEgg(from:)`

Rules:

- run must be unassigned
- egg opportunity must be eligible
- unlocked achievement IDs get persisted

## 6.4 Hatch Flow

Method:

- `hatchEgg(_:)`

Effects:

- final pet generated at hatch time
- companion inserted into roster
- egg removed
- source/incubation run IDs move into growth ownership
- new companion becomes active main pet

## 7. Reward Decision UI

Primary files:

- [PhoneRunCoreDecisionPanel.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/RunimalPhone/PhoneRunCoreDecisionPanel.swift)
- [PhoneCollectionView.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/RunimalPhone/PhoneCollectionView.swift)

Current behavior:

- each available run core is presented
- egg creation is conditionally shown
- ineligible runs show locked state and explanation
- feed/incubate actions depend on current main slot kind

## 8. UI Representation Rules

## 8.1 Egg UI

Eggs should display:

- `???`
- shell label
- progress bar
- shell hint
- readiness

Eggs should not display:

- exact species
- final hatch result

Key files:

- [PhoneCompanionRosterPanel.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/RunimalPhone/PhoneCompanionRosterPanel.swift)
- [PhoneCollectionView.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/RunimalPhone/PhoneCollectionView.swift)
- [PhoneHomeView.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/RunimalPhone/PhoneHomeView.swift)
- [EggShellStyle.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/SharedUI/EggShellStyle.swift)

## 8.2 Reset Safety

Reset action is intentionally dangerous and must remain hard to mis-tap.

Current behavior:

- located at bottom of collection page
- inside a dedicated danger zone section
- hidden behind a collapsed reveal step
- followed by an alert confirmation

Key file:

- [PhoneCollectionView.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/RunimalPhone/PhoneCollectionView.swift)

## 9. Weekly And Seasonal Systems

Weekly board logic:

- mission completion
- weekly reward claim
- active effect extraction

Seasonal systems currently connect to:

- visual layers
- season rewards
- economy
- raid branch bonuses

Important file groups:

- weekly/meta: `/Sources/RunimalCore/MetaLoop*`
- season economy: `/Sources/RunimalCore/SeasonEconomyEngine.swift`
- seasonal visuals/unlocks: `/Sources/RunimalCore/Seasonal*`

## 10. Resource Economy

Tracked values in `PhoneProgressStore`:

- `essenceBalance`
- `overdriveCharges`
- `seasonSigils`
- `raidShardBalance`

These are modified by:

- retirement
- forging
- season rewards
- raid rewards
- branch rewards

## 11. Build And Role System

Companion build state:

- selected role
- unlocked node IDs

This system is kept separate from base pet generation.

Core files:

- [CompanionBuildEngine.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/Sources/RunimalCore/CompanionBuildEngine.swift)
- [PhoneBuildTreePanel.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/RunimalPhone/PhoneBuildTreePanel.swift)

## 12. Sync And Cloud

Primary persistence layers:

- local defaults
- vault snapshot
- optional cloud mirror

Core related files:

- [PhoneVaultSyncManager.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/RunimalPhone/PhoneVaultSyncManager.swift)
- [PhoneCloudMirrorManager.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/RunimalPhone/PhoneCloudMirrorManager.swift)
- [SnapshotMergeEngine.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/Sources/RunimalCore/SnapshotMergeEngine.swift)

Egg achievement unlock state is now part of snapshots and merge results.

## 13. Watch Integration

Watch app responsibilities:

- run start
- run finish
- live metrics
- run reward trigger

The watch should stay lightweight and field-focused.
Most collection management remains on iPhone.

Key files:

- [WatchRunSessionManager.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/RunimalWatch/WatchRunSessionManager.swift)
- [WatchDashboardView.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/RunimalWatch/WatchDashboardView.swift)
- [WatchConnectivityManager.swift](/Users/heobella/jaw-bot-2/apps/runimal-apple/RunimalWatch/WatchConnectivityManager.swift)

## 14. Verification Notes

Recent verification flow for the current egg update:

- `xcodegen generate`
- `swift build`
- `xcodebuild -project RunimalApple.xcodeproj -scheme RunimalPhone -destination 'generic/platform=iOS' build`
- `xcodebuild -project RunimalApple.xcodeproj -scheme RunimalWatch -destination 'generic/platform=watchOS' build`
- iPhone install and launch via `devicectl`
- Watch install and launch via `devicectl`

Recent verification flow for the danger zone change:

- `xcodegen generate`
- `xcodebuild -project RunimalApple.xcodeproj -scheme RunimalPhone -destination 'generic/platform=iOS' build`
- iPhone install and launch via `devicectl`

## 15. Current Guardrails

When extending the system:

- do not reveal exact egg result before hatch
- do not make eggs drop from every run
- keep run ownership one-way and non-reusable
- keep main slot singular
- keep destructive reset protected behind multiple steps
- keep new persistence fields backward-compatible when decoding old data

## 16. Recommended Next Implementation Areas

High-value next steps:

1. real achievement catalog expansion
2. richer hatch weighting tables per shell
3. more shell-specific visuals
4. better live watch guidance for hatch probability windows
5. balancing tools for egg rarity and species distribution

