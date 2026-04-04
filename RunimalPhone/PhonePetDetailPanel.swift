import RunimalCore
import SwiftUI

struct PhonePetDetailPanel: View {
    let companion: PetCollectionEntry
    let mutationForm: MutationFormSnapshot?
    let mutationHistory: MutationHistorySnapshot?
    let mutationVisualState: MutationVisualState?
    let growthStageIndex: Int
    let mutationEvidence: MutationEvidenceSnapshot?
    let worldProfile: CompanionWorldProfile?
    let speciesIdentity: SpeciesBibleEntry?
    let variantNarrative: VariantNarrativeEntry?
    let worldStatus: CompanionWorldStatus?
    let narrativeSummary: CompanionNarrativeSummary?
    let nextEpisodeFocus: EpisodeNarrativeFocus?
    let progress: EvolutionProgress
    let activeEffects: [WeeklyRewardEffect]
    let season: WeeklySeason
    @State private var showMutationDetails = false

    private var effectResonance: [CompanionEffectResonance] {
        RunimalEffectResonanceEngine.effectResonance(
            for: companion,
            progress: progress,
            activeEffects: activeEffects
        )
    }

    private var progressionSnapshot: CompanionProgressionSnapshot {
        let growthRecord = CompanionGrowthRecord(
            companionID: companion.id,
            totalExperience: progress.totalExperience,
            feedCount: 0,
            assignedRunIDs: [],
            lastFedAt: nil
        )
        return RunimalCompanionGrowthEngine.progressionSnapshot(for: growthRecord, species: companion.pet.species)
    }

    private var lateGrowthFeatures: CompanionLateGrowthFeatures {
        progressionSnapshot.lateGrowthFeatures
    }

    private var growthToneLines: [String] {
        var lines: [String] = []
        if let hook = worldProfile?.hookLine { lines.append(hook) }
        if let variantNarrative {
            lines.append("\(variantNarrative.playerFacingName) 기운이 남아 있어요.")
        } else if RunimalGameEngine.seasonAffinity(for: companion.pet, season: season) {
            lines.append("\(season.title) 시즌 흐름과 잘 맞아요.")
        }
        return Array(lines.prefix(2))
    }

    private var baseVisualBlueprint: BaseSpeciesVisualBlueprint? {
        DefaultSpeciesVisualBlueprints.baseAnatomy(for: companion.pet.species)
    }

    var body: some View {
        GameSurface(title: "동행 정보") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 16) {
                    PixelPetView(
                        pet: companion.pet,
                        pixelSize: 10,
                        growthStageIndex: growthStageIndex,
                        mutationForm: mutationForm,
                        mutationHistory: mutationHistory,
                        mutationVisualState: mutationVisualState
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text(companion.pet.displayName)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(companion.pet.species.codename)
                            .font(.caption2.monospaced().weight(.semibold))
                            .foregroundStyle(.white.opacity(0.52))
                        Text(companion.pet.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.72))
                        if let mutationForm {
                            Text(mutationForm.displayTitle)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(companion.pet.accentColor.opacity(0.92))
                        }
                        HStack {
                            TraitChip(label: "Lv.\(companion.level)", accent: companion.pet.accentColor)
                            TraitChip(label: "유대 \(companion.bond)", accent: .white.opacity(0.22))
                            if RunimalGameEngine.seasonAffinity(for: companion.pet, season: season) {
                                TraitChip(label: season.title, accent: .mint.opacity(0.7))
                            }
                        }
                    }
                }

                if let speciesIdentity {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("종족 기질")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("\(speciesIdentity.displayName) · \(companion.pet.species.codename)")
                            .font(.caption2.monospaced().weight(.semibold))
                            .foregroundStyle(companion.pet.accentColor.opacity(0.86))
                        Text(speciesIdentity.fantasy)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.76))
                            .lineSpacing(3)
                        HStack(spacing: 6) {
                            TraitChip(label: reactionSummary(speciesIdentity.metricBias), accent: companion.pet.accentColor.opacity(0.26))
                            TraitChip(label: habitatSummary(speciesIdentity.habitatTags), accent: .white.opacity(0.14))
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(speciesIdentity.visualKeywords.prefix(3), id: \.self) { keyword in
                                    TraitChip(label: localizedKeyword(keyword), accent: .mint.opacity(0.24))
                                }
                            }
                        }
                        if speciesIdentity.narrativeHooks.isEmpty == false {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(Array(speciesIdentity.narrativeHooks.prefix(3)), id: \.self) { hook in
                                    Text("• \(hook)")
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.54))
                                        .lineSpacing(3)
                                }
                            }
                        }
                    }
                }

                if let baseVisualBlueprint {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("기본형 틀")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(baseVisualBlueprint.silhouetteLine)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.76))
                            .lineSpacing(3)
                        Text(baseVisualBlueprint.identityLine)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.56))
                            .lineSpacing(3)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(baseVisualBlueprint.signatureParts) { part in
                                    TraitChip(label: part.title, accent: companion.pet.accentColor.opacity(0.22))
                                }
                            }
                        }
                    }
                }

                if let variantNarrative {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("특별한 진화")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(variantNarrative.playerFacingName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(companion.pet.accentColor.opacity(0.92))
                        Text(variantNarrative.narrativeMeaning)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.74))
                            .lineSpacing(3)
                        Text(variantNarrative.triggerHint)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.52))
                    }
                } else if companion.pet.species == .shadebit, let worldProfile {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("황혼 특수형")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        HStack(spacing: 6) {
                            TraitChip(label: "기반 신더래시", accent: companion.pet.accentColor.opacity(0.22))
                            TraitChip(label: "던스프리그 황혼 분기", accent: .white.opacity(0.14))
                        }
                        Text(worldProfile.fantasyLine)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.74))
                            .lineSpacing(3)
                        Text(worldProfile.hookLine)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.52))
                            .lineSpacing(3)
                    }
                }

                if let mutationHistory {
                    DisclosureGroup(isExpanded: $showMutationDetails) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(mutationHistory.latestUnlockedDisplayTitle)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(companion.pet.accentColor.opacity(0.92))

                            ForEach(mutationHistory.axes) { axis in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Text(axisTitle(axis.axis))
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.white.opacity(0.74))
                                        TraitChip(label: axis.currentTitle, accent: companion.pet.accentColor.opacity(0.82))
                                        Spacer()
                                        Text(progressLabel(axis.currentProgress))
                                            .font(.caption2.monospacedDigit().weight(.semibold))
                                            .foregroundStyle(.white.opacity(0.54))
                                    }

                                    ProgressView(value: axis.currentProgress)
                                        .tint(companion.pet.accentColor.opacity(0.82))
                                        .background(.white.opacity(0.08))

                                    HStack(spacing: 8) {
                                        Text("누적")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(.white.opacity(0.45))
                                        Text("\(axis.currentScore)pt")
                                            .font(.caption2.monospacedDigit())
                                            .foregroundStyle(.white.opacity(0.54))
                                    }

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 6) {
                                            ForEach(axis.branches) { branch in
                                                TraitChip(
                                                    label: branch.title,
                                                    accent: branchAccent(
                                                        branch: branch
                                                    )
                                                )
                                            }
                                        }
                                    }

                                    if let lockedBranch = nextLockedBranch(
                                        for: axis.axis,
                                        speciesID: mutationHistory.speciesID,
                                        unlockedBranchIDs: axis.unlockedBranchIDs
                                    ) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "lock.fill")
                                                .font(.caption2)
                                                .foregroundStyle(.white.opacity(0.45))
                                            Text(lockedBranch.unlockCue)
                                                .font(.caption2)
                                                .foregroundStyle(.white.opacity(0.52))
                                                .lineLimit(1)
                                        }
                                    }

                                    mutationAnatomyRow(axis: axis)
                                }
                            }
                        }
                        .padding(.top, 8)
                    } label: {
                        HStack {
                            Text("변이 계보")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Spacer()
                            Text(showMutationDetails ? "접기" : "보기")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .tint(.white)
                }

                if let worldStatus {
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 8) {
                            worldRow(label: "구역", value: worldStatus.regionTitle)
                            if let seasonTitle = worldStatus.seasonTitle {
                                worldRow(label: "시즌", value: seasonTitle)
                            }
                            if let episodeTitle = worldStatus.episodeTitle {
                                worldRow(label: "에피소드", value: episodeTitle)
                            }
                            HStack(spacing: 8) {
                                TraitChip(label: "구역 \(worldStatus.unlockedRegionCount)", accent: companion.pet.accentColor.opacity(0.72))
                                TraitChip(label: "에피소드 \(worldStatus.unlockedEpisodeCount)", accent: .mint.opacity(0.3))
                            }
                        }
                        .padding(.top, 8)
                    } label: {
                        HStack {
                            Text("세계 진행")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Spacer()
                            Text(worldStatus.regionTitle)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.58))
                                .lineLimit(1)
                        }
                    }
                    .tint(.white)
                }

                if let narrativeSummary {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("동행 기록")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)

                        narrativeLine(narrativeSummary.originLine)
                        narrativeLine(narrativeSummary.recentLine)
                        narrativeLine(narrativeSummary.trajectoryLine)

                        if let nextEpisodeFocus {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("다음 장면")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.74))
                                    Spacer()
                                    TraitChip(label: nextEpisodeFocus.progressLabel, accent: companion.pet.accentColor.opacity(0.82))
                                }

                                Text(nextEpisodeFocus.title)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.76))
                                    .lineSpacing(3)

                                ProgressView(value: nextEpisodeFocus.progress)
                                    .tint(companion.pet.accentColor.opacity(0.82))
                                    .background(.white.opacity(0.08))

                                Text(nextEpisodeFocus.detail)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.52))
                                    .lineSpacing(3)
                            }
                            .padding(.top, 4)
                        }
                    }
                }

                PhonePetGrowthJourneyPanel(
                    companion: companion,
                    mutationForm: mutationForm,
                    mutationHistory: mutationHistory,
                    progress: progress,
                    season: season,
                    toneLines: growthToneLines
                )

                if companion.level >= 31 {
                    Divider()
                        .overlay(.white.opacity(0.12))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("성년기 이후 해금")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)

                        Text(lateGrowthSummaryLine())
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                            .lineSpacing(3)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(lateGrowthFeatureBadges(), id: \.self) { badge in
                                    TraitChip(label: badge, accent: companion.pet.accentColor.opacity(0.2))
                                }
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
            }
        }
    }

    private func axisTitle(_ axis: SpeciesLineageAxis) -> String {
        switch axis {
        case .body:
            return "체형"
        case .ecology:
            return "생태"
        case .rhythm:
            return "리듬"
        }
    }

    private func branchAccent(branch: MutationBranchProgressSnapshot) -> Color {
        if branch.isCurrent {
            return companion.pet.accentColor.opacity(0.82)
        }
        if branch.isUnlocked {
            return .white.opacity(0.18)
        }
        return .white.opacity(0.08)
    }

    private func nextLockedBranch(for axis: SpeciesLineageAxis, speciesID: String, unlockedBranchIDs: [String]) -> SpeciesLineageBranchBlueprint? {
        guard let blueprint = DefaultSpeciesExpansionBlueprints.baseSpeciesBlueprints.first(where: { $0.speciesID == speciesID }) else {
            return nil
        }
        let branches: [SpeciesLineageBranchBlueprint]
        switch axis {
        case .body:
            branches = blueprint.bodyBranches
        case .ecology:
            branches = blueprint.ecologyBranches
        case .rhythm:
            branches = blueprint.rhythmBranches
        }
        return branches.first(where: { unlockedBranchIDs.contains($0.id) == false })
    }

    private func progressLabel(_ progress: Double) -> String {
        "\(Int((progress * 100).rounded()))%"
    }

    private func worldRow(label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.76))
                .lineLimit(2)
        }
    }

    private func narrativeLine(_ line: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(companion.pet.accentColor.opacity(0.82))
                .frame(width: 5, height: 5)
                .padding(.top, 5)

            Text(line)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.74))
                .lineSpacing(3)
        }
    }

    private func mutationAnatomyRow(axis: MutationAxisHistory) -> some View {
        let anatomy = DefaultSpeciesVisualBlueprints.anatomy(for: axis.currentBranchID)
        let evidence = mutationEvidence?.evidence(for: axis.axis)
        let bridge = SpeciesGrowthMutationBridgeEngine.bridge(
            for: companion.pet.species,
            axis: axis.axis,
            branchID: axis.currentBranchID
        )
        let partIDs = Set(anatomy?.affectedParts.map(\.id) ?? [])
        let tint = axisTint(axis.axis)
        return VStack(alignment: .leading, spacing: 6) {
            if partIDs.isEmpty == false {
                VStack(spacing: 5) {
                    HStack(spacing: 6) {
                        miniPartSlot("머리", icon: "crown.fill", active: partIDs.contains("head-crest") || partIDs.contains("eye-signal"), tint: tint)
                        miniPartSlot("상체", icon: "shield.fill", active: partIDs.contains("upper-silhouette") || partIDs.contains("shoulder-line"), tint: tint)
                        miniPartSlot("등", icon: "square.stack.3d.up.fill", active: partIDs.contains("back-shell"), tint: tint)
                    }
                    HStack(spacing: 6) {
                        miniPartSlot("측면", icon: "wind", active: partIDs.contains("wing-line") || partIDs.contains("outer-markings"), tint: tint)
                        miniPartSlot("코어", icon: "sparkles", active: partIDs.contains("core-glow"), tint: tint)
                        miniPartSlot("꼬리", icon: "waveform.path", active: partIDs.contains("tail-wave") || partIDs.contains("motion-trail"), tint: tint)
                    }
                }
            }
            if let bridge {
                HStack(spacing: 6) {
                    TraitChip(label: bridge.startStageTitle, accent: tint.opacity(0.22))
                    Text("부터 갈래가 바뀌어요")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.54))
                }
                if bridge.inheritedParts.isEmpty == false {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(bridge.inheritedParts) { part in
                                TraitChip(label: part.title, accent: .mint.opacity(0.22))
                            }
                            ForEach(bridge.redirectedParts) { part in
                                TraitChip(label: part.title, accent: tint.opacity(0.18))
                            }
                        }
                    }
                }
            }
            if let anatomy {
                Text(anatomy.developmentLine)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.66))
                    .lineLimit(2)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(anatomy.affectedParts) { part in
                            TraitChip(
                                label: part.title,
                                accent: tint.opacity(axis.currentProgress > 0.66 ? 0.72 : 0.24)
                            )
                        }
                    }
                }
            }
            if let evidence {
                VStack(alignment: .leading, spacing: 3) {
                    Text("누적: \(evidence.aggregateReason)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.54))
                        .lineLimit(2)
                    if let recentReason = evidence.recentReason {
                        Text("최근: \(recentReason)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                            .lineLimit(2)
                    }
                }
            }
        }
        .padding(.top, 2)
    }

    private func axisTint(_ axis: SpeciesLineageAxis) -> Color {
        switch axis { case .body: .orange; case .ecology: .mint; case .rhythm: .cyan }
    }

    private func miniPartSlot(_ title: String, icon: String, active: Bool, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2.weight(.bold))
            Text(title).font(.caption2.weight(.semibold))
        }
            .foregroundStyle(active ? .white : .white.opacity(0.34))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(active ? tint.opacity(0.28) : .white.opacity(0.05)))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(active ? tint.opacity(0.56) : .white.opacity(0.08), lineWidth: 1))
    }

    private func habitatSummary(_ tags: [String]) -> String {
        tags.prefix(2).map(localizedHabitatTag).joined(separator: " · ")
    }

    private func reactionSummary(_ bias: MetricBiasProfile) -> String {
        let tags = [
            bias.distance == "high" ? "장거리" : nil,
            bias.paceStability == "high" ? "안정 페이스" : nil,
            bias.cadence == "high" ? "빠른 리듬" : nil,
            bias.elevation == "high" ? "오르막" : nil,
            bias.nightAffinity == "high" ? "야간" : nil,
            bias.routeComplexity == "high" ? "복잡한 경로" : nil
        ].compactMap { $0 }
        return tags.prefix(2).joined(separator: " · ")
    }

    private func localizedKeyword(_ keyword: String) -> String {
        switch keyword {
        case "wind-line": return "바람 결"
        case "feather-tail": return "깃 꼬리"
        case "open-sky": return "개활 실루엣"
        case "ridge-shell": return "능선 등갑"
        case "stone-core": return "암석 코어"
        case "heavy-step": return "묵직한 보폭"
        case "spark-fang": return "스파크 송곳니"
        case "neon-tail": return "네온 꼬리"
        case "tempo-flare": return "템포 잔광"
        case "moss-coat": return "이끼 외피"
        case "petal-aura": return "꽃잎 기운"
        case "rain-glow": return "빗결 광"
        case "bud-core": return "싹 코어"
        case "soft-shell": return "부드러운 갑피"
        case "trail-seed": return "씨앗 꼬리"
        default: return keyword
        }
    }

    private func localizedHabitatTag(_ tag: String) -> String {
        switch tag {
        case "urban": return "도심"
        case "riverside": return "강변"
        case "open-path": return "개활지"
        case "ridge": return "능선"
        case "stairs": return "계단"
        case "rock": return "암석 지대"
        case "city": return "시가지"
        case "sprint-lane": return "질주 코스"
        case "signal-zone": return "신호 지대"
        case "forest": return "숲길"
        case "park": return "공원"
        case "rain-trail": return "비길"
        case "night": return "야간"
        case "alley": return "골목"
        case "tunnel": return "터널"
        case "starter": return "입문 구간"
        case "garden": return "정원"
        default: return tag
        }
    }

    private func lateGrowthFeatureBadges() -> [String] {
        var badges = ["기록 태그 \(lateGrowthFeatures.insightLabelLimit)개"]

        if lateGrowthFeatures.potentialSpendCapBonus > 0 {
            badges.append("잠재 저장 \(lateGrowthFeatures.storedPotentialCap)")
            badges.append("잠재 사용 상한 +\(lateGrowthFeatures.potentialSpendCapBonus)")
        }

        if lateGrowthFeatures.seasonRecordEcho {
            badges.append("시즌 기록 보관")
        }

        if lateGrowthFeatures.preservesWorldSignals {
            badges.append("이야기 표식 보관")
        }

        if lateGrowthFeatures.completedRecordMark {
            badges.append("완성 기록 보관")
        }

        return badges
    }

    private func lateGrowthSummaryLine() -> String {
        if lateGrowthFeatures.completedRecordMark {
            return "풍부한 기록을 더 오래 보관하고, 후반부 잠재 운용 폭도 가장 넓게 열려 있습니다."
        }
        if lateGrowthFeatures.preservesWorldSignals {
            return "이제부터는 구역과 에피소드 신호도 이 동행의 기록으로 함께 남습니다."
        }
        if lateGrowthFeatures.seasonRecordEcho {
            return "시즌과 맞는 러닝을 먹이면 후반부 기록 보관과 반응이 더 또렷하게 남습니다."
        }
        if lateGrowthFeatures.potentialSpendCapBonus > 0 {
            return "잠재 저장 한도가 늘었고, 한 번에 꺼내 쓰는 폭도 더 커졌습니다."
        }
        return "풍부한 운동 기록의 태그를 더 많이 읽고, 후반부 기록으로 보관하기 시작합니다."
    }
}
