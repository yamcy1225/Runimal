import Foundation

public enum RunimalSeasonEconomyEngine {
    public static func board(
        for season: WeeklySeason,
        collection: [PetCollectionEntry],
        claimedSeasonIDs: Set<String>
    ) -> SeasonEconomyBoard {
        let seasonID = season.title.lowercased().replacingOccurrences(of: " ", with: "-")
        let affinityCount = collection.filter { RunimalGameEngine.seasonAffinity(for: $0.pet, season: season) }.count
        let requiredCount = 2
        let claimable = affinityCount >= requiredCount && !claimedSeasonIDs.contains(seasonID)
        let headline = claimable
            ? "시즌 친화 펫이 모였습니다. 전용 캐시를 열 수 있습니다."
            : "시즌 친화 펫 \(requiredCount)마리를 모으면 전용 캐시가 열립니다."

        return SeasonEconomyBoard(
            seasonID: seasonID,
            title: "\(season.title) Cache",
            headline: headline,
            affinityCount: affinityCount,
            requiredCount: requiredCount,
            rewardLabel: "+40 Essence · +1 Season Sigil",
            claimable: claimable
        )
    }
}
