import Foundation

public enum RunimalEssenceForgeEngine {
    public static func options(
        for companion: PetCollectionEntry,
        season: WeeklySeason
    ) -> [EssenceForgeOption] {
        let seasonReady = RunimalGameEngine.seasonAffinity(for: companion.pet, season: season)

        return [
            EssenceForgeOption(
                id: "forge-overdrive",
                title: "Overdrive Charge",
                detail: "다음 먹이 주기에 추가 XP를 실어주는 범용 촉매입니다.",
                cost: 30,
                rewardLabel: "+36 XP next feed"
            ),
            EssenceForgeOption(
                id: "forge-season-sigil",
                title: season.rewardTitle,
                detail: seasonReady
                    ? "현재 주력 펫과 시즌이 맞물려 다음 먹이 주기에서 시즌 진화 가속이 붙습니다."
                    : "시즌 정렬이 맞는 펫에게 더 강하게 작동하는 시즌 전용 촉매입니다.",
                cost: 44,
                rewardLabel: seasonReady ? "+28 XP + season crest" : "+18 XP on seasonal pet"
            ),
        ]
    }

    public static func bonusExperience(
        using inventory: ForgeInventory,
        companion: PetCollectionEntry,
        season: WeeklySeason
    ) -> (bonus: Int, consumeOverdrive: Bool, consumeSeasonSigil: Bool) {
        let usesOverdrive = inventory.overdriveCharges > 0
        let usesSeasonSigil = inventory.seasonSigils > 0 && RunimalGameEngine.seasonAffinity(for: companion.pet, season: season)
        let overdriveBonus = usesOverdrive ? 36 : 0
        let seasonalBonus = usesSeasonSigil ? 28 : 0

        return (overdriveBonus + seasonalBonus, usesOverdrive, usesSeasonSigil)
    }
}
