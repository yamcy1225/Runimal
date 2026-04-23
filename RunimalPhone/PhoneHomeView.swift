import RunimalCore
import SwiftUI

struct PhoneHomeView: View {
    let store: PhoneDashboardStore

    private var worldPack: WorldContentPack {
        store.contentCatalog.worldContentPack()
    }

    private var worldPackSummaries: [ContentPackSummary] {
        store.contentCatalog.worldContentPackSummaries()
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    GameBoyPalette.mediumLight,
                    GameBoyPalette.lightest,
                    GameBoyPalette.mediumLight.opacity(0.88)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            GameBoyLCDOverlay()
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerDeck
                    fantasyPulseCard
                    worldFrontierCard
                    heroCard
                    if let sanctuary = store.sanctuaryReward {
                        PhoneSanctuaryPanel(reward: sanctuary)
                    }
                    if store.isEggOnlyState {
                        eggStageCard
                    } else {
                        let renderState = store.pixelRenderState(for: store.featuredCompanion)
                        PhoneRewardStagePanel(
                            pet: store.pet,
                            target: store.evolutionTarget,
                            progress: store.evolutionProgress,
                            activeEffects: store.activeWeeklyEffects,
                            season: store.weeklyBoard.season,
                            claimableReward: store.claimableWeeklyReward,
                            onClaim: store.claimableWeeklyReward == nil ? nil : { store.claimWeeklyReward() },
                            renderState: renderState,
                            seasonalLayers: store.seasonalLayers
                        )
                    }
                    if store.hatchInsights.isEmpty == false {
                        PhoneHatchInsightPanel(
                            insights: store.hatchInsights,
                            target: store.evolutionTarget,
                            accent: store.mainAccentColor
                        )
                    }
                    questCard
                }
                .padding(20)
            }
        }
    }

    private var worldFrontierCard: some View {
        GameSurface(title: "활성 세계", accent: store.mainAccentColor, eyebrow: "활성 지역") {
            VStack(alignment: .leading, spacing: 12) {
                Text(worldPack.contentPack.playerFacingTheme)
                    .font(.headline.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.darkest)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    TraitChip(label: "팩 \(worldPackSummaries.count)", accent: store.mainAccentColor)
                    TraitChip(label: "구역 \(worldPack.regions.count)", accent: .cyan.opacity(0.28))
                    TraitChip(label: "시즌 \(worldPack.seasons.count)", accent: .mint.opacity(0.28))
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(worldPackSummaries.prefix(3), id: \.packID) { summary in
                        HStack(spacing: 8) {
                            Image(systemName: store.activeWorldPackIDs.contains(summary.packID) ? "checkmark.circle.fill" : "circle")
                                .font(.caption.weight(.black))
                                .foregroundStyle(store.activeWorldPackIDs.contains(summary.packID) ? store.mainAccentColor : GameBoyPalette.mediumDark)
                            Text(summary.title)
                                .font(.subheadline.monospaced().weight(.black))
                                .foregroundStyle(GameBoyPalette.darkest)
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Text(summary.type.uppercased())
                                .font(.caption2.monospaced().weight(.black))
                                .foregroundStyle(GameBoyPalette.mediumDark)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
    }

    private var headerDeck: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("오늘의 동행 루프")
                .font(.caption.monospaced().weight(.black))
                .tracking(1.4)
                .foregroundStyle(GameBoyPalette.mediumDark)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(store.mainSelectionLabel)
                        .font(.system(size: 30, weight: .black, design: .monospaced))
                        .foregroundStyle(GameBoyPalette.darkest)
                    Text(store.mainSelectionDetail)
                        .font(.footnote.monospaced())
                        .foregroundStyle(GameBoyPalette.mediumDark)
                        .lineLimit(2)
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 6) {
                    TraitChip(label: store.weeklyBoard.season.title, accent: store.mainAccentColor)
                    TraitChip(label: store.mainSelection?.kind == .egg ? "지금 선택한 알" : "지금 선택한 동행", accent: .white.opacity(0.16))
                }
            }

            Text("달린 기록은 알과 성장 자원이 되고, 지금 선택한 동행은 그 결과를 살아 있는 존재처럼 보여 줍니다.")
                .font(.footnote.monospaced())
                .foregroundStyle(GameBoyPalette.mediumDark)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var fantasyPulseCard: some View {
        GameSurface(title: "러닝이 생명이 되는 순간", accent: store.mainAccentColor, eyebrow: "RUNIMAL V1") {
            VStack(alignment: .leading, spacing: 14) {
                Text("첫 러닝은 첫 알, 둘째 러닝은 첫 부화, 첫 의미 있는 먹이 주기는 첫 성장으로 바로 읽혀야 합니다.")
                    .font(.headline.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.darkest)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    ritualColumn(
                        title: "러닝 중",
                        detail: "Apple Watch에서 실시간 동행과 리듬을 확인"
                    )
                    ritualColumn(
                        title: "러닝 후",
                        detail: "iPhone에서 기록을 알, 부화, 성장 보상으로 전환"
                    )
                }
            }
        }
    }

    private var heroCard: some View {
        GameSurface(accent: store.mainAccentColor, eyebrow: store.mainSelection?.kind == .egg ? "지금 선택한 알" : "지금 선택한 동행") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(store.mainAccentColor.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .stroke(store.mainAccentColor.opacity(0.26), lineWidth: 1.4)
                            )

                        Circle()
                            .fill(store.mainAccentColor.opacity(0.18))
                            .frame(width: 90, height: 90)
                            .blur(radius: 16)

                        if store.mainSelection?.kind == .egg {
                            TraceEggView(
                                accent: store.mainAccentColor,
                                shell: store.mainEgg?.shell,
                                pixelSize: 12,
                                cracked: store.mainEgg?.readyToHatch == true,
                                resonance: store.mainEggResonance
                            )
                        } else {
                            let renderState = store.pixelRenderState(for: store.featuredCompanion)
                            PixelPetView(
                                pet: store.pet,
                                pixelSize: 12,
                                growthStageIndex: renderState.growthStageIndex,
                                mutationForm: renderState.mutationForm,
                                mutationHistory: renderState.mutationHistory,
                                mutationVisualState: renderState.mutationVisualState,
                                seasonalLayers: store.seasonalLayers
                            )
                        }
                    }
                    .frame(width: 132, height: 140)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            TraitChip(
                                label: "\(store.featuredCompanionDistanceKm.formatted(.number.precision(.fractionLength(1)))) km",
                                accent: store.mainAccentColor
                            )
                            TraitChip(
                                label: store.featuredCompanionCadence.map { "\($0) spm" } ?? "-- spm",
                                accent: GameBoyPalette.mediumLight
                            )
                            TraitChip(
                                label: store.mainSelection?.kind == .egg ? (store.mainEgg?.shell.displayLabel ?? "숨김 알") : store.evolutionProgress.stageLabel,
                                accent: GameBoyPalette.mediumLight
                            )
                        }

                        RunimalProgressBar(
                            progress: store.mainSelection?.kind == .egg ? (store.mainEgg?.progressRatio ?? 0) : store.evolutionProgress.progressRatio,
                            accent: store.mainAccentColor,
                            height: 8
                        )

                        RunimalSignalBadge(
                            icon: "sparkles",
                            label: store.featuredCompanionSignalLabel,
                            accent: store.mainAccentColor
                        )

                        if let form = store.mutationForm(for: store.featuredCompanion),
                           store.mainSelection?.kind != .egg {
                            Text(form.displayTitle)
                                .font(.caption.monospaced().weight(.black))
                                .foregroundStyle(GameBoyPalette.mediumDark)
                                .lineLimit(1)
                                .minimumScaleFactor(0.82)
                        }

                        Text(heroMomentDetail)
                            .font(.caption.monospaced().weight(.black))
                            .foregroundStyle(store.mainAccentColor.opacity(0.94))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 10) {
                    statPillar(title: "XP", value: "\(store.evolutionProgress.totalExperience)")
                    statPillar(title: "단계", value: store.evolutionProgress.stageLabel)
                    statPillar(title: "시즌", value: store.weeklyBoard.season.title)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        RunimalSignalBadge(
                            icon: store.mainSelection?.kind == .egg ? "sparkles" : "figure.run",
                            label: heroMomentTitle,
                            accent: store.mainAccentColor
                        )
                        Spacer(minLength: 8)
                        TraitChip(label: store.mainSelection?.kind == .egg ? "부화 루프" : "성장 루프", accent: .white.opacity(0.18))
                    }

                    Text(heroMomentSupport)
                        .font(.footnote.monospaced())
                        .foregroundStyle(GameBoyPalette.mediumDark)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let egg = store.mainEgg, store.mainSelection?.kind == .egg {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("알 상태")
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
                                    .foregroundStyle(GameBoyPalette.mediumDark)
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
                            TraitChip(label: "받기 가능", accent: .green.opacity(0.72))
                        }

                        Text(nextReward.title)
                            .font(.headline.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.darkest)
                        Text(nextReward.detail)
                            .font(.footnote.monospaced())
                            .foregroundStyle(GameBoyPalette.mediumDark)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(GameBoyPalette.mediumLight.opacity(0.16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(GameBoyPalette.darkest.opacity(0.22), lineWidth: 1)
                            )
                    )
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("핵심 미션")
                            .font(.headline.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.darkest)
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
                                    .font(.subheadline.monospaced().weight(.black))
                                    .foregroundStyle(GameBoyPalette.darkest)
                                Spacer()
                                TraitChip(
                                    label: mission.completed ? "완료" : mission.progressLabel,
                                    accent: mission.completed ? .green : GameBoyPalette.mediumLight
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

    private var eggStageCard: some View {
        GameSurface(title: "알 상태", accent: store.mainAccentColor, eyebrow: "지금 상태") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 16) {
                    TraceEggView(
                        accent: store.mainAccentColor,
                        shell: store.mainEgg?.shell,
                        pixelSize: 10,
                        cracked: store.mainEgg?.readyToHatch == true,
                        resonance: store.mainEggResonance
                    )
                    .frame(width: 108, height: 108)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(store.mainAccentColor.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(store.mainAccentColor.opacity(0.22), lineWidth: 1)
                            )
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text(store.mainEgg?.readyToHatch == true ? "부화 준비 완료" : "부화 준비 중")
                            .font(.title2.weight(.black))
                            .foregroundStyle(GameBoyPalette.darkest)

                        Text(store.mainEgg?.shell.displayLabel ?? "숨김 알")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(store.mainAccentColor.opacity(0.94))

                        Text(store.mainSelectionDetail)
                            .font(.footnote)
                            .foregroundStyle(GameBoyPalette.mediumDark)
                            .lineLimit(2)

                        HStack(spacing: 8) {
                            RunimalSignalBadge(
                                icon: store.mainEgg?.readyToHatch == true ? "sparkles" : "shield.lefthalf.filled",
                                label: store.mainEgg?.readyToHatch == true ? "바로 부화 가능" : "알만 보유 중",
                                accent: store.mainAccentColor
                            )
                            TraitChip(label: store.weeklyBoard.season.title, accent: .white.opacity(0.22))
                        }
                    }
                }

                RunimalProgressBar(
                    progress: store.mainEgg?.progressRatio ?? 0,
                    accent: store.mainAccentColor,
                    height: 10
                )

                HStack(spacing: 12) {
                    RunimalMetricTile(
                        icon: "sparkles",
                        title: "알",
                        value: "\(store.eggInventory.count)",
                        accent: .mint
                    )
                    RunimalMetricTile(
                        icon: "shippingbox.fill",
                        title: "운동 기록",
                        value: "\(store.availableRunCores.count)",
                        accent: store.mainAccentColor
                    )
                    RunimalMetricTile(
                        icon: "figure.run",
                        title: "실제 러닝",
                        value: "\(store.actualCompletedRuns.count)",
                        accent: .green
                    )
                }
            }
        }
    }

    private func statPillar(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.monospaced().weight(.black))
                .tracking(1.1)
                .foregroundStyle(GameBoyPalette.mediumDark)
            Text(value)
                .font(.subheadline.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.darkest)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(GameBoyPalette.mediumLight.opacity(0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(GameBoyPalette.darkest.opacity(0.22), lineWidth: 1)
                )
        )
    }

    private func ritualColumn(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.monospaced().weight(.black))
                .tracking(1.2)
                .foregroundStyle(store.mainAccentColor.opacity(0.92))
            Text(detail)
                .font(.caption.monospaced())
                .foregroundStyle(GameBoyPalette.mediumDark)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(GameBoyPalette.mediumLight.opacity(0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(GameBoyPalette.darkest.opacity(0.18), lineWidth: 1)
                )
        )
    }

    private var heroMomentTitle: String {
        if store.mainSelection?.kind == .egg {
            return store.mainEgg?.readyToHatch == true ? "둘째 러닝 보상 도착" : "첫 알 부화 준비"
        }
        return store.hasUnlockedNonTraceStage ? "성장 결과 반영" : "첫 성장 보장 구간"
    }

    private var heroMomentDetail: String {
        if store.mainSelection?.kind == .egg {
            return store.mainEgg?.readyToHatch == true ? "이제 바로 깨워서 첫 동행을 확보할 수 있습니다." : "운동 기록은 알의 공명도와 부화 준비도를 밀어 올립니다."
        }
        return store.hasUnlockedNonTraceStage
            ? "실시간 동행은 워치에서, 성장 반영과 수집은 아이폰에서 분명하게 나눕니다."
            : "첫 의미 있는 보상은 반드시 눈에 띄는 성장으로 이어져야 합니다."
    }

    private var heroMomentSupport: String {
        if store.mainSelection?.kind == .egg {
            return "운동 기록은 그대로 남기고, 알 화면에서는 생성과 부화 상태만 또렷하게 보여 줍니다."
        }
        return "이번 허브 화면은 현재 동행, 다음 성장 목표, 그리고 시즌 보상을 한 번에 읽는 데 집중합니다."
    }
}
