import RunimalCore
import SwiftUI

struct PhoneCollectionView: View {
    let store: PhoneDashboardStore

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    private var effectResonance: [CompanionEffectResonance] {
        RunimalEffectResonanceEngine.effectResonance(
            for: store.featuredCompanion,
            progress: store.evolutionProgress,
            activeEffects: store.activeWeeklyEffects
        )
    }

    private var resonanceBoard: [CompanionResonanceSummary] {
        RunimalEffectResonanceEngine.compareCollection(
            store.collection,
            progress: store.evolutionProgress,
            activeEffects: store.activeWeeklyEffects
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                stableCard
                evolutionCard
                collectionEffectStage
                PhonePetDetailPanel(
                    companion: store.featuredCompanion,
                    progress: store.evolutionProgress,
                    activeEffects: store.activeWeeklyEffects
                )
                resonanceCompareBoard
                collectionGrid
                growthTimeline
                variantCodex
            }
            .padding(20)
        }
    }

    private var stableCard: some View {
        GameSurface(title: "Active Stable") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 16) {
                    PixelPetView(pet: store.featuredCompanion.pet, pixelSize: 10)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(store.featuredCompanion.pet.displayName)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(store.featuredCompanion.headline)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.72))

                        HStack {
                            TraitChip(label: "Lv.\(store.featuredCompanion.level)", accent: store.featuredCompanion.pet.accentColor)
                            TraitChip(label: "Bond \(store.featuredCompanion.bond)", accent: .white.opacity(0.28))
                        }
                    }
                }

                Text("최근 러닝 패턴을 가장 잘 흡수한 주력 펫입니다. 홈의 추천 러닝과 연동해 성장 루프를 유지합니다.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.72))

                if store.activeWeeklyEffects.isEmpty == false {
                    HStack(spacing: 8) {
                        ForEach(store.activeWeeklyEffects) { effect in
                            TraitChip(label: effect.title, accent: store.featuredCompanion.pet.accentColor.opacity(0.78))
                        }
                    }
                }
            }
        }
    }

    private var evolutionCard: some View {
        GameSurface(title: "Evolution Pulse") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(store.evolutionProgress.stageLabel)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    TraitChip(label: "\(store.evolutionProgress.totalExperience) XP", accent: store.pet.accentColor)
                }

                RunimalProgressBar(progress: store.evolutionProgress.progressRatio, accent: store.pet.accentColor, height: 10)

                Text(store.evolutionProgress.headline)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
    }

    private var collectionEffectStage: some View {
        GameSurface(title: "Effect Stage") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(store.featuredCompanion.pet.accentColor.opacity(0.2))
                            .frame(width: 84, height: 84)
                            .blur(radius: 10)

                        Circle()
                            .stroke(store.featuredCompanion.pet.accentColor.opacity(0.76), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                            .frame(width: 70, height: 70)

                        PixelPetView(pet: store.featuredCompanion.pet, pixelSize: 8)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(store.activeWeeklyEffects.isEmpty ? "No active weekly effects" : "Current boost chain")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(store.activeWeeklyEffects.isEmpty
                             ? "주간 보상을 수령하면 이 주력 펫의 성장/진화/변이 판정이 여기서 바로 반영됩니다."
                             : "현재 활성 효과가 주력 펫의 XP, 변이, 진화 속도에 직접 연결되어 있습니다.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }

                if effectResonance.isEmpty == false {
                    ForEach(effectResonance) { effect in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(effect.title)
                                    .foregroundStyle(.white)
                                Spacer()
                                TraitChip(label: "\(effect.intensityLabel) \(effect.score)", accent: .green)
                            }
                            Text(effect.detail)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.68))
                        }
                    }
                }
            }
        }
    }

    private var collectionGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Field Collection")
                .font(.headline)
                .foregroundStyle(.white)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(store.collection) { entry in
                    GameSurface {
                        VStack(alignment: .leading, spacing: 10) {
                            PixelPetView(pet: entry.pet, pixelSize: 8)

                            Text(entry.pet.displayName)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)
                            Text(entry.pet.subtitle)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.72))

                            HStack {
                                TraitChip(label: "Lv.\(entry.level)", accent: entry.pet.accentColor)
                                TraitChip(label: "\(entry.totalDistanceKm.formatted(.number.precision(.fractionLength(1))))km", accent: .white.opacity(0.24))
                                if store.activeWeeklyEffects.isEmpty == false && entry.id == store.featuredCompanion.id {
                                    TraitChip(label: "BUFFED", accent: .green.opacity(0.7))
                                }
                            }

                            Text(entry.headline)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.68))
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
    }

    private var resonanceCompareBoard: some View {
        GameSurface(title: "Resonance Board") {
            VStack(alignment: .leading, spacing: 12) {
                if resonanceBoard.isEmpty {
                    Text("비교할 컬렉션 데이터가 아직 없습니다.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.72))
                } else {
                    ForEach(Array(resonanceBoard.prefix(3).enumerated()), id: \.element.id) { index, item in
                        HStack(alignment: .top, spacing: 12) {
                            TraitChip(
                                label: "#\(index + 1)",
                                accent: index == 0 ? .green.opacity(0.82) : .white.opacity(0.18)
                            )

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(item.companion.pet.displayName)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    TraitChip(
                                        label: "\(item.intensityLabel) \(item.totalScore)",
                                        accent: item.companion.pet.accentColor.opacity(0.82)
                                    )
                                }

                                Text(item.headline)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.72))

                                if let topEffectTitle = item.topEffectTitle {
                                    Text("Top effect · \(topEffectTitle)")
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.56))
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var variantCodex: some View {
        GameSurface(title: "Mutation Codex") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(store.variantCodex) { entry in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(entry.discovered ? store.pet.accentColor : .white.opacity(0.16))
                            .frame(width: 10, height: 10)
                            .padding(.top, 5)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(entry.label)
                                    .foregroundStyle(.white)
                                Spacer()
                                TraitChip(
                                    label: entry.discovered ? "FOUND" : "LOCKED",
                                    accent: entry.discovered ? .green : .white.opacity(0.2)
                                )
                            }

                            Text(entry.detail)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.72))
                            Text(entry.passive)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
            }
        }
    }

    private var growthTimeline: some View {
        GameSurface(title: "Growth Timeline") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(store.recentJournal.prefix(4)) { entry in
                    HStack(alignment: .top, spacing: 12) {
                        PixelPetView(pet: entry.reward.pet, pixelSize: 5)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(entry.reward.pet.displayName) · +\(entry.reward.experience) XP")
                                .foregroundStyle(.white)
                            Text("\(entry.distanceKm.formatted(.number.precision(.fractionLength(1))))km · \(entry.cadence) spm")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.72))
                            Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.56))
                        }
                    }
                }
            }
        }
    }
}
