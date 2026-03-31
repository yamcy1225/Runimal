import Foundation

public struct EggCreationOpportunity: Equatable, Sendable {
    public let eligible: Bool
    public let unlockedAchievementIDs: [String]
    public let isFirstRecoveryRun: Bool
    public let summary: String

    public init(
        eligible: Bool,
        unlockedAchievementIDs: [String],
        isFirstRecoveryRun: Bool,
        summary: String
    ) {
        self.eligible = eligible
        self.unlockedAchievementIDs = unlockedAchievementIDs
        self.isFirstRecoveryRun = isFirstRecoveryRun
        self.summary = summary
    }
}

public enum RunimalEggEngine {
    public static func opportunity(
        for run: CompletedRunRecord,
        unlockedAchievementIDs: Set<String>,
        collectionIsEmpty: Bool,
        eggInventoryIsEmpty: Bool,
        completedRunCount: Int
    ) -> EggCreationOpportunity {
        let unlocked = newlyUnlockedAchievementIDs(for: run, unlockedAchievementIDs: unlockedAchievementIDs)
        let isFirstRecoveryRun = collectionIsEmpty && eggInventoryIsEmpty && completedRunCount <= 1

        if isFirstRecoveryRun {
            return EggCreationOpportunity(
                eligible: true,
                unlockedAchievementIDs: unlocked,
                isFirstRecoveryRun: true,
                summary: "모든 슬롯이 비어 있는 상태에서 첫 러닝을 완주했습니다."
            )
        }

        if unlocked.isEmpty == false {
            return EggCreationOpportunity(
                eligible: true,
                unlockedAchievementIDs: unlocked,
                isFirstRecoveryRun: false,
                summary: "이번 러닝으로 새 업적을 달성했습니다."
            )
        }

        return EggCreationOpportunity(
            eligible: false,
            unlockedAchievementIDs: [],
            isFirstRecoveryRun: false,
            summary: "새 업적을 달성한 러닝 또는 빈 슬롯에서의 첫 러닝만 알로 만들 수 있습니다."
        )
    }

    public static func shell(for run: CompletedRunRecord) -> EggShellType {
        let summary = RunimalSpeciesRuleEngine.summarize(run: run)

        if summary.elevationGainM >= 120 {
            return .stone
        }
        if summary.averagePaceSeconds < 330 || summary.cadence >= 176 {
            return .ember
        }
        if summary.aura == .night {
            return .dusk
        }
        if summary.distanceKm >= 8 || summary.shape == .outAndBack {
            return .gale
        }
        return .moss
    }

    public static func hatchThreshold(
        for shell: EggShellType,
        run: CompletedRunRecord,
        starterBoosted: Bool = false
    ) -> Int {
        if starterBoosted {
            return 92
        }

        let base = max(180, run.reward.experience + 120)
        switch shell {
        case .ember: return base
        case .gale: return base + 30
        case .moss: return base + 20
        case .dusk: return base + 10
        case .stone: return base + 40
        }
    }

    public static func initialExperience(
        for run: CompletedRunRecord,
        starterBoosted: Bool = false
    ) -> Int {
        if starterBoosted {
            return max(52, run.reward.experience / 2)
        }
        return max(20, run.reward.experience / 3)
    }

    public static func incubationExperienceGain(
        for run: CompletedRunRecord,
        egg: EggInventoryEntry
    ) -> Int {
        if egg.starterBoosted && egg.incubationRunIDs.isEmpty {
            return max(run.reward.experience, egg.hatchThreshold - egg.storedExperience)
        }
        return run.reward.experience
    }

    public static func starterGrowthSeed(for egg: EggInventoryEntry) -> Int {
        egg.starterBoosted ? 110 : 0
    }

    public static func title(for shell: EggShellType) -> String {
        switch shell {
        case .ember, .gale, .moss, .dusk, .stone:
            return "???"
        }
    }

    public static func shellLabel(for shell: EggShellType) -> String {
        switch shell {
        case .ember: return "EMBER SHELL"
        case .gale: return "GALE SHELL"
        case .moss: return "MOSS SHELL"
        case .dusk: return "DUSK SHELL"
        case .stone: return "STONE SHELL"
        }
    }

    public static func hint(for shell: EggShellType) -> String {
        switch shell {
        case .ember: return "[데이터 스캔 중...] 높은 케이던스 파동에 반응하는 질주 코드가 감지됩니다."
        case .gale: return "[데이터 스캔 중...] 장거리 주파수와 동기화되는 바람 계열 코드가 떠오릅니다."
        case .moss: return "[데이터 스캔 중...] 균형 잡힌 러닝 로그가 생장형 신호를 증폭합니다."
        case .dusk: return "[데이터 스캔 중...] 야간 주파수와 변칙 리듬에 반응하는 그림자 코드를 포착했습니다."
        case .stone: return "[데이터 스캔 중...] 상승 고도 로그가 방어형 광물 코드와 연결됩니다."
        }
    }

    public static func scanHeadline(for shell: EggShellType) -> String {
        switch shell {
        case .ember: return "HIGH CADENCE WAVE DETECTED"
        case .gale: return "LONG RANGE SYNC DETECTED"
        case .moss: return "BALANCED GROWTH PATTERN FOUND"
        case .dusk: return "NIGHT SIGNAL INTERFERENCE LOCKED"
        case .stone: return "ELEVATION CORE RESPONSE FOUND"
        }
    }

    public static func scanLogLines(for shell: EggShellType) -> [String] {
        switch shell {
        case .ember:
            return [
                "RUN TRACE // cadence surge packets are stacking.",
                "ODDS SHIFT // spark-class entities may decode more often."
            ]
        case .gale:
            return [
                "RANGE TRACE // long-distance drift signatures detected.",
                "ODDS SHIFT // wind-class entities are gaining sync weight."
            ]
        case .moss:
            return [
                "BALANCE TRACE // stable rhythm and recovery remain aligned.",
                "ODDS SHIFT // growth-class entities are seeding quietly."
            ]
        case .dusk:
            return [
                "NIGHT TRACE // low-light interference is still active.",
                "ODDS SHIFT // shadow-class entities are approaching signal lock."
            ]
        case .stone:
            return [
                "CLIMB TRACE // elevation fragments are packed into the shell.",
                "ODDS SHIFT // guard-class entities are hardening the decode."
            ]
        }
    }

    public static func hatchPet(
        from egg: EggInventoryEntry,
        using runs: [CompletedRunRecord],
        claimedRewardIDs: Set<String>
    ) -> GeneratedPet {
        let totalWeights = weightedSpecies(from: egg, using: runs)
        let totalScore = max(totalWeights.values.reduce(0, +), 1)
        let token = abs((egg.id + runs.map(\.id).joined()).hashValue)
        let target = token % totalScore
        var cursor = 0

        let orderedSpecies = PetSpecies.allCases
        let chosenSpecies = orderedSpecies.first { species in
            cursor += totalWeights[species, default: 0]
            return target < cursor
        } ?? dominantSpecies(in: totalWeights)

        let summary = summarize(runs: runs, fallbackShell: egg.shell)
        let basePet = RunimalGameEngine.generatePet(from: summary, claimedRewardIDs: claimedRewardIDs)

        return GeneratedPet(
            species: chosenSpecies,
            element: basePet.element,
            palette: basePet.palette,
            rareVariant: basePet.rareVariant,
            explanation: basePet.explanation + [hint(for: egg.shell)],
            stats: basePet.stats
        )
    }

    public static func newlyUnlockedAchievementIDs(
        for run: CompletedRunRecord,
        unlockedAchievementIDs: Set<String>
    ) -> [String] {
        achievementIDs(for: run).filter { unlockedAchievementIDs.contains($0) == false }
    }

    private static func achievementIDs(for run: CompletedRunRecord) -> [String] {
        var ids: [String] = []

        if run.distanceMeters >= 5000 {
            ids.append("distance-5k")
        }
        if (run.cadence ?? 0) >= 170 {
            ids.append("cadence-170")
        }
        if run.elevationGainM >= 60 {
            ids.append("climb-60")
        }
        if isNight(run.startedAt) {
            ids.append("night-run")
        }

        return ids
    }

    private static func weightedSpecies(from egg: EggInventoryEntry, using runs: [CompletedRunRecord]) -> [PetSpecies: Int] {
        RunimalSpeciesRuleEngine.shellBiasedScores(for: egg.shell, runs: runs)
    }

    private static func summarize(runs: [CompletedRunRecord], fallbackShell: EggShellType) -> RunSummary {
        RunimalSpeciesRuleEngine.summarize(runs: runs, fallbackShell: fallbackShell)
    }

    private static func dominantSpecies(in weights: [PetSpecies: Int]) -> PetSpecies {
        weights.max(by: { $0.value < $1.value })?.key ?? .seedle
    }
    private static func isNight(_ date: Date) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        return hour < 6 || hour >= 20
    }
}
