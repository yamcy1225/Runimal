import Foundation

public enum RunimalCompanionBuildEngine {
    public static func recommendedRoles(for pet: GeneratedPet) -> [CompanionRole] {
        switch pet.species {
        case .windrunner, .sparkfang:
            return [.relay, .vanguard, .oracle]
        case .stoneback, .mosshop:
            return [.vanguard, .oracle, .relay]
        case .shadebit, .seedle:
            return [.oracle, .relay, .vanguard]
        }
    }

    public static func skillTree(for buildState: CompanionBuildState?) -> [CompanionSkillNode] {
        let role = buildState?.selectedRole ?? .relay
        let unlocked = Set(buildState?.unlockedNodeIDs ?? [])

        return nodeBlueprints(for: role).map { node in
            CompanionSkillNode(
                id: node.id,
                title: node.title,
                detail: node.detail,
                cost: node.cost,
                unlocked: unlocked.contains(node.id)
            )
        }
    }

    public static func feedBonus(
        for buildState: CompanionBuildState?,
        run: CompletedRunRecord,
        companion: PetCollectionEntry
    ) -> Int {
        guard let buildState else { return 0 }
        let unlocked = Set(buildState.unlockedNodeIDs)
        var bonus = 0

        if unlocked.contains("surge-link"), (run.cadence ?? 0) >= 172 {
            bonus += 12
        }
        if unlocked.contains("guard-shell"), run.elevationGainM >= 30 {
            bonus += 12
        }
        if unlocked.contains("oracle-window"), companion.pet.rareVariant != nil {
            bonus += 14
        }
        if unlocked.contains("echo-lens"), run.reward.completedQuestCount >= 2 {
            bonus += 10
        }

        return bonus
    }

    private static func nodeBlueprints(for role: CompanionRole) -> [(id: String, title: String, detail: String, cost: Int)] {
        switch role {
        case .vanguard:
            return [
                ("guard-shell", "Guard Shell", "언덕/누적 고도 러닝을 먹일 때 추가 XP를 줍니다.", 24),
                ("impact-core", "Impact Core", "장거리 러닝을 안정적으로 소화하는 탱크 계열 보정을 준비합니다.", 34),
            ]
        case .relay:
            return [
                ("surge-link", "Surge Link", "고케이던스 러닝을 먹일 때 추가 XP를 줍니다.", 24),
                ("draft-lane", "Draft Lane", "페이스 안정성이 좋은 러닝의 성장 변환율을 높입니다.", 34),
            ]
        case .oracle:
            return [
                ("oracle-window", "Oracle Window", "희귀 변이 개체가 러닝 코어를 더 잘 흡수합니다.", 24),
                ("echo-lens", "Echo Lens", "퀘스트를 많이 끝낸 러닝일수록 성장 보너스를 얻습니다.", 34),
            ]
        }
    }
}
