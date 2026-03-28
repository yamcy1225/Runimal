import RunimalCore
import SwiftUI

struct PhonePetDetailPanel: View {
    let companion: PetCollectionEntry
    let progress: EvolutionProgress
    let activeEffects: [WeeklyRewardEffect]
    let season: WeeklySeason

    private var tree: [EvolutionTreeNode] {
        RunimalGameEngine.evolutionTree(for: companion.pet, progress: progress, season: season)
    }

    private var tuningNotes: [String] {
        RunimalGameEngine.balanceTuningNotes(for: companion.pet)
    }

    private var effectResonance: [CompanionEffectResonance] {
        RunimalEffectResonanceEngine.effectResonance(
            for: companion,
            progress: progress,
            activeEffects: activeEffects
        )
    }

    var body: some View {
        GameSurface(title: "동행체 정보") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 16) {
                    PixelPetView(pet: companion.pet, pixelSize: 10)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(companion.pet.displayName)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(companion.pet.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.72))
                        HStack {
                            TraitChip(label: "Lv.\(companion.level)", accent: companion.pet.accentColor)
                            TraitChip(label: "유대 \(companion.bond)", accent: .white.opacity(0.22))
                            if RunimalGameEngine.seasonAffinity(for: companion.pet, season: season) {
                                TraitChip(label: season.title, accent: .mint.opacity(0.7))
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("진화 경로")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)

                    ForEach(tree) { node in
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(node.current ? companion.pet.accentColor : (node.unlocked ? .green : .white.opacity(0.16)))
                                .frame(width: 10, height: 10)
                                .padding(.top, 5)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(node.title)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    TraitChip(label: node.status.uppercased(), accent: node.current ? companion.pet.accentColor : .white.opacity(0.18))
                                }

                                Text(node.detail)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.72))
                            }
                        }
                    }
                }

                if activeEffects.isEmpty == false {
                    Divider()
                        .overlay(.white.opacity(0.12))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("효과 연결")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)

                        ForEach(effectResonance) { effect in
                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text(effect.title)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    TraitChip(label: effect.intensityLabel, accent: companion.pet.accentColor.opacity(0.82))
                                }

                                Text(effect.detail)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.72))
                            }
                        }
                    }
                }

                Divider()
                    .overlay(.white.opacity(0.12))

                VStack(alignment: .leading, spacing: 8) {
                    Text("성장 힌트")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)

                    ForEach(tuningNotes, id: \.self) { note in
                        Text(note)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                    }

                    if RunimalGameEngine.seasonAffinity(for: companion.pet, season: season) {
                        Text("시즌 전용 진화명 \(season.evolutionTitle)과 보상 \(season.rewardTitle)이 이 펫에게 연결됩니다.")
                            .font(.caption)
                            .foregroundStyle(.mint.opacity(0.84))
                    }
                }
            }
        }
    }
}
