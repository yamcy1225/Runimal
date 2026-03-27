import Observation
import RunimalCore
import SwiftUI

@Observable
@MainActor
final class PhoneDashboardStore {
    let healthKit = PhoneHealthKitManager()
    let connectivity = PhoneConnectivityManager()
    let planner = PhoneWorkoutPlanner()
    let progress = PhoneProgressStore()
    let vault = PhoneVaultSyncManager()
    let cloudMirror = PhoneCloudMirrorManager()
    let contentCatalog = PhoneContentCatalog()
    let telemetry = PhoneTelemetryLogger()

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

    var baseCollection: [PetCollectionEntry] {
        RunimalGameEngine.buildCollection(from: runArchive)
    }

    var pet: GeneratedPet {
        featuredCompanion.pet
    }

    var quests: [RunQuestStatus] {
        RunimalGameEngine.evaluateRunQuests(for: summary, claimedRewardIDs: claimedWeeklyRewardIDs)
    }

    var suggestedWorkout: WorkoutPlanSuggestion {
        RunimalGameEngine.suggestWorkoutPlan(for: pet)
    }

    var collection: [PetCollectionEntry] {
        baseCollection.map { companion in
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
        RunimalGameEngine.buildVariantCodex(from: baseCollection)
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
        RunimalOnboardingEngine.starterLoop(
            completedRuns: completedRuns,
            collection: collection,
            activeEffects: activeWeeklyEffects
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
    }

    func bootstrap() {
        progress.load()
        let vaultSnapshot = vault.loadSnapshot()
        let cloudSnapshot = cloudMirror.restoreIfAvailable()

        if let vaultSnapshot, let cloudSnapshot {
            progress.restore(from: RunimalSnapshotMergeEngine.merge(vaultSnapshot, cloudSnapshot))
        } else if let single = vaultSnapshot ?? cloudSnapshot {
            progress.restore(from: single)
        }
        progress.seedIfNeeded(from: runArchive)
        persistVault()
        cloudMirror.validateRuntime()
        telemetry.log("bootstrap", detail: "store initialized")
    }

    func requestHealthAuthorization() async {
        await healthKit.requestAuthorization()
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
        telemetry.log("reward_ingested", detail: adjustedReward.coreLabel)
    }

    func ingestCompletedRun() {
        guard let record = connectivity.lastCompletedRun else { return }
        progress.append(completedRun: record)
        persistVault()
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

    func feedActiveCompanion(with runID: String) {
        guard let run = completedRuns.first(where: { $0.id == runID }) else { return }
        _ = progress.feed(run: run, to: featuredCompanion, activeEffects: activeWeeklyEffects, season: weeklyBoard.season)
        persistVault()
        telemetry.log("feed_companion", detail: run.id)
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
}

struct PhoneDashboardView: View {
    @State private var store = PhoneDashboardStore()
    @State private var selectedTab = ProcessInfo.processInfo.environment["RUNIMAL_OPEN_COLLECTION_ON_LAUNCH"] == "1" ? 1 : 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                PhoneHomeView(store: store)
                    .navigationTitle("Runimal")
            }
            .tag(0)
            .tabItem {
                Label("Home", systemImage: "bolt.heart")
            }

            NavigationStack {
                PhoneCollectionView(store: store)
                    .navigationTitle("Collection")
            }
            .tag(1)
            .tabItem {
                Label("Codex", systemImage: "sparkles.rectangle.stack")
            }
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
        .background(
            LinearGradient(
                colors: [.black, store.pet.accentColor.opacity(0.26), Color(.systemGroupedBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

#Preview {
    PhoneDashboardView()
}
