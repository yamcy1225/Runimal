import Foundation

public enum RunimalSanctuaryEngine {
    public static func restDayReward(
        today: Date,
        completedRuns: [CompletedRunRecord],
        mainCompanion: PetCollectionEntry?,
        buildState: CompanionBuildState?
    ) -> SanctuaryRewardEvent? {
        guard let mainCompanion else { return nil }
        let calendar = Calendar.current

        if completedRuns.contains(where: { calendar.isDate($0.endedAt, inSameDayAs: today) }) {
            return nil
        }

        let baseEssence = max(Int(mainCompanion.totalDistanceKm / 6), 1)
        let oracleBoost = oracleBoostChance(buildState: buildState)
        let token = abs("\(mainCompanion.id)-\(calendar.ordinality(of: .day, in: .year, for: today) ?? 0)".hashValue) % 100
        let foundItem = token < oracleBoost

        return SanctuaryRewardEvent(
            date: today,
            essenceGained: foundItem ? baseEssence + 2 : baseEssence,
            itemLabel: foundItem ? "Gap Seed" : nil,
            logLine: foundItem
                ? "메인 펫이 틈새 세계를 탐색해 정수와 Gap Seed를 회수했습니다."
                : "메인 펫이 틈새 세계를 탐색해 소량의 정수를 회수했습니다."
        )
    }

    private static func oracleBoostChance(buildState: CompanionBuildState?) -> Int {
        guard let buildState else { return 12 }
        let unlocked = Set(buildState.unlockedNodeIDs)
        var chance = 12
        if buildState.selectedRole == .oracle {
            chance += 8
        }
        if unlocked.contains("oracle-window") {
            chance += 12
        }
        return chance
    }
}
