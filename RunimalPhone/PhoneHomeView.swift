import RunimalCore
import SwiftUI

struct PhoneHomeView: View {
    let store: PhoneDashboardStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                heroCard
                questCard
                workoutCard
                syncCard
            }
            .padding(20)
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
                            TraitChip(label: store.evolutionProgress.stageLabel, accent: .white.opacity(0.22))
                        }

                        RunimalProgressBar(progress: store.evolutionProgress.progressRatio, accent: store.pet.accentColor, height: 8)

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

                if let reward = store.connectivity.lastReward {
                    Divider()
                        .overlay(.white.opacity(0.14))

                    HStack(alignment: .center, spacing: 12) {
                        PixelPetView(pet: reward.pet, pixelSize: 6)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Latest Hatch Reward")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.78))
                            Text("\(reward.pet.displayName) · \(reward.coreLabel)")
                                .foregroundStyle(.white)
                            Text(reward.flavorText)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.68))
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.7, dampingFraction: 0.85), value: store.connectivity.lastReward != nil)
    }
}
