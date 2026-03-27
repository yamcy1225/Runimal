import RunimalCore
import SwiftUI

struct PhoneRewardStagePanel: View {
    let pet: GeneratedPet
    let progress: EvolutionProgress
    let activeEffects: [WeeklyRewardEffect]
    let claimableReward: WeeklyReward?
    let onClaim: (() -> Void)?

    @State private var energized = false

    private var stageTitle: String {
        if let claimableReward {
            return "Reward Reveal: \(claimableReward.title)"
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
            return claimableReward.detail
        }

        if activeEffects.isEmpty == false {
            return activeEffects.map(\.detail).joined(separator: " ")
        }

        if progress.progressRatio >= 0.8 {
            return "다음 러닝 한 번이면 진화 임계점을 밀어붙일 수 있는 구간입니다."
        }

        return "주간 보상과 성장 효과가 이 공간에서 다음 루프로 이어집니다."
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
        GameSurface(title: "Reward Stage") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(stageAccent.opacity(energized ? 0.28 : 0.18))
                            .frame(width: 108, height: 108)
                            .blur(radius: 12)

                        Circle()
                            .stroke(stageAccent.opacity(0.72), style: StrokeStyle(lineWidth: 2, dash: [4, 5]))
                            .frame(width: 96, height: 96)
                            .rotationEffect(.degrees(energized ? 12 : -8))

                        PixelPetView(pet: pet, pixelSize: 10)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(stageTitle)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)

                        Text(stageDetail)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.74))

                        HStack {
                            TraitChip(label: progress.stageLabel, accent: stageAccent)
                            if activeEffects.isEmpty == false {
                                TraitChip(label: "\(activeEffects.count) effects", accent: .white.opacity(0.22))
                            }
                            if claimableReward != nil {
                                TraitChip(label: "READY", accent: .green)
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
        .onAppear {
            energized = true
        }
        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: energized)
    }
}
