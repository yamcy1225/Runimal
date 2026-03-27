import Foundation

public enum RunimalSeasonalUnlockEngine {
    public static func unlocks(
        season: WeeklySeason,
        claimedSeasonIDs: [String],
        claimedRaidIDs: [String]
    ) -> [SeasonalUnlock] {
        [
            SeasonalUnlock(
                id: "season-form",
                title: "\(season.evolutionTitle) Form",
                detail: "Claim the season cache to unlock the seasonal evolution shell.",
                unlocked: !claimedSeasonIDs.isEmpty
            ),
            SeasonalUnlock(
                id: "raid-skin",
                title: "\(season.rewardTitle) Skin",
                detail: "Clear a raid in this season to unlock the matching skin layer.",
                unlocked: !claimedRaidIDs.isEmpty
            ),
        ]
    }
}
