import Foundation
import RunimalCore

struct CompanionArchiveEntry: Identifiable {
    let companion: PetCollectionEntry
    let retired: Bool
    let preview: Bool

    var id: String { companion.id }
}

struct CompanionWorldStatus {
    let regionTitle: String
    let seasonTitle: String?
    let episodeTitle: String?
    let unlockedRegionCount: Int
    let unlockedEpisodeCount: Int
}

struct CompanionNarrativeSummary {
    let originLine: String
    let recentLine: String
    let trajectoryLine: String
}

struct EpisodeNarrativeFocus {
    let title: String
    let detail: String
    let progress: Double
    let progressLabel: String
}

struct RunNarrativeBeat {
    let title: String
    let detail: String
    let badges: [String]
}

struct CompanionPixelRenderState {
    let growthStageIndex: Int
    let mutationForm: MutationFormSnapshot?
    let mutationHistory: MutationHistorySnapshot?
    let mutationVisualState: MutationVisualState
}

@MainActor
extension PhoneDashboardStore {
    var companionArchive: [CompanionArchiveEntry] {
        progress.ownedCompanions.map { companion in
            let effectiveCompanion = RunimalCompanionGrowthEngine.effectiveCompanion(
                from: companion,
                growthRecord: progress.growthRecord(for: companion.id)
            )

            return CompanionArchiveEntry(
                companion: effectiveCompanion,
                retired: progress.retiredCompanionIDs.contains(companion.id),
                preview: false
            )
        }
    }

    var archivePreviewEntries: [CompanionArchiveEntry] {
        let representedSpecies = Set(companionArchive.map { $0.companion.pet.species })
        let previewSpecies: [PetSpecies] = [.windrunner, .stoneback, .sparkfang, .mosshop, .seedle]

        return previewSpecies.compactMap { species in
            guard representedSpecies.contains(species) == false else { return nil }
            return CompanionArchiveEntry(
                companion: previewCompanion(for: species),
                retired: false,
                preview: true
            )
        }
    }

    var activeInventoryCompanionCount: Int {
        collection.count
    }

    var archivedCompanionCount: Int {
        companionArchive.filter(\.retired).count
    }

    func narrativeBeat(for run: CompletedRunRecord) -> RunNarrativeBeat? {
        guard let impact = run.worldImpact else {
            guard let worldProfile = contentCatalog.runWorldProfile(for: run) else { return nil }
            return RunNarrativeBeat(
                title: "세계 반응",
                detail: worldProfile.summaryLine,
                badges: [worldProfile.regionTitle]
            )
        }

        let worldProfile = contentCatalog.runWorldProfile(for: run)
        let title: String
        let detail: String

        if impact.unlockedEpisode, let episodeTitle = impact.episodeTitle {
            title = "새 에피소드"
            detail = episodeTitle
        } else if impact.unlockedRegion {
            title = "새 구역 감지"
            detail = "\(impact.regionTitle) 구역이 이번 러닝에 반응하며 세계 지도에 새로운 흔적이 추가됐어요."
        } else if impact.unlockedSeason, let seasonTitle = impact.seasonTitle {
            title = "시즌 공명"
            detail = "\(seasonTitle) 시즌 흐름이 \(impact.regionTitle) 구역과 맞물리며 서사가 한 단계 진전됐어요."
        } else if let episodeTitle = impact.episodeTitle {
            title = "이야기 신호"
            detail = episodeTitle
        } else {
            title = "세계 반응"
            detail = worldProfile?.summaryLine ?? "\(impact.regionTitle) 구역이 이번 러닝의 흔적을 기록했어요."
        }

        var badges = [impact.regionTitle]
        if let seasonTitle = impact.seasonTitle {
            badges.append(seasonTitle)
        }
        if impact.unlockedEpisode {
            badges.append("에피소드 개방")
        } else if impact.unlockedRegion {
            badges.append("구역 개방")
        }

        return RunNarrativeBeat(title: title, detail: detail, badges: Array(badges.prefix(3)))
    }

    func mutationForm(for companion: PetCollectionEntry) -> MutationFormSnapshot? {
        guard let growthRecord = progress.growthRecord(for: companion.id) else { return nil }

        let runs = progress.completedRuns
            .filter { growthRecord.assignedRunIDs.contains($0.id) }
            .sorted { $0.endedAt < $1.endedAt }

        guard runs.isEmpty == false else { return nil }
        return SpeciesMutationUnlockEngine.resolveForm(
            for: runs,
            preferredSpecies: companion.pet.species
        )?.snapshot
    }

    func mutationHistory(for companion: PetCollectionEntry) -> MutationHistorySnapshot? {
        guard let growthRecord = progress.growthRecord(for: companion.id) else { return nil }

        let runs = progress.completedRuns
            .filter { growthRecord.assignedRunIDs.contains($0.id) }
            .sorted { $0.endedAt < $1.endedAt }

        guard runs.isEmpty == false else { return nil }
        return SpeciesMutationHistoryEngine.history(
            for: runs,
            preferredSpecies: companion.pet.species
        )
    }

    func mutationEvidence(for companion: PetCollectionEntry) -> MutationEvidenceSnapshot? {
        guard let growthRecord = progress.growthRecord(for: companion.id) else { return nil }

        let runs = progress.completedRuns
            .filter { growthRecord.assignedRunIDs.contains($0.id) }
            .sorted { $0.endedAt < $1.endedAt }

        guard runs.isEmpty == false else { return nil }
        return SpeciesMutationEvidenceEngine.evidence(
            for: runs,
            preferredSpecies: companion.pet.species
        )
    }

    func pixelRenderState(for companion: PetCollectionEntry) -> CompanionPixelRenderState {
        let growthStageIndex = growthStageIndex(for: companion)
        let mutationIdentityAllowed = MutationVisualEvolutionEngine.allowsMutationIdentity(
            growthStageIndex: growthStageIndex
        )
        let mutationForm = mutationIdentityAllowed ? mutationForm(for: companion) : nil
        let mutationHistory = mutationIdentityAllowed ? mutationHistory(for: companion) : nil
        let rawMutationVisualState = MutationVisualEvolutionEngine.state(
            for: mutationHistory,
            fallbackForm: mutationForm
        )
        let mutationVisualState = MutationVisualEvolutionEngine.visibleState(
            for: rawMutationVisualState,
            growthStageIndex: growthStageIndex
        )

        return CompanionPixelRenderState(
            growthStageIndex: growthStageIndex,
            mutationForm: mutationForm,
            mutationHistory: mutationHistory,
            mutationVisualState: mutationVisualState
        )
    }

    func pixelRenderState(for entry: CompanionArchiveEntry) -> CompanionPixelRenderState {
        if entry.preview {
            return CompanionPixelRenderState(
                growthStageIndex: 1,
                mutationForm: nil,
                mutationHistory: nil,
                mutationVisualState: .none
            )
        }

        return pixelRenderState(for: entry.companion)
    }

    func worldProfile(for companion: PetCollectionEntry) -> CompanionWorldProfile? {
        contentCatalog.companionWorldProfile(for: companion.pet)
    }

    func speciesIdentity(for companion: PetCollectionEntry) -> SpeciesBibleEntry? {
        contentCatalog.speciesBibleEntry(for: companion.pet)
    }

    func variantNarrative(for companion: PetCollectionEntry) -> VariantNarrativeEntry? {
        contentCatalog.variantNarrative(for: companion.pet)
    }

    func worldStatus(for companion: PetCollectionEntry) -> CompanionWorldStatus? {
        let runs = assignedRuns(for: companion)
        guard let latestImpact = runs.compactMap(\.worldImpact).last else { return nil }
        return CompanionWorldStatus(
            regionTitle: latestImpact.regionTitle,
            seasonTitle: latestImpact.seasonTitle,
            episodeTitle: latestImpact.episodeTitle,
            unlockedRegionCount: progress.worldProgressSnapshot.regions.count,
            unlockedEpisodeCount: progress.worldProgressSnapshot.episodes.filter { $0.unlockedAt != nil }.count
        )
    }

    func narrativeSummary(for companion: PetCollectionEntry) -> CompanionNarrativeSummary? {
        let runs = assignedRuns(for: companion)
        guard let firstRun = runs.first, let latestRun = runs.last else { return nil }

        let petName = companion.pet.displayName
        let originLine: String
        if let firstImpact = firstRun.worldImpact {
            if firstImpact.unlockedRegion {
                originLine = "첫 동행에서 \(firstImpact.regionTitle) 구역이 열렸고, \(petName)의 성장선도 여기서 시작됐어요."
            } else if let episodeTitle = firstImpact.episodeTitle {
                originLine = "첫 기억은 \(firstImpact.regionTitle)에서 시작됐고, \(episodeTitle) 쪽의 신호가 함께 남았어요."
            } else {
                originLine = "첫 기억은 \(firstImpact.regionTitle) 구역에 남은 러닝 흔적으로 기록돼 있어요."
            }
        } else {
            originLine = "\(distanceLabel(for: firstRun))의 첫 러닝이 \(petName)의 출발점으로 남아 있어요."
        }

        let recentLine: String
        if let latestImpact = latestRun.worldImpact {
            if latestImpact.unlockedEpisode, let episodeTitle = latestImpact.episodeTitle {
                recentLine = "가장 최근에는 \(episodeTitle) 에피소드가 열리며 \(petName)의 이야기 폭이 넓어졌어요."
            } else if let episodeTitle = latestImpact.episodeTitle {
                recentLine = "최근 러닝은 \(episodeTitle) 쪽으로 이야기를 밀어 주며 현재 흐름을 강화했어요."
            } else {
                recentLine = "최근 흔적은 \(latestImpact.regionTitle) 구역에 남았고, 지금의 성향도 이 구역 쪽으로 기울고 있어요."
            }
        } else {
            recentLine = "가장 최근 기록은 \(latestRun.endedAt.formatted(date: .abbreviated, time: .omitted))에 남아 있어요."
        }

        let trajectoryLine: String
        if let nextEpisodeFocus = nextEpisodeFocus(for: companion) {
            trajectoryLine = nextEpisodeFocus.detail
        } else if let variant = variantNarrative(for: companion) {
            trajectoryLine = "\(variant.playerFacingName) 계열의 여운이 남아 있어, 변이 서사가 아직 이어지고 있어요."
        } else if let worldProfile = worldProfile(for: companion) {
            trajectoryLine = worldProfile.hookLine
        } else {
            trajectoryLine = "\(petName)은 아직 다음 장면을 기다리는 초기 기록 단계에 있어요."
        }

        return CompanionNarrativeSummary(
            originLine: originLine,
            recentLine: recentLine,
            trajectoryLine: trajectoryLine
        )
    }

    func nextEpisodeFocus(for companion: PetCollectionEntry) -> EpisodeNarrativeFocus? {
        let runs = assignedRuns(for: companion)
        guard let latestImpact = runs.compactMap(\.worldImpact).last else { return nil }

        let pack = contentCatalog.worldContentPack()
        let regionEpisodes = pack.narrativeEpisodes.filter {
            $0.regionID == latestImpact.regionID &&
            (latestImpact.seasonID == nil || $0.seasonID == latestImpact.seasonID)
        }
        let candidates = regionEpisodes.isEmpty
            ? pack.narrativeEpisodes.filter { $0.regionID == latestImpact.regionID }
            : regionEpisodes

        let ranked = candidates.compactMap { episode -> (NarrativeEpisodeEntry, WorldEpisodeProgress?, Double)? in
            let progressEntry = progress.worldProgressSnapshot.episodes.first(where: { $0.episodeID == episode.episodeID })
            if progressEntry?.unlockedAt != nil { return nil }
            let ratio = progressEntry.map { RunimalWorldProgressEngine.progressRatio(for: $0, entry: episode) } ?? 0
            return (episode, progressEntry, ratio)
        }
        .sorted {
            if $0.2 != $1.2 { return $0.2 > $1.2 }
            return $0.0.episodeID < $1.0.episodeID
        }

        guard let target = ranked.first else { return nil }
        let progressValue = min(max(target.2, 0), 1)
        return EpisodeNarrativeFocus(
            title: target.0.playerFacingText,
            detail: episodeRequirementSummary(episode: target.0, progress: target.1),
            progress: progressValue,
            progressLabel: "\(Int((progressValue * 100).rounded()))%"
        )
    }

    func selectCompanionForWatch(_ companionID: String) {
        progress.selectWatchCompanion(id: companionID)
        syncMainCompanionSelection()
    }

    func selectEggForWatch(_ eggID: String) {
        progress.selectWatchEgg(id: eggID)
        syncMainCompanionSelection()
    }

    func growthStageIndex(for companion: PetCollectionEntry) -> Int {
        let evolutionProgress = RunimalCompanionGrowthEngine.evolutionProgress(
            for: progress.growthRecord(for: companion.id),
            species: companion.pet.species
        )
        return max(0, RunimalBalanceConfig.evolutionStageLabels.firstIndex(of: evolutionProgress.stageLabel) ?? 0)
    }

    private func assignedRuns(for companion: PetCollectionEntry) -> [CompletedRunRecord] {
        guard let growthRecord = progress.growthRecord(for: companion.id) else { return [] }

        return progress.completedRuns
            .filter { growthRecord.assignedRunIDs.contains($0.id) }
            .sorted { $0.endedAt < $1.endedAt }
    }

    private func previewCompanion(for species: PetSpecies) -> PetCollectionEntry {
        let pet = GeneratedPet(
            species: species,
            element: previewElement(for: species),
            palette: species.paletteName(),
            rareVariant: nil,
            explanation: ["유아기 확인용 미리보기"],
            stats: PetStats(vitality: 6, agility: 6, dexterity: 6, focus: 6, defense: 6)
        )

        return PetCollectionEntry(
            id: "preview-\(species.rawValue)",
            pet: pet,
            level: 1,
            bond: 40,
            totalDistanceKm: 0,
            headline: "유아기 확인용"
        )
    }

    private func previewElement(for species: PetSpecies) -> PetElement {
        switch species {
        case .windrunner:
            return .light
        case .stoneback:
            return .earth
        case .sparkfang:
            return .flame
        case .mosshop:
            return .leaf
        case .shadebit:
            return .lunar
        case .seedle:
            return .light
        }
    }

    private func episodeRequirementSummary(
        episode: NarrativeEpisodeEntry,
        progress: WorldEpisodeProgress?
    ) -> String {
        var requirements: [String] = []
        let rules = episode.triggerRules

        if let completedRunsMin = rules.completedRunsMin {
            let remaining = max(completedRunsMin - (progress?.runCount ?? 0), 0)
            if remaining > 0 {
                requirements.append("러닝 \(remaining)회")
            }
        }

        if let distanceKmMin = rules.distanceKmMin {
            let remaining = max(distanceKmMin - (progress?.totalDistanceKm ?? 0), 0)
            if remaining > 0.05 {
                requirements.append("거리 \(remaining.formatted(.number.precision(.fractionLength(1))))km")
            }
        }

        if let cadenceMin = rules.cadenceMin {
            let currentCadence = progress?.cadencePeak ?? 0
            if currentCadence < cadenceMin {
                requirements.append("케이던스 \(cadenceMin)spm")
            }
        }

        if let nightRunRequired = rules.nightRunRequired, nightRunRequired {
            if (progress?.nightRunCount ?? 0) == 0 {
                requirements.append("야간 러닝 1회")
            }
        }

        if let elevationGainMin = rules.elevationGainMin {
            let remaining = max(elevationGainMin - (progress?.totalElevationGainM ?? 0), 0)
            if remaining > 0 {
                requirements.append("상승고도 \(remaining)m")
            }
        }

        if requirements.isEmpty {
            return "다음 장면이 거의 준비됐어요. 현재 구역의 신호를 조금만 더 밀어주면 열립니다."
        }

        return "다음 장면까지 \(requirements.prefix(2).joined(separator: ", "))가 더 필요해요."
    }

    private func distanceLabel(for run: CompletedRunRecord) -> String {
        "\(run.distanceMeters / 1000.0)km"
    }
}
