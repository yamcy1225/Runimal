import Foundation

public enum RunimalCollectionEconomyEngine {
    public static func retirableOffers(
        from collection: [PetCollectionEntry],
        activeCompanionID: String?
    ) -> [RetirableCompanionOffer] {
        let speciesCounts = Dictionary(grouping: collection, by: { $0.pet.species }).mapValues(\.count)

        return collection.compactMap { companion in
            guard companion.id != activeCompanionID else { return nil }
            guard (speciesCounts[companion.pet.species] ?? 0) > 1 else { return nil }

            let rareBonus = companion.pet.rareVariant == nil ? 0 : 16
            let reward = 24 + companion.level + rareBonus

            return RetirableCompanionOffer(
                companion: companion,
                essenceReward: reward,
                reason: "\(companion.pet.species.rawValue) 계열 중복 개체를 Essence로 환원합니다."
            )
        }
        .sorted { lhs, rhs in
            lhs.essenceReward > rhs.essenceReward
        }
    }
}
