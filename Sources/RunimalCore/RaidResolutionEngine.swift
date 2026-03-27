import Foundation

public enum RunimalRaidResolutionEngine {
    public static func resolve(encounter: RaidEncounter) -> RaidResolution {
        let tier: String

        switch encounter.readinessScore {
        case (encounter.claimThreshold + 40)...:
            tier = "S"
        case (encounter.claimThreshold + 20)...:
            tier = "A"
        default:
            tier = "B"
        }

        let shardReward = tier == "S" ? 2 : 1
        let essenceReward = tier == "S" ? 42 : (tier == "A" ? 32 : 24)

        return RaidResolution(
            encounterID: encounter.id,
            title: encounter.title,
            tier: tier,
            shardReward: shardReward,
            essenceReward: essenceReward
        )
    }
}
