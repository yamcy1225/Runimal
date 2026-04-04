import Foundation

public enum RunimalCompanionGrowthEngine {
    public static func stageIndex(for progress: EvolutionProgress) -> Int {
        max(0, RunimalBalanceConfig.evolutionStageLabels.firstIndex(of: progress.stageLabel) ?? 0)
    }

    public static func stageUnlockWindow(for progress: EvolutionProgress) -> [CompanionStageUnlock] {
        stageUnlockWindow(forStageIndex: stageIndex(for: progress))
    }

    public static func effectiveCompanion(
        from base: PetCollectionEntry,
        growthRecord: CompanionGrowthRecord?
    ) -> PetCollectionEntry {
        guard let growthRecord else { return base }

        let level = RunimalBalanceConfig.companionLevel(forExperience: growthRecord.totalExperience)
        let bondBonus = min(growthRecord.feedCount * 4, 30)
        let headline = "Lv.\(level) · fed \(growthRecord.feedCount)x · +\(growthRecord.totalExperience) XP"

        return PetCollectionEntry(
            id: base.id,
            pet: base.pet,
            level: level,
            bond: min(base.bond + bondBonus, 99),
            totalDistanceKm: base.totalDistanceKm,
            headline: headline
        )
    }

    public static func evolutionProgress(
        for growthRecord: CompanionGrowthRecord?,
        species: PetSpecies? = nil
    ) -> EvolutionProgress {
        progressionSnapshot(for: growthRecord, species: species).progress
    }

    public static func progressionSnapshot(
        for growthRecord: CompanionGrowthRecord?,
        species: PetSpecies? = nil
    ) -> CompanionProgressionSnapshot {
        progressionSnapshot(
            totalExperience: growthRecord?.totalExperience ?? 0,
            species: species,
            hasGrowthRecord: growthRecord != nil,
            emptyHeadline: "아직 이 동행에게 먹인 운동 기록이 없습니다.",
            finalHeadline: "최종 단계에 도달했습니다. 이제 시즌/변이 메타를 노릴 수 있습니다."
        )
    }

    public static func feedBonusExperience(
        baseExperience: Int,
        resonance: [CompanionEffectResonance]
    ) -> Int {
        guard resonance.isEmpty == false else { return 0 }
        let averageScore = resonance.reduce(0) { $0 + $1.score } / resonance.count
        let bonusRatio = max(0, averageScore - 54)
        return min(Int(Double(baseExperience) * (Double(bonusRatio) / 220.0)), 28)
    }

    static func progressionSnapshot(
        totalExperience: Int,
        species: PetSpecies?,
        hasGrowthRecord: Bool,
        emptyHeadline: String,
        finalHeadline: String
    ) -> CompanionProgressionSnapshot {
        let resolvedExperience = max(totalExperience, 0)
        let milestones = RunimalBalanceConfig.evolutionMilestones(for: species)
        let thresholds = milestones.map(\.requiredExperience)
        let stageLabels = RunimalBalanceConfig.evolutionStageLabels

        var currentStage = 0
        for index in thresholds.indices where resolvedExperience >= thresholds[index] {
            currentStage = index
        }

        if hasGrowthRecord {
            currentStage = max(currentStage, 1)
        }

        let nextIndex = min(currentStage + 1, thresholds.count - 1)
        let currentThreshold: Int
        if hasGrowthRecord && currentStage == 1 && resolvedExperience < thresholds[1] {
            currentThreshold = 0
        } else {
            currentThreshold = thresholds[currentStage]
        }
        let nextThreshold = thresholds[nextIndex]
        let ratio: Double

        if currentStage == thresholds.count - 1 {
            ratio = 1
        } else {
            ratio = min(
                max(Double(resolvedExperience - currentThreshold) / Double(nextThreshold - currentThreshold), 0),
                1
            )
        }

        let headline: String
        if hasGrowthRecord == false {
            headline = emptyHeadline
        } else if currentStage == thresholds.count - 1 {
            headline = finalHeadline
        } else {
            headline = "다음 진화까지 \(nextThreshold - resolvedExperience) XP 남았습니다."
        }

        let progress = EvolutionProgress(
            stageLabel: stageLabels[currentStage],
            totalExperience: resolvedExperience,
            nextThreshold: nextThreshold,
            progressRatio: ratio,
            headline: headline
        )

        let level = RunimalBalanceConfig.companionLevel(forExperience: resolvedExperience)
        let nextMilestone = currentStage < nextIndex ? milestones[nextIndex] : nil

        return CompanionProgressionSnapshot(
            level: level,
            stageIndex: currentStage,
            progress: progress,
            evolutionMilestones: milestones,
            nextEvolutionMilestone: nextMilestone,
            stageUnlockWindow: stageUnlockWindow(forStageIndex: currentStage),
            lateGrowthWindow: RunimalBalanceConfig.lateGrowthWindow(forLevel: level),
            lateGrowthFeatures: RunimalBalanceConfig.lateGrowthFeatures(forLevel: level),
            evolutionSummary: milestones.first?.summary
        )
    }

    private static func stageUnlockWindow(forStageIndex stageIndex: Int) -> [CompanionStageUnlock] {
        let currentIndex = max(stageIndex, 0)
        let upperBound = min(currentIndex + 1, RunimalBalanceConfig.companionStageUnlocks.count - 1)
        guard currentIndex <= upperBound else { return [] }
        return Array(RunimalBalanceConfig.companionStageUnlocks[currentIndex...upperBound])
    }
}
