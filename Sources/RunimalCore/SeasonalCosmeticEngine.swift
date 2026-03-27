import Foundation

public enum SeasonalVisualLayer: String, Codable, CaseIterable, Sendable {
    case seasonShell = "season-shell"
    case raidStripe = "raid-stripe"
}

public enum RunimalSeasonalCosmeticEngine {
    public static func layers(
        seasonID: String,
        claimedSeasonIDs: [String],
        claimedRaidIDs: [String]
    ) -> [SeasonalVisualLayer] {
        var layers: [SeasonalVisualLayer] = []

        if claimedSeasonIDs.contains(seasonID) {
            layers.append(.seasonShell)
        }

        if claimedRaidIDs.isEmpty == false {
            layers.append(.raidStripe)
        }

        return layers
    }
}
