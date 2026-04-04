import Foundation

public enum RunimalEffectResonanceEngine {
    public static func effectResonance(
        for companion: PetCollectionEntry,
        progress: EvolutionProgress,
        activeEffects: [WeeklyRewardEffect]
    ) -> [CompanionEffectResonance] {
        activeEffects.map { effect in
            let score = resonanceScore(for: effect, companion: companion, progress: progress)

            return CompanionEffectResonance(
                id: effect.id,
                title: effect.title,
                detail: resonanceDetail(for: effect, companion: companion, progress: progress, score: score),
                intensityLabel: intensityLabel(for: score),
                score: score
            )
        }
    }

    public static func compareCollection(
        _ collection: [PetCollectionEntry],
        progress: EvolutionProgress,
        activeEffects: [WeeklyRewardEffect]
    ) -> [CompanionResonanceSummary] {
        collection.map { companion in
            let resonance = effectResonance(for: companion, progress: progress, activeEffects: activeEffects)
            let totalScore = resonance.isEmpty ? 0 : Int((Double(resonance.reduce(0) { $0 + $1.score }) / Double(resonance.count)).rounded())
            let topEffect = resonance.max(by: { $0.score < $1.score })

            return CompanionResonanceSummary(
                companion: companion,
                totalScore: totalScore,
                intensityLabel: intensityLabel(for: totalScore),
                headline: headline(for: companion, totalScore: totalScore, topEffect: topEffect),
                topEffectTitle: topEffect?.title
            )
        }
        .sorted { lhs, rhs in
            if lhs.totalScore == rhs.totalScore {
                return lhs.companion.bond > rhs.companion.bond
            }

            return lhs.totalScore > rhs.totalScore
        }
    }

    private static func resonanceScore(
        for effect: WeeklyRewardEffect,
        companion: PetCollectionEntry,
        progress: EvolutionProgress
    ) -> Int {
        var score = 48

        switch effect.id {
        case "weekly-badge":
            if companion.pet.species == .windrunner || companion.pet.species == .sparkfang {
                score += 28
            }

            score += min(companion.bond / 6, 18)
        case "weekly-core-cache":
            if companion.pet.rareVariant != nil {
                score += 34
            }

            if companion.pet.species == .shadebit || companion.pet.species == .mosshop {
                score += 12
            }
        case "weekly-evo-boost":
            if progress.progressRatio >= 0.45 {
                score += 24
            }

            score += min(companion.level, 18)
        default:
            break
        }

        return max(35, min(score, 99))
    }

    private static func resonanceDetail(
        for effect: WeeklyRewardEffect,
        companion: PetCollectionEntry,
        progress: EvolutionProgress,
        score: Int
    ) -> String {
        switch effect.id {
        case "weekly-badge":
            return "\(speciesLabel(for: companion.pet.species))의 러닝 템포와 bond \(companion.bond)이 배지 가속과 맞물려 XP 증폭 효율이 \(score)%까지 올라갑니다."
        case "weekly-core-cache":
            let variantText = companion.pet.rareVariant == nil ? "잠재 변이 창" : "기존 변이 코어"
            return "\(variantText)이 열려 있어 \(effect.title)가 희귀 분기 확률을 더 안정적으로 밀어줍니다."
        case "weekly-evo-boost":
            return "\(progress.stageLabel) 구간에서 다음 진화까지 남은 상승 폭이 짧아져, 추가 XP가 직접적인 stage 압축으로 연결됩니다."
        default:
            return effect.detail
        }
    }

    private static func intensityLabel(for score: Int) -> String {
        switch score {
        case 85...:
            return "SURGE"
        case 67...:
            return "SYNC"
        default:
            return "TRACE"
        }
    }

    private static func speciesLabel(for species: PetSpecies) -> String {
        species.displayName
    }

    private static func headline(
        for companion: PetCollectionEntry,
        totalScore: Int,
        topEffect: CompanionEffectResonance?
    ) -> String {
        guard let topEffect else {
            return "활성 효과가 아직 없어 기본 성장 상태를 유지합니다."
        }

        if totalScore >= 85 {
            return "\(topEffect.title)가 강하게 물려 이번 주 주력 펫으로 가장 적합합니다."
        }

        if totalScore >= 67 {
            return "\(topEffect.title)와 안정적으로 동기화되어 꾸준한 성장 기대치가 높습니다."
        }

        return "\(topEffect.title)는 받지만, 다른 펫보다 보정 효율은 낮습니다."
    }
}
