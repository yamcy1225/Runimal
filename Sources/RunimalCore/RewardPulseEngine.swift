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
            labels.append("Mastery Pulse")
            fragments.append("핵심 목표를 2개 이상 달성해 Mastery Pulse가 활성화되었습니다.")
        }

        if summary.rareEventCompleted {
            bonus += 20
            labels.append("Rare Signal")
            fragments.append("돌발 목표를 완수해 Rare Signal 보정이 적용되었습니다.")
        }

        if summary.environmentCondition != .unknown && summary.distanceKm >= 4 {
            bonus += 8
            labels.append("Field Sync")
            fragments.append("환경 신호가 안정적으로 읽혀 Field Sync 보너스가 더해졌습니다.")
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
        guard currentProgress.stageLabel != "Mythic" else {
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
            bonusLabels: ["Signal Lock"],
            flavorFragments: ["진화 직전 구간이라 Signal Lock 보정으로 임계점을 고정했습니다."]
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
            bonusLabels: ["Decode Lock"],
            flavorFragments: ["디코딩 임계점에 근접해 Decode Lock 보정이 적용되었습니다."]
        )
    }
}
