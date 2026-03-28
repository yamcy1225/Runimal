import RunimalCore
import SwiftUI

struct PhoneHomeView: View {
    let store: PhoneDashboardStore

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.05, blue: 0.08),
                    Color(red: 0.02, green: 0.03, blue: 0.05),
                    store.mainAccentColor.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [store.mainAccentColor.opacity(0.16), .clear],
                center: .top,
                startRadius: 40,
                endRadius: 420
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerDeck
                    heroCard
                    if let sanctuary = store.sanctuaryReward {
                        PhoneSanctuaryPanel(reward: sanctuary)
                    }
                    PhoneRewardStagePanel(
                        pet: store.pet,
                        progress: store.evolutionProgress,
                        activeEffects: store.activeWeeklyEffects,
                        season: store.weeklyBoard.season,
                        claimableReward: store.claimableWeeklyReward,
                        onClaim: store.claimableWeeklyReward == nil ? nil : { store.claimWeeklyReward() }
                    )
                    questCard
                }
                .padding(20)
            }
        }
    }

    private var headerDeck: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("오늘의 동행")
                .font(.caption.weight(.black))
                .tracking(1.4)
                .foregroundStyle(store.mainAccentColor.opacity(0.92))

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(store.mainSelectionLabel)
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text(store.mainSelectionDetail)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.68))
                        .lineLimit(2)
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 6) {
                    TraitChip(label: store.weeklyBoard.season.title, accent: store.mainAccentColor)
                    TraitChip(label: store.mainSelection?.kind == .egg ? "메인 알" : "메인 동행", accent: .white.opacity(0.16))
                }
            }
        }
    }

    private var heroCard: some View {
        GameSurface(accent: store.mainAccentColor, eyebrow: "메인 동행체") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 16) {
                    if store.mainSelection?.kind == .egg {
                        TraceEggView(
                            accent: store.mainAccentColor,
                            shell: store.mainEgg?.shell,
                            pixelSize: 12,
                            cracked: store.mainEgg?.readyToHatch == true,
                            resonance: store.mainEggResonance
                        )
                    } else {
                        PixelPetView(pet: store.pet, pixelSize: 12, seasonalLayers: store.seasonalLayers)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            TraitChip(label: "\(store.summary.distanceKm.formatted(.number.precision(.fractionLength(1)))) km", accent: store.mainAccentColor)
                            TraitChip(label: "\(store.summary.cadence) spm", accent: .white.opacity(0.3))
                            TraitChip(
                                label: store.mainSelection?.kind == .egg ? (store.mainEgg?.shell.displayLabel ?? "숨김 알") : store.evolutionProgress.stageLabel,
                                accent: .white.opacity(0.22)
                            )
                        }

                        RunimalProgressBar(
                            progress: store.mainSelection?.kind == .egg ? (store.mainEgg?.progressRatio ?? 0) : store.evolutionProgress.progressRatio,
                            accent: store.mainAccentColor,
                            height: 8
                        )

                        RunimalSignalBadge(
                            icon: "sparkles",
                            label: store.mainSelection?.kind == .egg ? (store.mainEgg?.shell.scanHeadline ?? "DIGITAL GAP SCAN ACTIVE") : "\(store.summary.distanceKm.formatted(.number.precision(.fractionLength(1))))km 각인",
                            accent: store.mainAccentColor
                        )
                    }
                }

                HStack(spacing: 10) {
                    statPillar(title: "XP", value: "\(store.evolutionProgress.totalExperience)")
                    statPillar(title: "단계", value: store.evolutionProgress.stageLabel)
                    statPillar(title: "시즌", value: store.weeklyBoard.season.title)
                }

                if let egg = store.mainEgg, store.mainSelection?.kind == .egg {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SCAN LOG")
                            .font(.caption2.weight(.black))
                            .tracking(1.2)
                            .foregroundStyle(egg.shell.accentColor.opacity(0.88))

                        ForEach(egg.shell.scanLogLines.prefix(2), id: \.self) { line in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(egg.shell.particleColor.opacity(0.9))
                                    .frame(width: 5, height: 5)
                                Text(line)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.white.opacity(0.6))
                                    .lineLimit(1)
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
    }

    private var questCard: some View {
        GameSurface(title: "이번 주 요약", accent: store.mainAccentColor, eyebrow: "빠른 확인") {
            VStack(alignment: .leading, spacing: 14) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    RunimalMetricTile(
                        icon: "figure.run",
                        title: "러닝",
                        value: "\(store.weeklyBoard.runCount)",
                        accent: store.mainAccentColor
                    )
                    RunimalMetricTile(
                        icon: "map",
                        title: "거리",
                        value: "\(store.weeklyBoard.totalDistanceKm.formatted(.number.precision(.fractionLength(1)))) km",
                        accent: .green
                    )
                    RunimalMetricTile(
                        icon: "flame.fill",
                        title: "연속",
                        value: "\(store.weeklyBoard.streakDays)d",
                        accent: .orange
                    )
                    RunimalMetricTile(
                        icon: "sparkles",
                        title: "알",
                        value: "\(store.eggInventory.count)",
                        accent: .mint
                    )
                }

                if let nextReward = store.claimableWeeklyReward {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            RunimalSignalBadge(icon: "gift.fill", label: "다음 보상", accent: store.mainAccentColor)
                            Spacer()
                            TraitChip(label: "READY", accent: .green.opacity(0.72))
                        }

                        Text(nextReward.title)
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)
                        Text(nextReward.detail)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.66))
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(.white.opacity(0.08), lineWidth: 1)
                            )
                    )
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("핵심 미션")
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)
                        Spacer()
                        RunimalSignalBadge(
                            icon: "crown.fill",
                            label: "\(store.weeklyBoard.completedMissionCount)/\(store.weeklyBoard.missions.count)",
                            accent: store.mainAccentColor
                        )
                    }

                    ForEach(store.weeklyBoard.missions.prefix(2), id: \.id) { mission in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(mission.title)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.white)
                                Spacer()
                                TraitChip(
                                    label: mission.completed ? "완료" : mission.progressLabel,
                                    accent: mission.completed ? .green : .white.opacity(0.18)
                                )
                            }

                            RunimalProgressBar(
                                progress: mission.progressRatio,
                                accent: mission.completed ? .green : store.mainAccentColor,
                                height: 7
                            )
                        }
                    }
                }
            }
        }
    }

    private func statPillar(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.black))
                .tracking(1.1)
                .foregroundStyle(.white.opacity(0.56))
            Text(value)
                .font(.subheadline.weight(.black))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

}
