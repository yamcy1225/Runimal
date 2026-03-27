import RunimalCore
import SwiftUI

struct PhoneRewardStagePanel: View {
    let pet: GeneratedPet
    let progress: EvolutionProgress
    let activeEffects: [WeeklyRewardEffect]
    let season: WeeklySeason
    let claimableReward: WeeklyReward?
    let onClaim: (() -> Void)?

    @State private var energized = false
    @State private var burstScale: CGFloat = 0.92
    @State private var revealPet = false
    @State private var crackEgg = false

    private var stageTitle: String {
        if claimableReward != nil {
            return "Reward Reveal: \(season.rewardTitle)"
        }

        if activeEffects.isEmpty == false {
            return "Active Effect Stage"
        }

        if progress.progressRatio >= 0.8 {
            return "Evolution Surge"
        }

        return "Growth Chamber"
    }

    private var stageDetail: String {
        if let claimableReward {
            return "\(claimableReward.detail) 이번 시즌 한정 보상 이름은 \(season.rewardTitle)입니다."
        }

        if activeEffects.isEmpty == false {
            return activeEffects.map(\.detail).joined(separator: " ")
        }

        if progress.progressRatio >= 0.8 {
            return "다음 러닝 한 번이면 진화 임계점을 밀어붙일 수 있는 구간입니다."
        }

        return "주간 보상과 성장 효과가 이 공간에서 다음 루프로 이어집니다."
    }

    private var variantLabel: String {
        pet.rareVariant.map { RareVariantMeta.labels[$0] ?? $0.rawValue } ?? "Standard Trace"
    }

    private var stageAccent: Color {
        if claimableReward != nil {
            return .mint
        }

        if activeEffects.isEmpty == false {
            return pet.accentColor
        }

        return .orange
    }

    var body: some View {
        GameSurface(title: "Reward Stage", accent: stageAccent, eyebrow: "Season Chamber") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 16) {
                    ZStack {
                        HatchBurstView(accent: stageAccent, pet: pet, scale: burstScale)

                        Circle()
                            .fill(stageAccent.opacity(energized ? 0.28 : 0.18))
                            .frame(width: 108, height: 108)
                            .blur(radius: 12)

                        Circle()
                            .stroke(stageAccent.opacity(0.72), style: StrokeStyle(lineWidth: 2, dash: [4, 5]))
                            .frame(width: 96, height: 96)
                            .rotationEffect(.degrees(energized ? 12 : -8))

                        if revealPet {
                            PixelPetView(pet: pet, pixelSize: 10)
                                .transition(.scale(scale: 0.86).combined(with: .opacity))
                        } else {
                            TraceEggView(accent: stageAccent, pixelSize: 10, cracked: crackEgg)
                                .transition(.scale(scale: 1.04).combined(with: .opacity))
                        }
                    }
                    .frame(width: 124, height: 124)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.white.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(stageAccent.opacity(0.22), lineWidth: 1)
                            )
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text(stageTitle)
                            .font(.title3.weight(.black))
                            .foregroundStyle(.white)

                        Text(variantLabel)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(stageAccent.opacity(0.94))

                        Text(stageDetail)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.74))

                        HStack {
                            TraitChip(label: progress.stageLabel, accent: stageAccent)
                            TraitChip(label: season.title, accent: .white.opacity(0.22))
                            if activeEffects.isEmpty == false {
                                TraitChip(label: "\(activeEffects.count) effects", accent: .white.opacity(0.22))
                            }
                            if claimableReward != nil {
                                TraitChip(label: "READY", accent: .green)
                            }
                            if pet.rareVariant != nil {
                                TraitChip(label: "RARE PATH", accent: .orange.opacity(0.82))
                            }
                        }
                    }
                }

                RunimalProgressBar(progress: progress.progressRatio, accent: stageAccent, height: 10)

                if activeEffects.isEmpty == false {
                    HStack(spacing: 8) {
                        ForEach(activeEffects) { effect in
                            TraitChip(label: effect.title, accent: stageAccent.opacity(0.82))
                        }
                    }
                }

                if let onClaim, claimableReward != nil {
                    Button("Reveal Weekly Reward") {
                        onClaim()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(stageAccent)
                    .fontWeight(.black)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [stageAccent.opacity(0.18), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(alignment: .topTrailing) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(season.title.uppercased())
                    .font(.caption2.weight(.black))
                    .tracking(1.2)
                Text("STAGE")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.62))
            }
            .foregroundStyle(stageAccent.opacity(0.92))
            .padding(.top, 12)
            .padding(.trailing, 14)
        }
        .onAppear {
            energized = true
            animateBurst()
            startRevealSequence()
        }
        .onChange(of: claimableReward?.id) { _, _ in
            animateBurst()
            startRevealSequence()
            RunimalCuePlayer.playHatchCue(for: pet)
        }
        .onChange(of: progress.stageLabel) { _, _ in
            animateBurst()
            RunimalCuePlayer.playEvolutionCue(for: pet)
        }
        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: energized)
    }

    private func animateBurst() {
        burstScale = 0.84
        withAnimation(.spring(response: 0.62, dampingFraction: 0.68)) {
            burstScale = 1.08
        }
    }

    private func startRevealSequence() {
        revealPet = false
        crackEgg = false

        Task {
            try? await Task.sleep(for: .milliseconds(220))
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.24)) {
                    crackEgg = true
                }
            }
            try? await Task.sleep(for: .milliseconds(420))
            await MainActor.run {
                withAnimation(.spring(response: 0.62, dampingFraction: 0.72)) {
                    revealPet = true
                }
            }
        }
    }
}
