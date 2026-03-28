import RunimalCore
import SwiftUI

struct PhoneMythicApexPanel: View {
    let pet: GeneratedPet
    let progress: EvolutionProgress
    let season: WeeklySeason

    private var tree: [EvolutionTreeNode] {
        RunimalGameEngine.evolutionTree(for: pet, progress: progress, season: season)
    }

    private var currentIndex: Int {
        max(0, tree.firstIndex(where: \.current) ?? 0)
    }

    private var isMythic: Bool {
        progress.stageLabel == "Mythic"
    }

    private var mythicTitle: String {
        RunimalGameEngine.mythicTitle(for: pet, season: season)
    }

    private var stageLine: String {
        tree
            .enumerated()
            .map { index, node in
                if index < currentIndex {
                    return "●"
                }
                if index == currentIndex {
                    return "◉"
                }
                return "○"
            }
            .joined(separator: " ")
    }

    var body: some View {
        GameSurface(
            title: isMythic ? "최종 진화 고정" : "Mythic 경로",
            accent: pet.accentColor,
            eyebrow: isMythic ? "APEX" : "FINAL STAGE"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(pet.accentColor.opacity(0.16))
                            .frame(width: 88, height: 88)
                            .blur(radius: 12)

                        Circle()
                            .stroke(pet.accentColor.opacity(0.82), lineWidth: 2)
                            .frame(width: 72, height: 72)

                        PixelPetView(pet: pet, pixelSize: 8)
                    }
                    .frame(width: 92, height: 92)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(mythicTitle)
                            .font(.title3.weight(.black))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Text(isMythic ? "최종 형태가 활성화되었습니다." : "다음 목표는 최종 진화 해금입니다.")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.72))

                        HStack(spacing: 8) {
                            TraitChip(label: progress.stageLabel, accent: pet.accentColor)
                            TraitChip(label: "XP \(progress.totalExperience)", accent: .white.opacity(0.22))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(stageLine)
                        .font(.caption.weight(.black))
                        .tracking(2.4)
                        .foregroundStyle(pet.accentColor.opacity(0.9))

                    RunimalProgressBar(
                        progress: progress.progressRatio,
                        accent: pet.accentColor,
                        height: 8
                    )

                    Text(RunimalGameEngine.mythicSignalLine(for: pet, season: season))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(2)
                }

                HStack(spacing: 10) {
                    compactNode(title: tree[safe: 0]?.title ?? "Trace", state: currentIndex >= 0, accent: pet.accentColor)
                    compactNode(title: tree[safe: 1]?.title ?? "Stage 1", state: currentIndex >= 1, accent: pet.accentColor)
                    compactNode(title: tree[safe: 2]?.title ?? "Stage 2", state: currentIndex >= 2, accent: pet.accentColor)
                    compactNode(title: tree[safe: 3]?.title ?? "Ascended", state: currentIndex >= 3, accent: pet.accentColor)
                    compactNode(title: "Mythic", state: isMythic, accent: .orange)
                }
            }
        }
    }

    private func compactNode(title: String, state: Bool, accent: Color) -> some View {
        VStack(spacing: 6) {
            Circle()
                .fill(state ? accent.opacity(0.96) : .white.opacity(0.12))
                .frame(width: 12, height: 12)

            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(state ? .white : .white.opacity(0.45))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
