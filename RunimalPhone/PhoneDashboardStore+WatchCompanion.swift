import RunimalCore
import SwiftUI

struct CompanionRunMetricSummary {
    let totalDistanceKm: Double
    let averagePaceSeconds: Int?
    let averageCadence: Int?
    let averageHeartRate: Double?

    var primaryLine: String {
        paceLabel(averagePaceSeconds)
    }

    var secondaryLine: String {
        cadenceLabel(averageCadence)
    }

    var tertiaryLine: String {
        heartRateLabel(averageHeartRate)
    }

    var watchDetailText: String {
        [secondaryLine, tertiaryLine].joined(separator: "\n")
    }

    private func paceLabel(_ seconds: Int?) -> String {
        guard let seconds else { return "페이스 --" }
        return "페이스 \(seconds / 60):\(String(format: "%02d", seconds % 60))/km"
    }

    private func cadenceLabel(_ cadence: Int?) -> String {
        guard let cadence else { return "케이던스 --" }
        return "케이던스 \(cadence) spm"
    }

    private func heartRateLabel(_ heartRate: Double?) -> String {
        guard let heartRate else { return "심박 -- bpm" }
        return "심박 \(Int(heartRate.rounded())) bpm"
    }
}

@MainActor
extension PhoneDashboardStore {
    var watchSelectionFormLabel: String? {
        switch watchSelection?.kind {
        case .pet:
            return watchPet.flatMap { mutationForm(for: $0)?.displayTitle }
        default:
            return nil
        }
    }

    var watchSelection: MainCompanionSelection? {
        progress.watchCompanionSelection ?? progress.mainCompanionSelection
    }

    var watchSelectionLabel: String {
        switch watchSelection?.kind {
        case .egg:
            return watchEgg?.title ?? "???"
        case .pet:
            return watchPet?.pet.displayName ?? featuredCompanion.pet.displayName
        case nil:
            if let watchEgg {
                return watchEgg.title
            }
            return featuredCompanion.pet.displayName
        }
    }

    var watchSelectionDetail: String {
        switch watchSelection?.kind {
        case .egg:
            guard let watchEgg else { return "워치에 들고 나갈 알을 고르세요." }
            return metricSummary(for: watchEgg)?.primaryLine ?? (watchEgg.readyToHatch ? "워치에서 바로 부화 상호작용이 가능합니다." : watchEgg.shell.hatchHint)
        case .pet:
            return watchPet.flatMap { metricSummary(for: $0)?.primaryLine } ?? featuredCompanion.headline
        case nil:
            if let watchEgg {
                return metricSummary(for: watchEgg)?.primaryLine ?? (watchEgg.readyToHatch ? "워치에서 바로 부화 상호작용이 가능합니다." : watchEgg.shell.hatchHint)
            }
            return "워치에 들고 나갈 동행을 고르세요."
        }
    }

    var watchSelectionSecondaryDetail: String? {
        switch watchSelection?.kind {
        case .egg:
            return watchEgg.flatMap { metricSummary(for: $0)?.watchDetailText }
        case .pet:
            return watchPet.flatMap { metricSummary(for: $0)?.watchDetailText }
        case nil:
            return nil
        }
    }

    var watchAccentColor: Color {
        watchEgg?.shell.accentColor ?? watchPet?.pet.accentColor ?? mainAccentColor
    }

    var watchPet: PetCollectionEntry? {
        progress.watchPetSelection ?? progress.mainPetSelection
    }

    var watchEgg: EggInventoryEntry? {
        progress.watchEggSelection ?? progress.mainEggSelection
    }

    var watchMainCompanionContext: WatchMainCompanionContext {
        if let selection = watchSelection {
            switch selection.kind {
            case .egg:
                if let egg = eggInventory.first(where: { $0.id == selection.targetID }) {
                    return WatchMainCompanionContext(
                        selection: selection,
                        detailText: metricSummary(for: egg)?.watchDetailText,
                        eggShell: egg.shell,
                        eggTitle: egg.title,
                        eggProgressRatio: egg.progressRatio,
                        eggReadyToHatch: egg.readyToHatch
                    )
                }
            case .pet:
                if let companion = collection.first(where: { $0.id == selection.targetID }) {
                    let lore = contentCatalog.companionWorldProfile(for: companion.pet)
                    let renderState = pixelRenderState(for: companion)
                    let progression = RunimalCompanionGrowthEngine.progressionSnapshot(
                        for: progress.growthRecord(for: companion.id),
                        species: companion.pet.species
                    )
                    return WatchMainCompanionContext(
                        selection: selection,
                        pet: companion.pet,
                        petName: companion.pet.displayName,
                        petHeadline: renderState.mutationForm?.displayTitle ?? lore?.fantasyLine ?? companion.headline,
                        detailText: lore?.habitatLine,
                        companionLevel: companion.level,
                        companionStageLabel: progression.progress.stageLabel,
                        growthStageIndex: renderState.growthStageIndex,
                        mutationBodyStage: renderState.mutationVisualState.bodyStage,
                        mutationEcologyStage: renderState.mutationVisualState.ecologyStage,
                        mutationRhythmStage: renderState.mutationVisualState.rhythmStage,
                        mutationBodyBranchID: renderState.mutationForm?.bodyBranchID,
                        mutationEcologyBranchID: renderState.mutationForm?.ecologyBranchID,
                        mutationRhythmBranchID: renderState.mutationForm?.rhythmBranchID
                    )
                }

                if let companion = progress.ownedCompanions.first(where: { $0.id == selection.targetID }) {
                    let lore = contentCatalog.companionWorldProfile(for: companion.pet)
                    let renderState = pixelRenderState(for: companion)
                    let progression = RunimalCompanionGrowthEngine.progressionSnapshot(
                        for: progress.growthRecord(for: companion.id),
                        species: companion.pet.species
                    )
                    return WatchMainCompanionContext(
                        selection: selection,
                        pet: companion.pet,
                        petName: companion.pet.displayName,
                        petHeadline: renderState.mutationForm?.displayTitle ?? lore?.fantasyLine ?? companion.headline,
                        detailText: lore?.habitatLine,
                        companionLevel: companion.level,
                        companionStageLabel: progression.progress.stageLabel,
                        growthStageIndex: renderState.growthStageIndex,
                        mutationBodyStage: renderState.mutationVisualState.bodyStage,
                        mutationEcologyStage: renderState.mutationVisualState.ecologyStage,
                        mutationRhythmStage: renderState.mutationVisualState.rhythmStage,
                        mutationBodyBranchID: renderState.mutationForm?.bodyBranchID,
                        mutationEcologyBranchID: renderState.mutationForm?.ecologyBranchID,
                        mutationRhythmBranchID: renderState.mutationForm?.rhythmBranchID
                    )
                }
            }
        }

        if let egg = watchEgg {
            return WatchMainCompanionContext(
                selection: MainCompanionSelection(kind: .egg, targetID: egg.id),
                detailText: metricSummary(for: egg)?.watchDetailText,
                eggShell: egg.shell,
                eggTitle: egg.title,
                eggProgressRatio: egg.progressRatio,
                eggReadyToHatch: egg.readyToHatch
            )
        }

        let companion = watchPet ?? featuredCompanion
        let lore = contentCatalog.companionWorldProfile(for: companion.pet)
        let renderState = pixelRenderState(for: companion)
        let progression = RunimalCompanionGrowthEngine.progressionSnapshot(
            for: progress.growthRecord(for: companion.id),
            species: companion.pet.species
        )
        return WatchMainCompanionContext(
            selection: MainCompanionSelection(kind: .pet, targetID: companion.id),
            pet: companion.pet,
            petName: companion.pet.displayName,
            petHeadline: renderState.mutationForm?.displayTitle ?? lore?.fantasyLine ?? companion.headline,
            detailText: lore?.habitatLine,
            companionLevel: companion.level,
            companionStageLabel: progression.progress.stageLabel,
            growthStageIndex: renderState.growthStageIndex,
            mutationBodyStage: renderState.mutationVisualState.bodyStage,
            mutationEcologyStage: renderState.mutationVisualState.ecologyStage,
            mutationRhythmStage: renderState.mutationVisualState.rhythmStage,
            mutationBodyBranchID: renderState.mutationForm?.bodyBranchID,
            mutationEcologyBranchID: renderState.mutationForm?.ecologyBranchID,
            mutationRhythmBranchID: renderState.mutationForm?.rhythmBranchID
        )
    }

    func syncMainCompanionSelection() {
        let context = watchMainCompanionContext
        connectivity.currentMainCompanionContext = context
        connectivity.currentMainCompanionProvider = { [weak self] in
            self?.watchMainCompanionContext
        }
        connectivity.pushMainCompanionContext(context)
    }

    func metricSummary(for companion: PetCollectionEntry) -> CompanionRunMetricSummary? {
        guard let record = progress.growthRecords.first(where: { $0.companionID == companion.id }) else {
            return CompanionRunMetricSummary(totalDistanceKm: 0, averagePaceSeconds: nil, averageCadence: nil, averageHeartRate: nil)
        }
        return metricSummary(forRunIDs: record.assignedRunIDs)
    }

    func metricSummary(for egg: EggInventoryEntry) -> CompanionRunMetricSummary? {
        metricSummary(forRunIDs: [egg.sourceRunID] + egg.incubationRunIDs)
    }

    private func metricSummary(forRunIDs runIDs: [String]) -> CompanionRunMetricSummary? {
        guard !runIDs.isEmpty else {
            return nil
        }

        let runsByID = Dictionary(uniqueKeysWithValues: completedRuns.map { ($0.id, $0) })
        let runs = runIDs.compactMap { runsByID[$0] }.filter { $0.source != "seeded-archive" }
        guard !runs.isEmpty else {
            return nil
        }

        let totalDistanceMeters = runs.reduce(0.0) { $0 + $1.distanceMeters }
        let totalDurationSeconds = runs.reduce(0) { $0 + max($1.durationSeconds, 0) }

        let cadenceSamples = runs.compactMap { run -> (Double, Double)? in
            guard let cadence = run.cadence else { return nil }
            return (Double(max(run.durationSeconds, 1)), Double(cadence))
        }
        let heartSamples = runs.compactMap { run -> (Double, Double)? in
            guard let heartRate = run.averageHeartRate else { return nil }
            return (Double(max(run.durationSeconds, 1)), heartRate)
        }

        let averageCadence = weightedAverage(samples: cadenceSamples).map { Int($0.rounded()) }
        let averageHeartRate = weightedAverage(samples: heartSamples)
        let averagePaceSeconds = totalDistanceMeters > 0
            ? Int((Double(totalDurationSeconds) / (totalDistanceMeters / 1000)).rounded())
            : nil

        return CompanionRunMetricSummary(
            totalDistanceKm: totalDistanceMeters / 1000,
            averagePaceSeconds: averagePaceSeconds,
            averageCadence: averageCadence,
            averageHeartRate: averageHeartRate
        )
    }

    private func weightedAverage(samples: [(Double, Double)]) -> Double? {
        let totalWeight = samples.reduce(0.0) { $0 + $1.0 }
        guard totalWeight > 0 else { return nil }
        let weightedSum = samples.reduce(0.0) { $0 + ($1.0 * $1.1) }
        return weightedSum / totalWeight
    }
}
