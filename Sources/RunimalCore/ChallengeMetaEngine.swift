import Foundation

public enum RunimalChallengeMetaEngine {
    public static func trials(
        for companion: PetCollectionEntry,
        progress: EvolutionProgress,
        selectedRole: CompanionRole
    ) -> [ChallengeTrial] {
        let base = companion.level + companion.bond + progress.totalExperience / 20
        let roleBonus: Int

        switch selectedRole {
        case .vanguard:
            roleBonus = companion.pet.stats.defense * 3
        case .relay:
            roleBonus = companion.pet.stats.agility * 3
        case .oracle:
            roleBonus = companion.pet.stats.focus * 3
        }

        return [
            ChallengeTrial(
                id: "tempo-arena",
                title: "Tempo Arena",
                detail: "고케이던스 적응력과 속도 유지력을 시험합니다.",
                score: base + companion.pet.stats.agility * 4 + roleBonus / 2,
                verdict: verdict(for: base + companion.pet.stats.agility * 4 + roleBonus / 2)
            ),
            ChallengeTrial(
                id: "ridge-gate",
                title: "Ridge Gate",
                detail: "언덕/방어 계열 압박을 버티는 챌린지입니다.",
                score: base + companion.pet.stats.defense * 4 + roleBonus / 2,
                verdict: verdict(for: base + companion.pet.stats.defense * 4 + roleBonus / 2)
            ),
            ChallengeTrial(
                id: "echo-labyrinth",
                title: "Echo Labyrinth",
                detail: "희귀 변이와 집중 유지력을 보는 장기전입니다.",
                score: base + companion.pet.stats.focus * 4 + roleBonus / 2,
                verdict: verdict(for: base + companion.pet.stats.focus * 4 + roleBonus / 2)
            ),
        ]
    }

    private static func verdict(for score: Int) -> String {
        switch score {
        case 160...: return "S-ready"
        case 130...: return "A-line"
        case 100...: return "B-line"
        default: return "Needs Growth"
        }
    }
}
