import Observation
import RunimalCore
import SwiftUI

@Observable
@MainActor
final class PhoneDashboardStore {
    let healthKit = PhoneHealthKitManager()
    let connectivity = PhoneConnectivityManager()
    let planner = PhoneWorkoutPlanner()

    let summary = RunSummary(
        distanceKm: 10.02,
        averagePaceSeconds: 318,
        cadence: 174,
        elevationGainM: 0,
        variability: 0.06,
        aura: .day,
        shape: .outAndBack
    )

    var pet: GeneratedPet {
        RunimalGameEngine.generatePet(from: summary)
    }

    var quests: [RunQuestStatus] {
        RunimalGameEngine.evaluateRunQuests(for: summary)
    }

    var suggestedWorkout: WorkoutPlanSuggestion {
        RunimalGameEngine.suggestWorkoutPlan(for: pet)
    }

    func activateConnectivity() {
        connectivity.activate()
    }

    func requestHealthAuthorization() async {
        await healthKit.requestAuthorization()
    }

    func syncWorkoutPlan() async {
        let suggestion = await planner.syncSuggestedWorkout(for: pet)
        connectivity.pushSuggestedWorkout(suggestion)
    }
}

struct PhoneDashboardView: View {
    @State private var store = PhoneDashboardStore()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    heroCard
                    questCard
                    workoutCard
                    syncCard
                }
                .padding(20)
            }
            .background(
                LinearGradient(
                    colors: [.black, store.pet.accentColor.opacity(0.26), Color(.systemGroupedBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Runimal")
            .task {
                store.activateConnectivity()
            }
        }
    }

    private var heroCard: some View {
        GameSurface {
            VStack(alignment: .leading, spacing: 14) {
                Text("Today’s Hatch")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.75))

                HStack(alignment: .center, spacing: 16) {
                    PixelPetView(pet: store.pet, pixelSize: 12)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(store.pet.displayName)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                        Text(store.pet.subtitle)
                            .foregroundStyle(.white.opacity(0.76))

                        HStack {
                            TraitChip(label: "\(store.summary.distanceKm.formatted(.number.precision(.fractionLength(1)))) km", accent: store.pet.accentColor)
                            TraitChip(label: "\(store.summary.cadence) spm", accent: .white.opacity(0.3))
                        }

                        Text(store.pet.explanation.first ?? "")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }
            }
        }
    }

    private var questCard: some View {
        GameSurface(title: "Growth Route") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(store.quests, id: \.label) { quest in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(quest.label)
                                .foregroundStyle(.white)
                            Text(quest.detail)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        Spacer()
                        TraitChip(
                            label: quest.completed ? "CLEAR" : "PENDING",
                            accent: quest.completed ? .green : .orange
                        )
                    }
                }
            }
        }
    }

    private var workoutCard: some View {
        GameSurface(title: "Suggested Run") {
            VStack(alignment: .leading, spacing: 10) {
                Text(store.suggestedWorkout.title.capitalized)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(store.suggestedWorkout.summary)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
                HStack {
                    TraitChip(label: "\(store.suggestedWorkout.scheduledDistanceKm.formatted()) km", accent: store.pet.accentColor)
                    TraitChip(label: store.suggestedWorkout.targetPaceBand, accent: .white.opacity(0.25))
                }

                HStack {
                    Button("Authorize HealthKit") {
                        Task { await store.requestHealthAuthorization() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(store.pet.accentColor)

                    Button("Send To Watch") {
                        Task { await store.syncWorkoutPlan() }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var syncCard: some View {
        GameSurface(title: "Companion Link") {
            VStack(alignment: .leading, spacing: 8) {
                Text("HealthKit \(store.healthKit.authorizationStatus)")
                    .foregroundStyle(.white)
                Text("WatchConnectivity \(store.connectivity.activationStateLabel) · \(store.connectivity.reachabilityLabel)")
                    .foregroundStyle(.white.opacity(0.76))

                if let snapshot = store.connectivity.lastSnapshot {
                    Text("Latest watch trace: \(Int(snapshot.distanceMeters))m · \(snapshot.cadence ?? 0) spm")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.72))
                } else {
                    Text(store.connectivity.lastMessage)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.72))
                }
            }
        }
    }
}

#Preview {
    PhoneDashboardView()
}
