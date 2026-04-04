import Foundation

public enum RunimalStarterLoopEngine {
    public static let minimumMeaningfulDistanceMeters: Double = 1_000

    public static func isMeaningfulRun(_ run: CompletedRunRecord) -> Bool {
        run.distanceMeters >= minimumMeaningfulDistanceMeters
    }

    public static func guaranteedStarterHatchGain(
        for run: CompletedRunRecord,
        egg: EggInventoryEntry
    ) -> Int? {
        guard egg.starterBoosted else { return nil }
        guard egg.incubationRunIDs.isEmpty else { return nil }
        guard isMeaningfulRun(run) else { return nil }

        return max(run.reward.experience, max(0, egg.hatchThreshold - egg.storedExperience))
    }

    public static func shouldGuaranteeFirstVisibleStageAdvance(
        record: CompanionGrowthRecord?,
        currentStageLabel: String,
        run: CompletedRunRecord
    ) -> Bool {
        guard let record else { return false }
        guard record.feedCount == 0 else { return false }
        guard record.assignedRunIDs.count >= 2 else { return false }
        guard currentStageLabel == RunimalBalanceConfig.evolutionStageLabels[1] else { return false }
        return isMeaningfulRun(run)
    }

    public static func guaranteedFirstVisibleStageTotalExperience(for species: PetSpecies?) -> Int {
        let thresholds = RunimalBalanceConfig.evolutionThresholds(for: species)
        guard thresholds.count > 2 else { return thresholds.last ?? 0 }
        return thresholds[2]
    }

    public static func guaranteedFirstVisibleStageGain(
        currentExperience: Int,
        species: PetSpecies?
    ) -> Int {
        max(0, guaranteedFirstVisibleStageTotalExperience(for: species) - max(currentExperience, 0))
    }
}
