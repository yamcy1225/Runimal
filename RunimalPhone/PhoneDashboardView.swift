import Observation
import RunimalCore
import SwiftUI

@Observable
@MainActor
final class PhoneDashboardStore {
    let healthKit = PhoneHealthKitManager()
    let fitImport = PhoneFITImportManager()
    let connectivity = PhoneConnectivityManager()
    let offlineMaps = PhoneOfflineMapPackManager()
    let planner = PhoneWorkoutPlanner()
    let progress = PhoneProgressStore()
    let vault = PhoneVaultSyncManager()
    let cloudMirror = PhoneCloudMirrorManager()
    let contentCatalog = PhoneContentCatalog()
    let telemetry = PhoneTelemetryLogger()
    var latestFeedOutcome: CompanionFeedOutcome?

    let summary = RunSummary(
        distanceKm: 10.02,
        averagePaceSeconds: 318,
        cadence: 174,
        elevationGainM: 0,
        variability: 0.06,
        aura: .day,
        shape: .outAndBack
    )

    let runArchive: [RunSummary] = [
        RunSummary(distanceKm: 10.02, averagePaceSeconds: 318, cadence: 174, elevationGainM: 0, variability: 0.06, aura: .day, shape: .outAndBack),
        RunSummary(distanceKm: 6.4, averagePaceSeconds: 344, cadence: 168, elevationGainM: 132, variability: 0.11, aura: .dawn, shape: .loop),
        RunSummary(distanceKm: 3.8, averagePaceSeconds: 298, cadence: 176, elevationGainM: 18, variability: 0.18, aura: .night, shape: .maze),
        RunSummary(distanceKm: 8.1, averagePaceSeconds: 332, cadence: 171, elevationGainM: 42, variability: 0.08, aura: .dusk, shape: .loop),
    ]

    var claimedWeeklyRewardIDs: Set<String> {
        Set(progress.claimedWeeklyRewards)
    }

    var activeWeeklyEffects: [WeeklyRewardEffect] {
        RunimalGameEngine.activeWeeklyEffects(from: claimedWeeklyRewardIDs)
    }

    var pet: GeneratedPet {
        featuredCompanion.pet
    }

    var mainAccentColor: Color {
        mainEgg?.shell.accentColor ?? featuredCompanion.pet.accentColor
    }

    var quests: [RunQuestStatus] {
        RunimalGameEngine.evaluateRunQuests(for: summary, claimedRewardIDs: claimedWeeklyRewardIDs)
    }

    var suggestedWorkout: WorkoutPlanSuggestion {
        RunimalGameEngine.suggestWorkoutPlan(for: featuredCompanion.pet)
    }

    var collection: [PetCollectionEntry] {
        progress.ownedCompanions.map { companion in
            RunimalCompanionGrowthEngine.effectiveCompanion(
                from: companion,
                growthRecord: progress.growthRecord(for: companion.id)
            )
        }
        .filter { !progress.retiredCompanionIDs.contains($0.id) }
    }

    var featuredCompanion: PetCollectionEntry {
        if let activeCompanionID = progress.activeCompanionID,
           let activeCompanion = collection.first(where: { $0.id == activeCompanionID }) {
            return activeCompanion
        }

        return collection.first ?? PetCollectionEntry(
            id: "fallback",
            pet: RunimalGameEngine.generatePet(from: summary, claimedRewardIDs: claimedWeeklyRewardIDs),
            level: 1,
            bond: 20,
            totalDistanceKm: summary.distanceKm,
            headline: "starter companion"
        )
    }

    var variantCodex: [VariantCodexEntry] {
        RunimalGameEngine.buildVariantCodex(from: collection)
    }

    var eggInventory: [EggInventoryEntry] {
        progress.eggInventory
    }

    var mainSelection: MainCompanionSelection? {
        progress.mainCompanionSelection
    }

    var mainEgg: EggInventoryEntry? {
        progress.mainEggSelection
    }

    var mainEggResonance: Double {
        guard let egg = mainEgg else { return 0.24 }
        let bpm = latestCompletedRun?.averageHeartRate ?? Double(summary.cadence) * 0.78
        let bpmRatio = min(max((bpm - 95) / 75, 0.16), 1)
        return min(max((egg.progressRatio * 0.58) + (bpmRatio * 0.42), 0.18), 1)
    }

    var mainSelectionLabel: String {
        switch mainSelection?.kind {
        case .egg:
            return mainEgg?.title ?? "???"
        case .pet:
            return featuredCompanion.pet.displayName
        case nil:
            return featuredCompanion.pet.displayName
        }
    }

    var mainSelectionDetail: String {
        switch mainSelection?.kind {
        case .egg:
            guard let mainEgg else { return "새 알을 메인으로 들고 다니는 중" }
            return mainEgg.readyToHatch
                ? "디코딩 안정화 완료. 실체화 시퀀스를 시작할 수 있습니다."
                : mainEgg.shell.hatchHint
        case .pet:
            return featuredCompanion.headline
        case nil:
            return featuredCompanion.headline
        }
    }

    var evolutionProgress: EvolutionProgress {
        RunimalCompanionGrowthEngine.evolutionProgress(
            for: progress.growthRecord(for: featuredCompanion.id)
        )
    }

    var recentJournal: [RunJournalEntry] {
        progress.journal
    }

    var completedRuns: [CompletedRunRecord] {
        progress.completedRuns
    }

    var latestCompletedRun: CompletedRunRecord? {
        progress.completedRuns.first
    }

    var sanctuaryReward: SanctuaryRewardEvent? {
        progress.lastSanctuaryReward
    }

    var weeklyBoard: WeeklyBoard {
        RunimalGameEngine.weeklyBoard(
            from: progress.completedRuns,
            journal: progress.journal,
            codex: variantCodex
        )
    }

    var seasonEconomyBoard: SeasonEconomyBoard {
        RunimalSeasonEconomyEngine.board(
            for: weeklyBoard.season,
            collection: collection,
            claimedSeasonIDs: Set(progress.claimedSeasonRewardIDs)
        )
    }

    var claimableWeeklyReward: WeeklyReward? {
        weeklyBoard.rewards.first {
            weeklyBoard.completedMissionCount >= $0.unlockRequirement &&
            !claimedWeeklyRewardIDs.contains($0.id)
        }
    }

    var hatchInsights: [HatchInsight] {
        guard let latestCompletedRun else { return [] }
        return RunimalGameEngine.hatchInsights(for: latestCompletedRun)
    }

    var evolutionTarget: EvolutionTarget {
        RunimalGameEngine.evolutionTarget(for: evolutionProgress, recentRun: latestCompletedRun)
    }

    var availableRunCores: [CompletedRunRecord] {
        progress.unassignedRuns(from: completedRuns)
    }

    var importedRunArchive: [CompletedRunRecord] {
        completedRuns.filter {
            $0.source.hasPrefix("healthkit:") || $0.source.hasPrefix("fit:")
        }
    }

    var runimalRunArchive: [CompletedRunRecord] {
        completedRuns.filter {
            $0.source == "watch-healthkit" || $0.source == "watch-demo"
        }
    }

    var latestWatchSyncedRun: CompletedRunRecord? {
        guard let record = connectivity.lastCompletedRun else { return nil }
        guard record.source == "watch-healthkit" || record.source == "watch-demo" else { return nil }
        return record
    }

    var latestWatchSyncDiagnostic: WatchRunSyncDiagnostic? {
        guard let inbound = latestWatchSyncedRun else { return nil }
        guard let persisted = completedRuns.first(where: { $0.id == inbound.id }) else { return nil }
        return WatchRunSyncDiagnostic(inbound: inbound, persisted: persisted)
    }

    var offlineMapPacks: [OfflineMapPackSummary] {
        offlineMaps.packs
    }

    var watchOfflineMapPacks: [OfflineMapPackSummary] {
        connectivity.watchOfflineMapPacks
    }

    var selectedOfflineMapPackID: String? {
        offlineMaps.selectedPackID
    }

    var selectedOfflineMapPack: OfflineMapPackSummary? {
        guard let selectedOfflineMapPackID else { return offlineMapPacks.first }
        return offlineMapPacks.first(where: { $0.id == selectedOfflineMapPackID }) ?? offlineMapPacks.first
    }

    var autoPauseEnabled: Bool {
        progress.autoPauseEnabled
    }

    func canUseRunCore(_ run: CompletedRunRecord) -> Bool {
        availableRunCores.contains(where: { $0.id == run.id })
    }

    func eggOpportunity(for run: CompletedRunRecord) -> EggCreationOpportunity {
        progress.eggOpportunity(for: run)
    }

    var retirableOffers: [RetirableCompanionOffer] {
        RunimalCollectionEconomyEngine.retirableOffers(
            from: collection,
            activeCompanionID: featuredCompanion.id
        )
    }

    var essenceBalance: Int {
        progress.essenceBalance
    }

    var forgeInventory: ForgeInventory {
        progress.forgeInventory
    }

    var forgeOptions: [EssenceForgeOption] {
        RunimalEssenceForgeEngine.options(for: featuredCompanion, season: weeklyBoard.season)
    }

    var buildState: CompanionBuildState? {
        progress.buildState(for: featuredCompanion.id)
    }

    var selectedRole: CompanionRole {
        buildState?.selectedRole ?? RunimalCompanionBuildEngine.recommendedRoles(for: featuredCompanion.pet).first ?? .relay
    }

    var buildRoles: [CompanionRole] {
        RunimalCompanionBuildEngine.recommendedRoles(for: featuredCompanion.pet)
    }

    var buildNodes: [CompanionSkillNode] {
        RunimalCompanionBuildEngine.skillTree(
            for: buildState ?? CompanionBuildState(
                companionID: featuredCompanion.id,
                selectedRole: selectedRole,
                unlockedNodeIDs: []
            )
        )
    }

    var challengeTrials: [ChallengeTrial] {
        RunimalChallengeMetaEngine.trials(
            for: featuredCompanion,
            progress: evolutionProgress,
            selectedRole: selectedRole
        )
    }

    var starterLoop: [StarterLoopStep] {
        let hasStageAdvance = progress.growthRecords.contains {
            RunimalCompanionGrowthEngine.evolutionProgress(for: $0).stageLabel != "Trace Egg"
        }

        return RunimalOnboardingEngine.starterLoop(
            completedRuns: completedRuns,
            collection: collection,
            eggInventory: eggInventory,
            hasStageAdvance: hasStageAdvance
        )
    }

    var contentRotation: [ContentRotationEntry] {
        contentCatalog.rotationEntries(for: weeklyBoard.season) ??
        RunimalContentRotationEngine.entries(for: weeklyBoard.season)
    }

    var raidEncounters: [RaidEncounter] {
        let generated = RunimalRaidBoardEngine.encounters(
            for: featuredCompanion,
            progress: evolutionProgress,
            selectedRole: selectedRole
        )
        return contentCatalog.mergeRaids(generated)
    }

    var claimedRaidRewardIDs: Set<String> {
        Set(progress.claimedRaidRewardIDs)
    }

    var raidShardBalance: Int {
        progress.raidShardBalance
    }

    var lastRaidResolution: RaidResolution? {
        progress.lastRaidResolution
    }

    var cloudValidationStates: [CloudValidationState] {
        RunimalCloudValidationEngine.checklist(
            hasIdentity: cloudMirror.hasIdentity,
            mirrorStatus: cloudMirror.statusLabel,
            lastMirroredAt: cloudMirror.lastMirroredAt
        )
    }

    var conflictReport: SnapshotConflictReport {
        RunimalSnapshotConflictEngine.report(
            local: vault.loadSnapshot(),
            cloud: cloudMirror.restoreIfAvailable()
        )
    }

    var selectedConflictPolicy: SnapshotConflictPolicy {
        progress.conflictPolicy
    }

    var selectedDuplicatePriority: SnapshotDuplicatePriority {
        progress.duplicatePriority
    }

    var primaryRaidEncounter: RaidEncounter? {
        raidEncounters.first
    }

    var raidCombatReport: RaidCombatReport? {
        guard let primaryRaidEncounter else { return nil }
        return RunimalRaidCombatEngine.report(
            encounter: primaryRaidEncounter,
            companion: featuredCompanion,
            progress: evolutionProgress,
            selectedRole: selectedRole
        )
    }

    var cloudRehearsalSteps: [CloudRehearsalStep] {
        RunimalCloudRehearsalEngine.steps(
            hasIdentity: cloudMirror.hasIdentity,
            mirrorStatus: cloudMirror.statusLabel,
            hasConflict: conflictReport.hasConflict
        )
    }

    var conflictDiffEntries: [SnapshotConflictDiffEntry] {
        RunimalSnapshotConflictDiffEngine.entries(
            local: vault.loadSnapshot(),
            cloud: cloudMirror.restoreIfAvailable()
        )
    }

    var raidBossPatterns: [RaidBossPattern] {
        guard let primaryRaidEncounter else { return [] }
        return RunimalRaidBossPatternEngine.patterns(for: primaryRaidEncounter, season: weeklyBoard.season)
    }

    var raidTurnResults: [RaidTurnResult] {
        guard let raidCombatReport else { return [] }
        return RunimalRaidBossPatternEngine.turnResults(for: raidCombatReport)
    }

    var verificationRecords: [DeviceVerificationRecord] {
        progress.verificationRecords
    }

    var selectiveMergeCandidates: [MergeCandidate] {
        RunimalSelectiveMergeEngine.candidates(
            local: vault.loadSnapshot(),
            cloud: cloudMirror.restoreIfAvailable()
        )
    }

    var recordDiffChoices: [RecordDiffChoice] {
        RunimalRecordDiffEngine.choices(
            local: vault.loadSnapshot(),
            cloud: cloudMirror.restoreIfAvailable()
        )
    }

    var seasonalRaidBranchReward: RaidBranchReward? {
        guard let primaryRaidEncounter else { return nil }
        return RunimalSeasonalRaidBranchEngine.reward(for: primaryRaidEncounter, season: weeklyBoard.season)
    }

    var seasonalUnlocks: [SeasonalUnlock] {
        RunimalSeasonalUnlockEngine.unlocks(
            season: weeklyBoard.season,
            claimedSeasonIDs: progress.claimedSeasonRewardIDs,
            claimedRaidIDs: progress.claimedRaidRewardIDs
        )
    }

    var seasonalLayers: [SeasonalVisualLayer] {
        RunimalSeasonalCosmeticEngine.layers(
            seasonID: weeklyBoard.season.title.lowercased(),
            claimedSeasonIDs: progress.claimedSeasonRewardIDs,
            claimedRaidIDs: progress.claimedRaidRewardIDs
        )
    }

    func activateConnectivity() {
        connectivity.activate()
        syncCompanionEffects()
        connectivity.pushAutoPauseEnabled(progress.autoPauseEnabled)
        connectivity.pushOfflineMapPackCatalog(offlineMaps.packs)
        connectivity.pushSelectedOfflineMapPackID(offlineMaps.selectedPackID)
    }

    func bootstrap() {
        progress.load()
        offlineMaps.load()
        let vaultSnapshot = vault.loadSnapshot()
        let cloudSnapshot = cloudMirror.restoreIfAvailable()

        if let vaultSnapshot, let cloudSnapshot {
            progress.restore(from: RunimalSnapshotMergeEngine.merge(vaultSnapshot, cloudSnapshot))
        } else if let single = vaultSnapshot ?? cloudSnapshot {
            progress.restore(from: single)
        }
        progress.seedIfNeeded(from: runArchive)
        progress.evaluateSanctuaryRewardIfNeeded()
        persistVault()
        cloudMirror.validateRuntime()
        telemetry.log("bootstrap", detail: "store initialized")
    }

    func requestHealthAuthorization() async {
        await healthKit.requestAuthorization()
    }

    func syncExternalHealthKitRuns() async {
        if healthKit.authorizationStatus == "not requested" {
            await healthKit.requestAuthorization()
        }

        let imports = await healthKit.syncExternalRuns(
            claimedRewardIDs: claimedWeeklyRewardIDs,
            existingRunsByID: Dictionary(uniqueKeysWithValues: completedRuns.map { ($0.id, $0) })
        )

        guard !imports.isEmpty else { return }

        for item in imports.reversed() {
            progress.append(completedRun: item.record)
            progress.append(reward: item.reward, snapshot: item.snapshot)
            telemetry.log("external_workout_imported", detail: "\(item.sourceName) · \(item.id)")
        }

        persistVault()
    }

    func importFITRun(from url: URL) async {
        do {
            let item = try await fitImport.importFile(
                from: url,
                claimedRewardIDs: claimedWeeklyRewardIDs
            )
            progress.append(completedRun: item.record)
            progress.append(reward: item.reward, snapshot: item.snapshot)
            telemetry.log("fit_file_imported", detail: "\(item.sourceName) · \(item.id)")
            persistVault()
        } catch {
            fitImport.markImportFailed(error.localizedDescription)
        }
    }

    func clearImportedExternalRuns() {
        progress.removeImportedExternalRuns()
        healthKit.resetImportedWorkoutIDs()
        fitImport.resetImportedStatus()
        telemetry.log("external_workout_cleared", detail: "manual clear")
        persistVault()
    }

    func setAutoPauseEnabled(_ enabled: Bool) {
        progress.setAutoPauseEnabled(enabled)
        connectivity.pushAutoPauseEnabled(enabled)
        telemetry.log("auto_pause_toggled", detail: enabled ? "on" : "off")
        persistVault()
    }

    func registerOfflineMapPack(_ pack: OfflineMapPackSummary) {
        offlineMaps.prepareLocalStorage(for: pack)
        offlineMaps.selectPack(id: pack.id)
        offlineMaps.markTransferredToWatch(ids: [pack.id])
        connectivity.pushOfflineMapPackCatalog(offlineMaps.packs)
        connectivity.pushSelectedOfflineMapPackID(offlineMaps.selectedPackID)
        sendOfflineMapPackFiles(id: pack.id)
        telemetry.log("offline_map_pack_registered", detail: pack.title)
    }

    func setSelectedOfflineMapPack(id: String) {
        offlineMaps.selectPack(id: id)
        connectivity.pushSelectedOfflineMapPackID(offlineMaps.selectedPackID)
        telemetry.log("offline_map_pack_selected", detail: id)
    }

    func syncWorkoutPlan() async {
        let suggestion = await planner.syncSuggestedWorkout(for: pet)
        connectivity.pushSuggestedWorkout(suggestion)
        telemetry.log("sync_workout_plan", detail: suggestion.title)
    }

    func ingestLatestReward() {
        guard let reward = connectivity.lastReward else { return }
        let adjustedReward: RunRewardSummary

        if let snapshot = connectivity.lastSnapshot {
            adjustedReward = RunimalGameEngine.evaluateReward(for: snapshot, claimedRewardIDs: claimedWeeklyRewardIDs)
        } else {
            adjustedReward = RunimalGameEngine.applyWeeklyRewardModifiers(to: reward, claimedRewardIDs: claimedWeeklyRewardIDs)
        }

        progress.append(reward: adjustedReward, snapshot: connectivity.lastSnapshot)
        persistVault()
        logRewardPulseTelemetry(for: adjustedReward)
        telemetry.log("reward_ingested", detail: adjustedReward.coreLabel)
    }

    func ingestCompletedRun() {
        guard let record = connectivity.lastCompletedRun else { return }
        let isFirstCompletedRun = completedRuns.contains(where: { $0.source != "seeded-archive" }) == false
        progress.append(completedRun: record)
        persistVault()
        if isFirstCompletedRun {
            telemetry.log("first_run_completed", detail: record.id)
        }
        telemetry.log("completed_run_ingested", detail: record.id)
    }

    func claimWeeklyReward() {
        guard let reward = claimableWeeklyReward else { return }
        progress.claimWeeklyReward(id: reward.id)
        syncCompanionEffects()
        persistVault()
        telemetry.log("weekly_reward_claimed", detail: reward.id)
    }

    func activateCompanion(_ companionID: String) {
        progress.activateCompanion(id: companionID)
        persistVault()
        telemetry.log("activate_companion", detail: companionID)
    }

    func activateEgg(_ eggID: String) {
        progress.activateEgg(id: eggID)
        persistVault()
        telemetry.log("activate_egg", detail: eggID)
    }

    @discardableResult
    func feedActiveCompanion(with runID: String) -> CompanionFeedOutcome? {
        guard let run = completedRuns.first(where: { $0.id == runID }) else { return nil }
        let wasFirstStageUp = hasUnlockedNonTraceStage == false
        latestFeedOutcome = progress.feed(
            run: run,
            to: featuredCompanion,
            activeEffects: activeWeeklyEffects,
            season: weeklyBoard.season
        )
        persistVault()
        if let outcome = latestFeedOutcome {
            if outcome.bonusLabels.contains("Signal Lock") {
                telemetry.log("signal_lock_applied", detail: "\(run.id):\(outcome.afterProgress.stageLabel)")
            }
            if outcome.stageAdvanced, wasFirstStageUp {
                telemetry.log("first_stage_up", detail: outcome.afterProgress.stageLabel)
            }
        }
        telemetry.log("feed_companion", detail: run.id)
        return latestFeedOutcome
    }

    @discardableResult
    func forgeEgg(from runID: String) -> EggInventoryEntry? {
        guard let run = completedRuns.first(where: { $0.id == runID }) else { return nil }
        guard progress.eggOpportunity(for: run).eligible else { return nil }
        let wasFirstEgg = eggInventory.isEmpty
        let forgedEgg = progress.forgeEgg(from: run)
        persistVault()
        if let forgedEgg {
            let firstFlag = wasFirstEgg ? "first" : "repeat"
            telemetry.log("egg_created", detail: "\(forgedEgg.shell.rawValue):\(firstFlag)")
        }
        telemetry.log("forge_egg", detail: run.id)
        return forgedEgg
    }

    @discardableResult
    func incubateMainEgg(with runID: String) -> EggInventoryEntry? {
        guard let run = completedRuns.first(where: { $0.id == runID }) else { return nil }
        guard let eggBefore = mainEgg else { return nil }
        let proposedExperience = RunimalEggEngine.incubationExperienceGain(for: run, egg: eggBefore)
        let updatedEgg = progress.incubateMainEgg(with: run)
        persistVault()
        if let updatedEgg, updatedEgg.storedExperience > eggBefore.storedExperience + proposedExperience {
            telemetry.log("decode_lock_applied", detail: "\(updatedEgg.id):\(updatedEgg.shell.rawValue)")
        }
        telemetry.log("incubate_egg", detail: run.id)
        return updatedEgg
    }

    @discardableResult
    func hatchEgg(_ eggID: String) -> PetCollectionEntry? {
        let isFirstHatch = progress.ownedCompanions.contains(where: { $0.id.hasPrefix("hatched-") }) == false
        let companion = progress.hatchEgg(eggID)
        persistVault()
        if let companion {
            let hatchDetail = isFirstHatch ? "first:\(companion.pet.species.rawValue)" : companion.pet.species.rawValue
            telemetry.log("egg_hatched", detail: hatchDetail)
            if let rareVariant = companion.pet.rareVariant {
                let rareLabel = RareVariantMeta.labels[rareVariant] ?? rareVariant.rawValue
                telemetry.log("rare_variant_obtained", detail: "\(rareLabel):\(companion.pet.species.rawValue)")
            }
        }
        telemetry.log("hatch_egg", detail: eggID)
        return companion
    }

    func resetProgress() {
        progress.resetProgress(from: runArchive)
        latestFeedOutcome = nil
        persistVault()
        syncCompanionEffects()
        telemetry.log("reset_progress", detail: "seeded")
    }

    func clearFeedOutcome() {
        latestFeedOutcome = nil
    }

    func retireCompanion(_ companionID: String) {
        guard let offer = retirableOffers.first(where: { $0.companion.id == companionID }) else { return }
        _ = progress.retireCompanion(companionID, essenceReward: offer.essenceReward)
        persistVault()
        telemetry.log("retire_companion", detail: companionID)
    }

    func forgeOption(_ optionID: String) {
        guard let option = forgeOptions.first(where: { $0.id == optionID }) else { return }
        _ = progress.purchaseForgeOption(option)
        persistVault()
        telemetry.log("forge_option", detail: option.id)
    }

    func selectRole(_ role: CompanionRole) {
        progress.selectRole(role, for: featuredCompanion.id)
        persistVault()
        telemetry.log("select_role", detail: role.rawValue)
    }

    func unlockBuildNode(_ nodeID: String) {
        guard let node = buildNodes.first(where: { $0.id == nodeID }) else { return }
        _ = progress.unlockSkillNode(nodeID, for: featuredCompanion.id, cost: node.cost)
        persistVault()
        telemetry.log("unlock_build_node", detail: nodeID)
    }

    func claimSeasonReward() {
        _ = progress.claimSeasonReward(id: seasonEconomyBoard.seasonID)
        persistVault()
        telemetry.log("claim_season_reward", detail: seasonEconomyBoard.seasonID)
    }

    func claimRaidReward(_ encounterID: String) {
        guard let encounter = raidEncounters.first(where: { $0.id == encounterID }) else { return }
        _ = progress.claimRaidReward(
            id: encounter.id,
            title: encounter.title,
            readinessScore: encounter.readinessScore,
            threshold: encounter.claimThreshold,
            branchReward: seasonalRaidBranchReward
        )
        persistVault()
        telemetry.log("claim_raid_reward", detail: encounter.id)
    }

    func selectConflictPolicy(_ policy: SnapshotConflictPolicy) {
        progress.setConflictPolicy(policy)
        telemetry.log("select_conflict_policy", detail: policy.rawValue)
    }

    func applyConflictPolicy() {
        let localSnapshot = vault.loadSnapshot()
        let cloudSnapshot = cloudMirror.restoreIfAvailable()

        let resolved: RunimalProgressSnapshot?

        switch progress.conflictPolicy {
        case .merged:
            if let localSnapshot, let cloudSnapshot {
                resolved = RunimalSnapshotMergeEngine.merge(localSnapshot, cloudSnapshot, priority: progress.duplicatePriority)
            } else {
                resolved = localSnapshot ?? cloudSnapshot
            }
        case .localPreferred:
            resolved = localSnapshot ?? cloudSnapshot
        case .cloudPreferred:
            resolved = cloudSnapshot ?? localSnapshot
        }

        guard let resolved else { return }
        progress.restore(from: resolved)
        persistVault()
        telemetry.log("apply_conflict_policy", detail: progress.conflictPolicy.rawValue)
    }

    func recordVerification(_ title: String, passed: Bool) {
        progress.recordVerification(title, passed: passed)
        persistVault()
        telemetry.log("verification_recorded", detail: "\(title):\(passed)")
    }

    func selectDuplicatePriority(_ priority: SnapshotDuplicatePriority) {
        progress.setDuplicatePriority(priority)
        telemetry.log("select_duplicate_priority", detail: priority.rawValue)
    }

    func importSelectiveCandidate(_ id: String, type: String) {
        let localSnapshot = vault.loadSnapshot()
        let cloudSnapshot = cloudMirror.restoreIfAvailable()
        progress.importSelectiveCandidate(id: id, type: type, local: localSnapshot, cloud: cloudSnapshot)
        persistVault()
        telemetry.log("selective_import", detail: "\(type):\(id)")
    }

    func importAllSelectiveCandidates(_ type: String) {
        let localSnapshot = vault.loadSnapshot()
        let cloudSnapshot = cloudMirror.restoreIfAvailable()
        progress.importAllSelectiveCandidates(type: type, local: localSnapshot, cloud: cloudSnapshot)
        persistVault()
        telemetry.log("selective_import_all", detail: type)
    }

    func resolveRecordDiff(_ id: String, type: String, useCloud: Bool) {
        let localSnapshot = vault.loadSnapshot()
        let cloudSnapshot = cloudMirror.restoreIfAvailable()
        progress.resolveRecordDiff(id: id, type: type, useCloud: useCloud, local: localSnapshot, cloud: cloudSnapshot)
        persistVault()
        telemetry.log("record_diff_resolved", detail: "\(type):\(id):\(useCloud)")
    }

    func resolveAllRecordDiffs(type: String, useCloud: Bool) {
        let localSnapshot = vault.loadSnapshot()
        let cloudSnapshot = cloudMirror.restoreIfAvailable()
        progress.resolveAllRecordDiffs(type: type, useCloud: useCloud, local: localSnapshot, cloud: cloudSnapshot)
        persistVault()
        telemetry.log("record_diff_batch_resolved", detail: "\(type):\(useCloud)")
    }

    func syncCompanionEffects() {
        let context = CompanionEffectContext(
            claimedRewardIDs: Array(claimedWeeklyRewardIDs).sorted(),
            activeEffects: activeWeeklyEffects
        )
        connectivity.pushCompanionEffects(context)
    }

    private func persistVault() {
        let snapshot = progress.snapshot()
        vault.save(snapshot: snapshot)
        cloudMirror.mirror(snapshot: snapshot)
    }

    private var hasUnlockedNonTraceStage: Bool {
        progress.growthRecords.contains {
            RunimalCompanionGrowthEngine.evolutionProgress(for: $0).stageLabel != "Trace Egg"
        }
    }

    private func logRewardPulseTelemetry(for reward: RunRewardSummary) {
        guard reward.bonusLabels.isEmpty == false else { return }
        telemetry.log("reward_pulse_applied", detail: reward.bonusLabels.joined(separator: ", "))
    }
}

struct WatchRunSyncDiagnostic {
    let inbound: CompletedRunRecord
    let persisted: CompletedRunRecord

    var distanceDeltaMeters: Double {
        persisted.distanceMeters - inbound.distanceMeters
    }

    var durationDeltaSeconds: Int {
        persisted.durationSeconds - inbound.durationSeconds
    }

    var paceDeltaSeconds: Int {
        (persisted.averagePaceSeconds ?? 0) - (inbound.averagePaceSeconds ?? 0)
    }

    var averageHeartRateDelta: Double? {
        guard let inbound = inbound.averageHeartRate,
              let persisted = persisted.averageHeartRate else { return nil }
        return persisted - inbound
    }

    var cadenceDelta: Int? {
        guard let inbound = inbound.cadence,
              let persisted = persisted.cadence else { return nil }
        return persisted - inbound
    }

    var hasAnyMismatch: Bool {
        if abs(distanceDeltaMeters) >= 1 { return true }
        if durationDeltaSeconds != 0 { return true }
        if paceDeltaSeconds != 0 { return true }
        if let averageHeartRateDelta, abs(averageHeartRateDelta) >= 0.5 { return true }
        if let cadenceDelta, cadenceDelta != 0 { return true }
        return false
    }
}

struct PhoneDashboardView: View {
    @State private var store = PhoneDashboardStore()
    @State private var selectedTab = ProcessInfo.processInfo.environment["RUNIMAL_OPEN_COLLECTION_ON_LAUNCH"] == "1" ? 2 : 0
    private let pageTitles = ["동행", "러닝", "보관함"]

    var body: some View {
        VStack(spacing: 0) {
            pageHeader
            pageIndicator

            TabView(selection: $selectedTab) {
                NavigationStack {
                    PhoneHomeView(store: store)
                        .navigationBarTitleDisplayMode(.inline)
                }
                .tag(0)

                NavigationStack {
                    PhoneRunDeckView(store: store)
                        .navigationBarTitleDisplayMode(.inline)
                }
                .tag(1)

                NavigationStack {
                    PhoneCollectionView(store: store)
                        .navigationBarTitleDisplayMode(.inline)
                }
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .task {
            store.bootstrap()
            store.activateConnectivity()
        }
        .onChange(of: store.connectivity.lastReward) { _, _ in
            store.ingestLatestReward()
        }
        .onChange(of: store.connectivity.lastCompletedRun) { _, _ in
            store.ingestCompletedRun()
        }
        .onChange(of: store.connectivity.lastWorkoutArchive) { _, _ in
            store.ingestLatestWorkoutArchive()
        }
        .background(
            ZStack {
                LinearGradient(
                    colors: [GameBoyPalette.mediumLight, GameBoyPalette.lightest, GameBoyPalette.mediumLight.opacity(0.88)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                GameBoyLCDOverlay()
                    .opacity(0.7)
            }
            .ignoresSafeArea()
        )
    }

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("RUNIMAL")
                        .font(.title3.monospaced().weight(.black))
                        .tracking(1.6)
                        .foregroundStyle(GameBoyPalette.darkest)
                    Text("DIGITAL FIELD GUIDE")
                        .font(.caption2.monospaced().weight(.black))
                        .tracking(1.4)
                        .foregroundStyle(GameBoyPalette.mediumDark)
                }

                Spacer()

                RunimalSignalBadge(
                    icon: "sparkles",
                    label: store.weeklyBoard.season.title,
                    accent: store.pet.accentColor
                )
            }

            HStack(spacing: 10) {
                pagePill(title: "동행", icon: "sparkles", tag: 0)
                pagePill(title: "러닝", icon: "figure.run", tag: 1)
                pagePill(title: "보관함", icon: "shippingbox.fill", tag: 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(
            Rectangle()
                .fill(GameBoyPalette.lightest.opacity(0.92))
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(GameBoyPalette.darkest)
                        .frame(height: 2)
                }
        )
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(Array(pageTitles.enumerated()), id: \.offset) { index, title in
                VStack(spacing: 4) {
                    Rectangle()
                        .fill(selectedTab == index ? GameBoyPalette.darkest : GameBoyPalette.mediumLight)
                        .frame(width: selectedTab == index ? 28 : 10, height: 5)
                        .overlay(
                            Rectangle()
                                .stroke(GameBoyPalette.darkest, lineWidth: selectedTab == index ? 0 : 1)
                        )
                    Text(title)
                        .font(.caption2.monospaced().weight(selectedTab == index ? .black : .medium))
                        .foregroundStyle(selectedTab == index ? GameBoyPalette.darkest : GameBoyPalette.mediumDark)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    private func pagePill(title: String, icon: String, tag: Int) -> some View {
        let isActive = selectedTab == tag

        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                selectedTab = tag
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.black)
            }
            .font(.subheadline.monospaced())
            .foregroundStyle(isActive ? GameBoyPalette.lightest : GameBoyPalette.darkest)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isActive ? GameBoyPalette.mediumDark : GameBoyPalette.lightest)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(GameBoyPalette.darkest, lineWidth: 2)
            )
            .overlay(alignment: .topLeading) {
                Rectangle()
                    .fill(store.pet.accentColor.opacity(0.82))
                    .frame(width: isActive ? 14 : 9, height: 4)
                    .padding(6)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PhoneDashboardView()
}
