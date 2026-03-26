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

    let runArchive: [RunSummary] = [
        RunSummary(distanceKm: 10.02, averagePaceSeconds: 318, cadence: 174, elevationGainM: 0, variability: 0.06, aura: .day, shape: .outAndBack),
        RunSummary(distanceKm: 6.4, averagePaceSeconds: 344, cadence: 168, elevationGainM: 132, variability: 0.11, aura: .dawn, shape: .loop),
        RunSummary(distanceKm: 3.8, averagePaceSeconds: 298, cadence: 176, elevationGainM: 18, variability: 0.18, aura: .night, shape: .maze),
        RunSummary(distanceKm: 8.1, averagePaceSeconds: 332, cadence: 171, elevationGainM: 42, variability: 0.08, aura: .dusk, shape: .loop),
    ]

    var pet: GeneratedPet {
        RunimalGameEngine.generatePet(from: summary)
    }

    var quests: [RunQuestStatus] {
        RunimalGameEngine.evaluateRunQuests(for: summary)
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
        TabView {
            NavigationStack {
                PhoneHomeView(store: store)
                    .navigationTitle("Runimal")
            }
            .tabItem {
                Label("Home", systemImage: "bolt.heart")
            }

            NavigationStack {
                PhoneCollectionView(store: store)
                    .navigationTitle("Collection")
            }
            .tabItem {
                Label("Codex", systemImage: "sparkles.rectangle.stack")
            }
        }
        .task {
            store.activateConnectivity()
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
