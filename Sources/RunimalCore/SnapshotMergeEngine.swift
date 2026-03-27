import Foundation

public enum RunimalSnapshotMergeEngine {
    public static func merge(_ lhs: RunimalProgressSnapshot, _ rhs: RunimalProgressSnapshot) -> RunimalProgressSnapshot {
        let journal = uniqueJournal(lhs.journal + rhs.journal)
        let completedRuns = uniqueRuns(lhs.completedRuns + rhs.completedRuns)
        let growthRecords = uniqueGrowth(lhs.growthRecords + rhs.growthRecords)

        return RunimalProgressSnapshot(
            savedAt: max(lhs.savedAt, rhs.savedAt),
            originDeviceID: "\(lhs.originDeviceID)+\(rhs.originDeviceID)",
            journal: journal,
            completedRuns: completedRuns,
            claimedWeeklyRewards: Array(Set(lhs.claimedWeeklyRewards + rhs.claimedWeeklyRewards)).sorted(),
            activeCompanionID: rhs.activeCompanionID ?? lhs.activeCompanionID,
            growthRecords: growthRecords,
            retiredCompanionIDs: Array(Set(lhs.retiredCompanionIDs + rhs.retiredCompanionIDs)).sorted(),
            essenceBalance: max(lhs.essenceBalance, rhs.essenceBalance),
            overdriveCharges: max(lhs.overdriveCharges, rhs.overdriveCharges),
            seasonSigils: max(lhs.seasonSigils, rhs.seasonSigils),
            buildStates: uniqueBuildStates(lhs.buildStates + rhs.buildStates),
            claimedSeasonRewardIDs: Array(Set(lhs.claimedSeasonRewardIDs + rhs.claimedSeasonRewardIDs)).sorted(),
            claimedRaidRewardIDs: Array(Set(lhs.claimedRaidRewardIDs + rhs.claimedRaidRewardIDs)).sorted(),
            raidShardBalance: max(lhs.raidShardBalance, rhs.raidShardBalance)
        )
    }

    private static func uniqueJournal(_ entries: [RunJournalEntry]) -> [RunJournalEntry] {
        Array(Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) }).values)
            .sorted(by: { $0.createdAt > $1.createdAt })
    }

    private static func uniqueRuns(_ runs: [CompletedRunRecord]) -> [CompletedRunRecord] {
        Array(Dictionary(uniqueKeysWithValues: runs.map { ($0.id, $0) }).values)
            .sorted(by: { $0.endedAt > $1.endedAt })
    }

    private static func uniqueGrowth(_ records: [CompanionGrowthRecord]) -> [CompanionGrowthRecord] {
        Array(Dictionary(uniqueKeysWithValues: records.map { ($0.companionID, $0) }).values)
    }

    private static func uniqueBuildStates(_ states: [CompanionBuildState]) -> [CompanionBuildState] {
        Array(Dictionary(uniqueKeysWithValues: states.map { ($0.companionID, $0) }).values)
    }
}
