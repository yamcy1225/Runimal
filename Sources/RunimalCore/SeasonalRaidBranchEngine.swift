import Foundation

public enum RunimalSeasonalRaidBranchEngine {
    public static func reward(for encounter: RaidEncounter, season: WeeklySeason) -> RaidBranchReward {
        switch season.title {
        case "Canopy Rise":
            return RaidBranchReward(branchTitle: "Canopy Bloom", extraEssence: 16, extraSigils: 1, extraOverdrive: 0)
        case "Sun Spike":
            return RaidBranchReward(branchTitle: "Solar Spike", extraEssence: 10, extraSigils: 0, extraOverdrive: 1)
        default:
            if encounter.id == "signal-wyrm" {
                return RaidBranchReward(branchTitle: "Relay Crest", extraEssence: 12, extraSigils: 1, extraOverdrive: 0)
            }

            return RaidBranchReward(branchTitle: "Shard Route", extraEssence: 14, extraSigils: 0, extraOverdrive: 1)
        }
    }
}
