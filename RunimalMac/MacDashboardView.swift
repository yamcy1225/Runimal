import RunimalCore
import SwiftUI

struct MacDashboardView: View {
    private let summary = RunSummary(
        distanceKm: 10.02,
        averagePaceSeconds: 318,
        cadence: 174,
        elevationGainM: 0,
        variability: 0.06,
        aura: .day,
        shape: .outAndBack
    )

    private var pet: GeneratedPet {
        RunimalGameEngine.generatePet(from: summary)
    }

    private var quests: [RunQuestStatus] {
        RunimalGameEngine.evaluateRunQuests(for: summary)
    }

    private var plan: WorkoutPlanSuggestion {
        RunimalGameEngine.suggestWorkoutPlan(for: pet)
    }

    private var balanceNotes: [String] {
        RunimalGameEngine.balanceTuningNotes(for: pet)
    }

    var body: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 18) {
                GameSurface {
                    HStack(spacing: 18) {
                        PixelPetView(pet: pet, pixelSize: 14)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Runimal Control Deck")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.74))
                            Text(pet.displayName)
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(.white)
                            Text(pet.subtitle)
                                .foregroundStyle(.white.opacity(0.72))
                            HStack {
                                TraitChip(label: "\(summary.distanceKm.formatted()) km", accent: pet.accentColor)
                                TraitChip(label: "\(summary.cadence) spm", accent: .white.opacity(0.28))
                            }
                        }
                    }
                }

                GameSurface(title: "Quest Board") {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(quests, id: \.label) { quest in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(quest.label)
                                        .foregroundStyle(.white)
                                    Text(quest.detail)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.72))
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

            VStack(alignment: .leading, spacing: 18) {
                GameSurface(title: "Balance View") {
                    VStack(alignment: .leading, spacing: 8) {
                        statRow("Vitality", pet.stats.vitality)
                        statRow("Agility", pet.stats.agility)
                        statRow("Dexterity", pet.stats.dexterity)
                        statRow("Focus", pet.stats.focus)
                        statRow("Defense", pet.stats.defense)
                    }
                }

                GameSurface(title: "Workout Plan") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(plan.title.capitalized)
                            .foregroundStyle(.white)
                        Text(plan.summary)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                        TraitChip(label: plan.targetPaceBand, accent: pet.accentColor)
                    }
                }

                GameSurface(title: "Tuning Notes") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(balanceNotes, id: \.self) { note in
                            Text(note)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.72))
                        }
                    }
                }
            }
            .frame(width: 280)
        }
        .padding(22)
        .frame(width: 860)
        .background(
            LinearGradient(
                colors: [.black, pet.accentColor.opacity(0.22), Color.black.opacity(0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func statRow(_ label: String, _ value: Int) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.white.opacity(0.78))
            Spacer()
            Text(String(repeating: "■", count: value))
                .font(.caption.monospaced())
                .foregroundStyle(pet.accentColor)
        }
    }
}

#Preview {
    MacDashboardView()
}
