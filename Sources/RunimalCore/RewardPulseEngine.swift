import Foundation

public struct RewardPulseResult: Equatable, Sendable {
    public let bonusExperience: Int
    public let bonusLabels: [String]
    public let flavorFragments: [String]

    public init(bonusExperience: Int, bonusLabels: [String], flavorFragments: [String]) {
        self.bonusExperience = bonusExperience
        self.bonusLabels = bonusLabels
        self.flavorFragments = flavorFragments
    }
}

public enum RunimalRewardPulseEngine {
    public static func runPulse(
        for summary: RunSummary,
        completedQuestCount: Int
    ) -> RewardPulseResult {
        var bonus = 0
        var labels: [String] = []
        var fragments: [String] = []

        if completedQuestCount >= 2 {
            bonus += 14
            labels.append("목표 달성")
            fragments.append("핵심 목표를 2개 이상 달성해 추가 보상이 붙었습니다.")
        }

        if summary.rareEventCompleted {
            bonus += 20
            labels.append("특별 이벤트")
            fragments.append("돌발 목표를 완수해 특별 이벤트 보상이 적용되었습니다.")
        }

        if summary.environmentCondition != .unknown && summary.distanceKm >= 4 {
            bonus += 8
            labels.append("환경 호흡")
            fragments.append("환경 흐름이 안정적으로 읽혀 환경 호흡 보너스가 더해졌습니다.")
        }

        return RewardPulseResult(
            bonusExperience: bonus,
            bonusLabels: labels,
            flavorFragments: fragments
        )
    }

    public static func stageLock(
        currentProgress: EvolutionProgress,
        proposedExperience: Int
    ) -> RewardPulseResult {
        guard currentProgress.stageLabel != RunimalBalanceConfig.finalStageLabel else {
            return RewardPulseResult(bonusExperience: 0, bonusLabels: [], flavorFragments: [])
        }

        let remaining = currentProgress.nextThreshold - currentProgress.totalExperience
        guard remaining > 0 else {
            return RewardPulseResult(bonusExperience: 0, bonusLabels: [], flavorFragments: [])
        }

        let gapAfterReward = remaining - proposedExperience
        guard gapAfterReward > 0 && gapAfterReward <= 18 else {
            return RewardPulseResult(bonusExperience: 0, bonusLabels: [], flavorFragments: [])
        }

        return RewardPulseResult(
            bonusExperience: gapAfterReward,
            bonusLabels: ["단계 맞춤"],
            flavorFragments: ["다음 단계 직전이라 단계 맞춤 보너스로 딱 맞게 채웠습니다."]
        )
    }

    public static func hatchLock(
        egg: EggInventoryEntry,
        proposedExperience: Int
    ) -> RewardPulseResult {
        let remaining = egg.hatchThreshold - egg.storedExperience
        guard remaining > 0 else {
            return RewardPulseResult(bonusExperience: 0, bonusLabels: [], flavorFragments: [])
        }

        let gapAfterReward = remaining - proposedExperience
        guard gapAfterReward > 0 && gapAfterReward <= 18 else {
            return RewardPulseResult(bonusExperience: 0, bonusLabels: [], flavorFragments: [])
        }

        return RewardPulseResult(
            bonusExperience: gapAfterReward,
            bonusLabels: ["부화 맞춤"],
            flavorFragments: ["부화 직전이라 부화 맞춤 보너스가 적용되었습니다."]
        )
    }
}
