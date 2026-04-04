import Observation
import RunimalCore
import SwiftUI

@Observable
@MainActor
final class PhoneDashboardStore {
    private let emptySummary = RunSummary(
        distanceKm: 0,
        averagePaceSeconds: 0,
        cadence: 0,
        elevationGainM: 0,
        variability: 0,
        aura: .day,
        shape: .freeform
    )

    let healthKit = PhoneHealthKitManager()
    let fitImport = PhoneFITImportManager()
    let currentLocation = PhoneCurrentLocationManager()
    let connectivity = PhoneConnectivityManager()
    let offlineMaps = PhoneOfflineMapPackManager()
    let planner = PhoneWorkoutPlanner()
    let progress = PhoneProgressStore()
    let vault = PhoneVaultSyncManager()
    let cloudMirror = PhoneCloudMirrorManager()
    let worldPackManifest = PhoneWorldPackManifestManager()
    let telemetry = PhoneTelemetryLogger()
    var latestFeedOutcome: CompanionFeedOutcome?
    var activeWorldPackIDs: [String] = []

    var contentCatalog: PhoneContentCatalog {
        PhoneContentCatalog(manifest: worldPackManifest)
    }

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
        RunimalGameEngine.evaluateRunQuests(for: currentRunSummary, claimedRewardIDs: claimedWeeklyRewardIDs)
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
        if let mainCompanion = progress.mainPetSelection,
           let selectedCompanion = collection.first(where: { $0.id == mainCompanion.id }) {
            return selectedCompanion
        }

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

    var hasOwnedCompanion: Bool {
        collection.isEmpty == false
    }

    var isEggOnlyState: Bool {
        hasOwnedCompanion == false && mainSelection?.kind == .egg
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
        let bpm = latestCompletedRun?.averageHeartRate ?? 108
        let bpmRatio = min(max((bpm - 95) / 75, 0.16), 1)
        return min(max((egg.progressRatio * 0.58) + (bpmRatio * 0.42), 0.18), 1)
    }

    var currentRunSummary: RunSummary {
        guard let latestCompletedRun else { return emptySummary }
        return runSummary(from: latestCompletedRun)
    }

    var featuredCompanionDistanceKm: Double {
        guard mainSelection?.kind != .egg else { return 0 }
        return metricSummary(for: featuredCompanion)?.totalDistanceKm ?? featuredCompanion.totalDistanceKm
    }

    var featuredCompanionCadence: Int? {
        guard mainSelection?.kind != .egg else { return nil }
        return metricSummary(for: featuredCompanion)?.averageCadence ?? latestCompletedRun?.cadence
    }

    var featuredCompanionSignalLabel: String {
        if mainSelection?.kind == .egg {
            return mainEgg?.shell.scanHeadline ?? "SCAN ACTIVE"
        }

        let totalDistanceKm = featuredCompanionDistanceKm
        if totalDistanceKm > 0 {
            return "\(totalDistanceKm.formatted(.number.precision(.fractionLength(1))))km 누적 동행"
        }

        return featuredCompanion.headline
    }

    var mainSelectionLabel: String {
        switch mainSelection?.kind {
        case .egg:
            return mainEgg?.title ?? "???"
        case .pet:
            return featuredCompanion.pet.displayName
        case nil:
            if let mainEgg {
                return mainEgg.title
            }
            return featuredCompanion.pet.displayName
        }
    }

    var mainSelectionDetail: String {
        switch mainSelection?.kind {
        case .egg:
            guard let mainEgg else { return "새 알을 대표로 데리고 있는 중" }
            return mainEgg.readyToHatch
                ? "부화 준비가 끝났습니다. 이제 바로 꺼낼 수 있습니다."
                : mainEgg.shell.hatchHint
        case .pet:
            return featuredCompanion.headline
        case nil:
            if let mainEgg {
                return mainEgg.readyToHatch
                    ? "부화 준비가 끝났습니다. 이제 바로 꺼낼 수 있습니다."
                    : mainEgg.shell.hatchHint
            }
            return featuredCompanion.headline
        }
    }

    var evolutionProgress: EvolutionProgress {
        RunimalCompanionGrowthEngine.evolutionProgress(
            for: progress.growthRecord(for: featuredCompanion.id),
            species: featuredCompanion.pet.species
        )
    }

    var progressionSnapshot: CompanionProgressionSnapshot {
        RunimalCompanionGrowthEngine.progressionSnapshot(
            for: progress.growthRecord(for: featuredCompanion.id),
            species: featuredCompanion.pet.species
        )
    }

    var recentJournal: [RunJournalEntry] {
        progress.journal
    }

    var completedRuns: [CompletedRunRecord] {
        progress.completedRuns
    }

    var actualCompletedRuns: [CompletedRunRecord] {
        progress.completedRuns.filter { $0.source != "seeded-archive" }
    }

    var latestCompletedRun: CompletedRunRecord? {
        actualCompletedRuns.first
    }

    var sanctuaryReward: SanctuaryRewardEvent? {
        progress.lastSanctuaryReward
    }

    var weeklyBoard: WeeklyBoard {
        RunimalGameEngine.weeklyBoard(
            from: actualCompletedRuns,
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
        RunimalGameEngine.evolutionTarget(
            for: progressionSnapshot,
            pet: featuredCompanion.pet,
            recentRun: latestCompletedRun,
            season: weeklyBoard.season
        )
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

    var offlineMapPacks: [OfflineMapPackSummary] {
        offlineMaps.packs
    }

    var watchOfflineMapPacks: [OfflineMapPackSummary] {
        connectivity.watchOfflineMapPacks
    }

    var watchStoredOfflineMapPackIDs: Set<String> {
        connectivity.watchStoredOfflineMapPackIDs
    }

    var offlineMapTransferStatus: [String: OfflineMapPackTransferStatus] {
        connectivity.offlineMapTransferStatus
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
        let hasStageAdvance = progress.growthRecords.contains { record in
            let species = collection.first(where: { $0.id == record.companionID })?.pet.species
            return RunimalCompanionGrowthEngine.evolutionProgress(for: record, species: species).stageLabel != RunimalBalanceConfig.eggStageLabel
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
}

struct PhoneDashboardView: View {
    @State var store = PhoneDashboardStore()
    @State var selectedTab = ProcessInfo.processInfo.environment["RUNIMAL_OPEN_COLLECTION_ON_LAUNCH"] == "1" ? 2 : 0
    let pageTitles = ["동행", "러닝", "보관함", "도감"]

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
                    PhoneInventoryView(store: store)
                        .navigationBarTitleDisplayMode(.inline)
                }
                .tag(2)

                NavigationStack {
                    PhoneCompanionArchiveView(store: store)
                        .navigationBarTitleDisplayMode(.inline)
                }
                .tag(3)
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
}

#Preview {
    PhoneDashboardView()
}
