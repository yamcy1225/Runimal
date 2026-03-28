import Foundation

public enum RunimalSnapshotMergeEngine {
    public static func merge(
        _ lhs: RunimalProgressSnapshot,
        _ rhs: RunimalProgressSnapshot,
        priority: SnapshotDuplicatePriority = .newestWins
    ) -> RunimalProgressSnapshot {
        let journal = uniqueJournal(lhs.journal, rhs.journal, priority: priority)
        let completedRuns = uniqueRuns(lhs.completedRuns, rhs.completedRuns, priority: priority)
        let ownedCompanions = uniqueCompanions(lhs.ownedCompanions, rhs.ownedCompanions, priority: priority)
        let eggInventory = uniqueEggs(lhs.eggInventory, rhs.eggInventory, priority: priority)
        let growthRecords = uniqueGrowth(lhs.growthRecords + rhs.growthRecords)

        return RunimalProgressSnapshot(
            savedAt: max(lhs.savedAt, rhs.savedAt),
            originDeviceID: "\(lhs.originDeviceID)+\(rhs.originDeviceID)",
            journal: journal,
            completedRuns: completedRuns,
            ownedCompanions: ownedCompanions,
            eggInventory: eggInventory,
            unlockedEggAchievementIDs: Array(Set(lhs.unlockedEggAchievementIDs + rhs.unlockedEggAchievementIDs)).sorted(),
            claimedWeeklyRewards: Array(Set(lhs.claimedWeeklyRewards + rhs.claimedWeeklyRewards)).sorted(),
            activeCompanionID: rhs.activeCompanionID ?? lhs.activeCompanionID,
            mainCompanionSelection: rhs.mainCompanionSelection ?? lhs.mainCompanionSelection,
            growthRecords: growthRecords,
            retiredCompanionIDs: Array(Set(lhs.retiredCompanionIDs + rhs.retiredCompanionIDs)).sorted(),
            essenceBalance: max(lhs.essenceBalance, rhs.essenceBalance),
            overdriveCharges: max(lhs.overdriveCharges, rhs.overdriveCharges),
            seasonSigils: max(lhs.seasonSigils, rhs.seasonSigils),
            buildStates: uniqueBuildStates(lhs.buildStates + rhs.buildStates),
            claimedSeasonRewardIDs: Array(Set(lhs.claimedSeasonRewardIDs + rhs.claimedSeasonRewardIDs)).sorted(),
            claimedRaidRewardIDs: Array(Set(lhs.claimedRaidRewardIDs + rhs.claimedRaidRewardIDs)).sorted(),
            raidShardBalance: max(lhs.raidShardBalance, rhs.raidShardBalance),
            raidContributionTotal: max(lhs.raidContributionTotal, rhs.raidContributionTotal)
        )
    }

    private static func uniqueJournal(
        _ local: [RunJournalEntry],
        _ cloud: [RunJournalEntry],
        priority: SnapshotDuplicatePriority
    ) -> [RunJournalEntry] {
        Array(
            Dictionary(
                prioritized(local, cloud, priority: priority).map { ($0.id, $0) },
                uniquingKeysWith: { _, latest in latest }
            ).values
        )
            .sorted(by: { $0.createdAt > $1.createdAt })
    }

    private static func uniqueRuns(
        _ local: [CompletedRunRecord],
        _ cloud: [CompletedRunRecord],
        priority: SnapshotDuplicatePriority
    ) -> [CompletedRunRecord] {
        Array(
            Dictionary(
                prioritized(local, cloud, priority: priority).map { ($0.id, $0) },
                uniquingKeysWith: { _, latest in latest }
            ).values
        )
            .sorted(by: { $0.endedAt > $1.endedAt })
    }

    private static func prioritized<T>(_ local: [T], _ cloud: [T], priority: SnapshotDuplicatePriority) -> [T] {
        switch priority {
        case .localWins:
            return local + cloud
        case .newestWins:
            return cloud + local
        case .cloudWins:
            return cloud + local
        }
    }

    private static func uniqueGrowth(_ records: [CompanionGrowthRecord]) -> [CompanionGrowthRecord] {
        Array(Dictionary(uniqueKeysWithValues: records.map { ($0.companionID, $0) }).values)
    }

    private static func uniqueCompanions(
        _ local: [PetCollectionEntry],
        _ cloud: [PetCollectionEntry],
        priority: SnapshotDuplicatePriority
    ) -> [PetCollectionEntry] {
        Array(
            Dictionary(
                prioritized(local, cloud, priority: priority).map { ($0.id, $0) },
                uniquingKeysWith: { _, latest in latest }
            ).values
        )
    }

    private static func uniqueEggs(
        _ local: [EggInventoryEntry],
        _ cloud: [EggInventoryEntry],
        priority: SnapshotDuplicatePriority
    ) -> [EggInventoryEntry] {
        Array(
            Dictionary(
                prioritized(local, cloud, priority: priority).map { ($0.id, $0) },
                uniquingKeysWith: { _, latest in latest }
            ).values
        )
        .sorted(by: { $0.createdAt > $1.createdAt })
    }

    private static func uniqueBuildStates(_ states: [CompanionBuildState]) -> [CompanionBuildState] {
        Array(Dictionary(uniqueKeysWithValues: states.map { ($0.companionID, $0) }).values)
    }
}
