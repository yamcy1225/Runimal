import RunimalCore
import SwiftUI

struct PhoneFeedCinematicPanel: View {
    let pet: GeneratedPet
    let outcome: CompanionFeedOutcome
    let onDismiss: () -> Void

    @State private var shownProgress = 0.0
    @State private var xpScale: CGFloat = 0.86
    @State private var glow = false
    @State private var showEvolutionCut = false

    private var accent: Color {
        outcome.stageAdvanced ? .orange : pet.accentColor
    }

    private var stageHeadline: String {
        outcome.stageAdvanced
            ? "\(outcome.afterProgress.stageLabel) 진화 임계점 돌파"
            : "Growth Core synchronized"
    }

    var body: some View {
        GameSurface(title: "Feed Sequence", accent: accent, eyebrow: "Core Intake") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 16) {
                    ZStack {
                        HatchBurstView(accent: accent, pet: pet, scale: glow ? 1.08 : 0.9)

                        Circle()
                            .fill(accent.opacity(glow ? 0.28 : 0.16))
                            .frame(width: 110, height: 110)
                            .blur(radius: 14)

                        PixelPetView(pet: pet, pixelSize: 10)

                        if showEvolutionCut {
                            Text("EVOLVE")
                                .font(.caption.weight(.black))
                                .tracking(1.8)
                                .foregroundStyle(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(.white.opacity(0.92)))
                                .offset(y: -56)
                                .transition(.scale.combined(with: .opacity))
                        }

                        Text("+\(outcome.gainedExperience) XP")
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(accent.opacity(0.88)))
                            .scaleEffect(xpScale)
                            .offset(y: 56)
                    }
                    .frame(width: 132, height: 132)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(stageHeadline)
                            .font(.title3.weight(.black))
                            .foregroundStyle(.white)

                        Text("\(outcome.coreLabel)을 흡수해서 \(outcome.beforeProgress.totalExperience) XP에서 \(outcome.afterProgress.totalExperience) XP로 상승했습니다.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.76))

                        HStack {
                            TraitChip(label: outcome.beforeProgress.stageLabel, accent: .white.opacity(0.2))
                            Image(systemName: "arrow.right")
                                .foregroundStyle(.white.opacity(0.45))
                            TraitChip(label: outcome.afterProgress.stageLabel, accent: accent)
                            if outcome.stageAdvanced {
                                TraitChip(label: "CUT-IN", accent: .orange.opacity(0.82))
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Evolution Pulse")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.72))

                    RunimalProgressBar(progress: shownProgress, accent: accent, height: 12)

                    Text(outcome.afterProgress.headline)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.72))
                }
            }
        }
        .onAppear {
            startSequence()
        }
        .onChange(of: outcome.runID) { _, _ in
            startSequence()
        }
    }

    private func startSequence() {
        shownProgress = outcome.beforeProgress.progressRatio
        xpScale = 0.72
        glow = false
        showEvolutionCut = false

        Task {
            await MainActor.run {
                RunimalCuePlayer.playHatchCue(for: pet)
                withAnimation(.spring(response: 0.42, dampingFraction: 0.62)) {
                    xpScale = 1.04
                    glow = true
                }
            }

            try? await Task.sleep(for: .milliseconds(180))

            await MainActor.run {
                withAnimation(.easeInOut(duration: 1.0)) {
                    shownProgress = outcome.afterProgress.progressRatio
                }
            }

            if outcome.stageAdvanced {
                try? await Task.sleep(for: .milliseconds(520))
                await MainActor.run {
                    RunimalCuePlayer.playEvolutionCue(for: pet)
                    withAnimation(.spring(response: 0.48, dampingFraction: 0.68)) {
                        showEvolutionCut = true
                    }
                }
            }

            try? await Task.sleep(for: .seconds(outcome.stageAdvanced ? 3.6 : 2.8))
            await MainActor.run {
                onDismiss()
            }
        }
    }
}
