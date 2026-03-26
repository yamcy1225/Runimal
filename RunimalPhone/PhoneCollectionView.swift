import RunimalCore
import SwiftUI

struct PhoneCollectionView: View {
    let store: PhoneDashboardStore

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                stableCard
                evolutionCard
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

                ProgressView(value: store.evolutionProgress.progressRatio)
                    .tint(store.pet.accentColor)

                Text(store.evolutionProgress.headline)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.72))
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
