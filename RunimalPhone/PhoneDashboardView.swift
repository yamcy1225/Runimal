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

    func activateConnectivity() {
        connectivity.activate()
        syncCompanionEffects()
    }

    func bootstrap() {
        progress.load()
        progress.seedIfNeeded(from: runArchive)
    }

    func requestHealthAuthorization() async {
        await healthKit.requestAuthorization()
    }

    func syncWorkoutPlan() async {
        let suggestion = await planner.syncSuggestedWorkout(for: pet)
        connectivity.pushSuggestedWorkout(suggestion)
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
    }

    func ingestCompletedRun() {
        guard let record = connectivity.lastCompletedRun else { return }
        progress.append(completedRun: record)
    }

    func claimWeeklyReward() {
        guard let reward = claimableWeeklyReward else { return }
        progress.claimWeeklyReward(id: reward.id)
        syncCompanionEffects()
    }

    func activateCompanion(_ companionID: String) {
        progress.activateCompanion(id: companionID)
    }

    func feedActiveCompanion(with runID: String) {
        guard let run = completedRuns.first(where: { $0.id == runID }) else { return }
        _ = progress.feed(run: run, to: featuredCompanion, activeEffects: activeWeeklyEffects, season: weeklyBoard.season)
    }

    func retireCompanion(_ companionID: String) {
        guard let offer = retirableOffers.first(where: { $0.companion.id == companionID }) else { return }
        _ = progress.retireCompanion(companionID, essenceReward: offer.essenceReward)
    }

    func forgeOption(_ optionID: String) {
        guard let option = forgeOptions.first(where: { $0.id == optionID }) else { return }
        _ = progress.purchaseForgeOption(option)
    }

    func selectRole(_ role: CompanionRole) {
        progress.selectRole(role, for: featuredCompanion.id)
    }

    func unlockBuildNode(_ nodeID: String) {
        guard let node = buildNodes.first(where: { $0.id == nodeID }) else { return }
        _ = progress.unlockSkillNode(nodeID, for: featuredCompanion.id, cost: node.cost)
    }

    func syncCompanionEffects() {
        let context = CompanionEffectContext(
            claimedRewardIDs: Array(claimedWeeklyRewardIDs).sorted(),
            activeEffects: activeWeeklyEffects
        )
        connectivity.pushCompanionEffects(context)
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
