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

    var pet: GeneratedPet {
        RunimalGameEngine.generatePet(from: summary, claimedRewardIDs: claimedWeeklyRewardIDs)
    }

    var quests: [RunQuestStatus] {
        RunimalGameEngine.evaluateRunQuests(for: summary, claimedRewardIDs: claimedWeeklyRewardIDs)
    }

    var suggestedWorkout: WorkoutPlanSuggestion {
        RunimalGameEngine.suggestWorkoutPlan(for: pet)
    }

    var collection: [PetCollectionEntry] {
        RunimalGameEngine.buildCollection(from: runArchive)
    }

    var featuredCompanion: PetCollectionEntry {
        collection.first ?? PetCollectionEntry(
            id: "fallback",
            pet: pet,
            level: 1,
            bond: 20,
            totalDistanceKm: summary.distanceKm,
            headline: "starter companion"
        )
    }

    var variantCodex: [VariantCodexEntry] {
        RunimalGameEngine.buildVariantCodex(from: collection)
    }

    var evolutionProgress: EvolutionProgress {
        RunimalGameEngine.evolutionProgress(for: progress.journal)
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

    func activateConnectivity() {
        connectivity.activate()
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
