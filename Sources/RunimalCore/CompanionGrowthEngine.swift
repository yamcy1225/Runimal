import Foundation

public enum RunimalCompanionGrowthEngine {
    public static func effectiveCompanion(
        from base: PetCollectionEntry,
        growthRecord: CompanionGrowthRecord?
    ) -> PetCollectionEntry {
        guard let growthRecord else { return base }

        let levelBonus = min(growthRecord.totalExperience / 170, 18)
        let bondBonus = min(growthRecord.feedCount * 4, 30)
        let headline = "fed \(growthRecord.feedCount)x · +\(growthRecord.totalExperience) XP"

        return PetCollectionEntry(
            id: base.id,
            pet: base.pet,
            level: min(base.level + levelBonus, 99),
            bond: min(base.bond + bondBonus, 99),
            totalDistanceKm: base.totalDistanceKm,
            headline: headline
        )
    }

    public static func evolutionProgress(for growthRecord: CompanionGrowthRecord?) -> EvolutionProgress {
        let totalExperience = growthRecord?.totalExperience ?? 0
        let thresholds = RunimalBalanceConfig.evolutionThresholds
        let stageLabels = RunimalBalanceConfig.evolutionStageLabels

        var currentStage = 0

        for index in thresholds.indices where totalExperience >= thresholds[index] {
            currentStage = index
        }

        let nextIndex = min(currentStage + 1, thresholds.count - 1)
        let currentThreshold = thresholds[currentStage]
        let nextThreshold = thresholds[nextIndex]
        let ratio: Double

        if currentStage == thresholds.count - 1 {
            ratio = 1
        } else {
            ratio = min(
                max(Double(totalExperience - currentThreshold) / Double(nextThreshold - currentThreshold), 0),
                1
            )
        }

        let headline: String

        if growthRecord == nil {
            headline = "아직 이 펫에게 먹인 러닝 코어가 없습니다."
        } else if currentStage == thresholds.count - 1 {
            headline = "최종 단계에 도달했습니다. 이제 시즌/변이 메타를 노릴 수 있습니다."
        } else {
            headline = "다음 진화까지 \(nextThreshold - totalExperience) XP 남았습니다."
        }

        return EvolutionProgress(
            stageLabel: stageLabels[currentStage],
            totalExperience: totalExperience,
            nextThreshold: nextThreshold,
            progressRatio: ratio,
            headline: headline
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
}
