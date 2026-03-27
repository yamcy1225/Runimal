import Observation
import RunimalCore
import SwiftUI

@MainActor
@Observable
final class MacBalanceLabStore {
    enum Preset: String, CaseIterable, Identifiable {
        case tempo = "Tempo"
        case mountain = "Mountain"
        case night = "Night"
        case long = "Long"

        var id: String { rawValue }
    }

    var distanceKm = 10.02
    var averagePaceSeconds = 318.0
    var cadence = 174.0
    var elevationGainM = 0.0
    var variability = 0.06
    var aura: RunTimeAura = .day
    var shape: RouteShape = .outAndBack
    var selectedScenarioID = RunimalQAReplayEngine.scenarios.first?.id ?? "offline-link"

    var summary: RunSummary {
        RunSummary(
            distanceKm: distanceKm,
            averagePaceSeconds: Int(averagePaceSeconds.rounded()),
            cadence: Int(cadence.rounded()),
            elevationGainM: Int(elevationGainM.rounded()),
            variability: variability,
            aura: aura,
            shape: shape
        )
    }

    var pet: GeneratedPet { RunimalGameEngine.generatePet(from: summary) }
    var quests: [RunQuestStatus] { RunimalGameEngine.evaluateRunQuests(for: summary) }
    var plan: WorkoutPlanSuggestion { RunimalGameEngine.suggestWorkoutPlan(for: pet) }
    var reward: RunRewardSummary { RunimalGameEngine.evaluateReward(for: summary) }
    var progress: EvolutionProgress {
        let entries = (0..<3).map { index in
            RunimalGameEngine.makeJournalEntry(
                reward: reward,
                distanceKm: max(distanceKm - Double(index), 2),
                cadence: max(Int(cadence.rounded()) - index * 2, 150),
                createdAt: Calendar.current.date(byAdding: .day, value: -index, to: Date()) ?? Date()
            )
        }
        return RunimalGameEngine.evolutionProgress(for: entries)
    }

    var evolutionTree: [EvolutionTreeNode] {
        RunimalGameEngine.evolutionTree(for: pet, progress: progress)
    }

    var feedback: LiveRunFeedback {
        RunimalGameEngine.evaluateLiveFeedback(
            for: LiveRunSnapshot(
                elapsedSeconds: Int(distanceKm * averagePaceSeconds),
                distanceMeters: distanceKm * 1000,
                currentHeartRate: 154,
                cadence: Int(cadence.rounded()),
                elevationGainM: Int(elevationGainM.rounded()),
                averagePaceSeconds: Int(averagePaceSeconds.rounded())
            )
        )
    }

    var balanceNotes: [String] {
        RunimalGameEngine.balanceTuningNotes(for: pet)
    }

    func apply(_ preset: Preset) {
        switch preset {
        case .tempo:
            distanceKm = 6.2
            averagePaceSeconds = 303
            cadence = 176
            elevationGainM = 18
            variability = 0.09
            aura = .day
            shape = .outAndBack
        case .mountain:
            distanceKm = 7.8
            averagePaceSeconds = 352
            cadence = 167
            elevationGainM = 154
            variability = 0.11
            aura = .dawn
            shape = .loop
        case .night:
            distanceKm = 4.6
            averagePaceSeconds = 326
            cadence = 171
            elevationGainM = 26
            variability = 0.22
            aura = .night
            shape = .maze
        case .long:
            distanceKm = 13.4
            averagePaceSeconds = 334
            cadence = 172
            elevationGainM = 42
            variability = 0.07
            aura = .dusk
            shape = .loop
        }
    }
}

struct MacDashboardView: View {
    @State private var store = MacBalanceLabStore()

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 18) {
                controlColumn
                resultColumn
                detailColumn
            }
            .padding(22)
        }
        .frame(width: 1180, height: 860)
        .background(
            LinearGradient(
                colors: [.black, store.pet.accentColor.opacity(0.22), Color.black.opacity(0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var controlColumn: some View {
        VStack(alignment: .leading, spacing: 18) {
            GameSurface(title: "Balance Lab") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("프리셋과 수치를 바꿔가며 펫 결과와 코칭 기준을 동시에 검토합니다.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))

                    HStack {
                        ForEach(MacBalanceLabStore.Preset.allCases) { preset in
                            Button(preset.rawValue) {
                                store.apply(preset)
                            }
                            .buttonStyle(.bordered)
                            .tint(store.pet.accentColor)
                        }
                    }

                    sliderRow("Distance", value: $store.distanceKm, range: 2...18, step: 0.1, format: "%.1f km")
                    sliderRow("Pace", value: $store.averagePaceSeconds, range: 280...400, step: 1, format: "%.0f s/km")
                    sliderRow("Cadence", value: $store.cadence, range: 150...182, step: 1, format: "%.0f spm")
                    sliderRow("Elevation", value: $store.elevationGainM, range: 0...220, step: 1, format: "%.0f m")
                    sliderRow("Variability", value: $store.variability, range: 0.04...0.32, step: 0.01, format: "%.2f")

                    HStack {
                        picker("Aura", selection: $store.aura, cases: RunTimeAura.allCases)
                        picker("Shape", selection: $store.shape, cases: RouteShape.allCases)
                    }
                }
            }

            GameSurface(title: "Quest Board") {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(store.quests, id: \.label) { quest in
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

            MacQAReplayPanel(selectedScenarioID: $store.selectedScenarioID)
        }
        .frame(width: 360)
    }

    private var resultColumn: some View {
        VStack(alignment: .leading, spacing: 18) {
            GameSurface {
                HStack(spacing: 18) {
                    PixelPetView(pet: store.pet, pixelSize: 14)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Runimal Control Deck")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.74))
                        Text(store.pet.displayName)
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(.white)
                        Text(store.pet.subtitle)
                            .foregroundStyle(.white.opacity(0.72))
                        HStack {
                            TraitChip(label: "\(store.summary.distanceKm.formatted(.number.precision(.fractionLength(1)))) km", accent: store.pet.accentColor)
                            TraitChip(label: "\(store.summary.cadence) spm", accent: .white.opacity(0.28))
                            TraitChip(label: store.feedback.label.uppercased(), accent: store.pet.accentColor.opacity(0.82))
                        }
                    }
                }
            }

            GameSurface(title: "Live Coaching") {
                VStack(alignment: .leading, spacing: 10) {
                    Text(store.feedback.headline)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(store.feedback.detail)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                    RunimalProgressBar(progress: store.feedback.intensity, accent: store.pet.accentColor, height: 9)
                }
            }

            GameSurface(title: "Reward Preview") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        TraitChip(label: store.reward.coreLabel, accent: store.pet.accentColor)
                        TraitChip(label: "+\(store.reward.experience) XP", accent: .green)
                    }

                    Text(store.reward.flavorText)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))

                    VStack(alignment: .leading, spacing: 8) {
                        statRow("Vitality", store.pet.stats.vitality)
                        statRow("Agility", store.pet.stats.agility)
                        statRow("Dexterity", store.pet.stats.dexterity)
                        statRow("Focus", store.pet.stats.focus)
                        statRow("Defense", store.pet.stats.defense)
                    }
                }
            }
        }
        .frame(width: 360)
    }

    private var detailColumn: some View {
        VStack(alignment: .leading, spacing: 18) {
            GameSurface(title: "Evolution Track") {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(store.evolutionTree) { node in
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(node.current ? store.pet.accentColor : (node.unlocked ? .green : .white.opacity(0.16)))
                                .frame(width: 10, height: 10)
                                .padding(.top, 5)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(node.title)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    TraitChip(label: node.status.uppercased(), accent: node.current ? store.pet.accentColor : .white.opacity(0.18))
                                }
                                Text(node.detail)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.72))
                            }
                        }
                    }
                }
            }

            GameSurface(title: "Tuning Notes") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(store.plan.title.capitalized)
                        .foregroundStyle(.white)
                    Text(store.plan.summary)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                    TraitChip(label: store.plan.targetPaceBand, accent: store.pet.accentColor)

                    Divider()
                        .overlay(.white.opacity(0.12))

                    ForEach(store.balanceNotes, id: \.self) { note in
                        Text(note)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }
            }
        }
        .frame(width: 380)
    }

    private func statRow(_ label: String, _ value: Int) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.white.opacity(0.78))
            Spacer()
            Text(String(repeating: "■", count: value))
                .font(.caption.monospaced())
                .foregroundStyle(store.pet.accentColor)
        }
    }

    private func sliderRow(_ label: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, format: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .foregroundStyle(.white)
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.7))
            }

            Slider(value: value, in: range, step: step)
                .tint(store.pet.accentColor)
        }
    }

    private func picker<Value: Hashable & CaseIterable & RawRepresentable>(_ title: String, selection: Binding<Value>, cases: Value.AllCases) -> some View where Value.RawValue == String {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .foregroundStyle(.white)

            Picker(title, selection: selection) {
                ForEach(Array(cases), id: \.self) { value in
                    Text(value.rawValue.capitalized).tag(value)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

#Preview {
    MacDashboardView()
}
