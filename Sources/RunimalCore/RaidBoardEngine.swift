import Foundation

public enum RunimalRaidBoardEngine {
    public static func encounters(
        for companion: PetCollectionEntry,
        progress: EvolutionProgress,
        selectedRole: CompanionRole
    ) -> [RaidEncounter] {
        let corePower = companion.level + companion.bond + progress.totalExperience / 18
        let roleScalar: Int

        switch selectedRole {
        case .vanguard:
            roleScalar = companion.pet.stats.defense * 5
        case .relay:
            roleScalar = companion.pet.stats.agility * 5
        case .oracle:
            roleScalar = companion.pet.stats.focus * 5
        }

        return [
            RaidEncounter(
                id: "apex-husk",
                title: "Apex Husk",
                detail: "탱크/장거리 축이 강한 펫에게 맞는 고난도 보스입니다.",
                readinessScore: corePower + companion.pet.stats.vitality * 4 + roleScalar / 2,
                recommendedReward: "Ascension shard",
                claimThreshold: 150
            ),
            RaidEncounter(
                id: "signal-wyrm",
                title: "Signal Wyrm",
                detail: "속도와 연계가 강한 개체가 우세한 레이드입니다.",
                readinessScore: corePower + companion.pet.stats.agility * 4 + roleScalar / 2,
                recommendedReward: "Relay crest",
                claimThreshold: 145
            ),
            RaidEncounter(
                id: "lumen-veil",
                title: "Lumen Veil",
                detail: "집중력과 희귀 변이 시너지가 좋은 펫이 강한 레이드입니다.",
                readinessScore: corePower + companion.pet.stats.focus * 4 + roleScalar / 2,
                recommendedReward: "Oracle sigil",
                claimThreshold: 152
            ),
            RaidEncounter(
                id: "root-bastion",
                title: "Root Bastion",
                detail: "체력과 방어가 높은 장거리 개체에게 유리한 시즌 보스입니다.",
                readinessScore: corePower + companion.pet.stats.defense * 4 + companion.pet.stats.vitality * 2,
                recommendedReward: "Season bulwark",
                claimThreshold: 158
            ),
        ]
    }
}
