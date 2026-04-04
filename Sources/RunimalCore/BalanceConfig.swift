import Foundation

public enum RunimalBalanceConfig {
    public static var evolutionThresholds: [Int] { evolutionThresholds(for: nil) }
    public static let defaultEvolutionLevelMilestones = [1, 6, 13, 20, 27]
    public static let eggStageLabel = "알"
    public static let finalStageLabel = "성년기"
    public static let evolutionStageLabels = [eggStageLabel, "유아기", "유년기", "청소년기", finalStageLabel]
    public static let companionLevelCap = 50
    public static let companionLateGrowthMilestones: [CompanionLateGrowthMilestone] = [
        CompanionLateGrowthMilestone(
            requiredLevel: 31,
            title: "기록 해석",
            summary: "풍부한 운동 기록에서 숨은 정보를 더 잘 읽기 시작해요.",
            unlockedFeatures: ["기록 태그 4개 보관", "풍부한 기록 해석 강화"],
            bonusLabel: "기록 해석"
        ),
        CompanionLateGrowthMilestone(
            requiredLevel: 35,
            title: "잠재 응축",
            summary: "실시간 동행 중 쌓인 잠재를 더 진하게 끌어올릴 수 있어요.",
            unlockedFeatures: ["잠재 저장 80", "잠재 사용 상한 +4"],
            bonusLabel: "잠재 응축"
        ),
        CompanionLateGrowthMilestone(
            requiredLevel: 40,
            title: "시즌 숙련",
            summary: "시즌과 맞는 기록을 먹였을 때 호흡이 한층 안정돼요.",
            unlockedFeatures: ["시즌 기록 보관", "시즌 반응 강조"],
            bonusLabel: "시즌 숙련"
        ),
        CompanionLateGrowthMilestone(
            requiredLevel: 45,
            title: "이야기 정착",
            summary: "구역과 에피소드 신호를 안정적으로 자기 기록으로 남겨요.",
            unlockedFeatures: ["구역/에피소드 표식 보관", "이야기 신호 정착"],
            bonusLabel: "이야기 정착"
        ),
        CompanionLateGrowthMilestone(
            requiredLevel: 50,
            title: "완성 기록",
            summary: "이후에는 더 오르기보다, 완성된 형태의 기록을 쌓아 가요.",
            unlockedFeatures: ["기록 태그 5개 보관", "잠재 저장 90"],
            bonusLabel: "완성 기록"
        ),
    ]
    public static let companionStageUnlocks: [CompanionStageUnlock] = [
        CompanionStageUnlock(
            stageIndex: 0,
            stageLabel: eggStageLabel,
            title: "기록을 기다리는 상태",
            summary: "아직 성장으로 바뀌기 전 단계예요.",
            unlockedFeatures: ["부화 준비", "첫 기록 대기"],
            nextFocus: "첫 운동 기록을 먹이면 유아기로 넘어가요."
        ),
        CompanionStageUnlock(
            stageIndex: 1,
            stageLabel: "유아기",
            title: "첫 반응이 열려요",
            summary: "먹인 운동 기록을 받아들이며 기본 반응이 생겨요.",
            unlockedFeatures: ["기본 반응", "종족 성향 확인", "기본 교감 보너스"],
            nextFocus: "익숙한 길과 시간대가 쌓이면 유년기로 안정돼요."
        ),
        CompanionStageUnlock(
            stageIndex: 2,
            stageLabel: "유년기",
            title: "취향이 자리 잡아요",
            summary: "자주 달린 길과 시간대가 이 아이의 취향으로 남아요.",
            unlockedFeatures: ["길/시즌 힌트", "기록 선택 폭 확대", "안정 보너스"],
            nextFocus: "러닝 패턴이 더 선명해지면 청소년기 갈래가 드러나요."
        ),
        CompanionStageUnlock(
            stageIndex: 3,
            stageLabel: "청소년기",
            title: "갈래가 드러나요",
            summary: "변이와 이야기 신호를 읽기 시작하고 반응이 더 또렷해져요.",
            unlockedFeatures: ["변이 힌트", "에피소드 신호", "반응 수 증가"],
            nextFocus: "집중해서 키운 방향이 굳으면 성년기로 완성돼요."
        ),
        CompanionStageUnlock(
            stageIndex: 4,
            stageLabel: finalStageLabel,
            title: "완성된 호흡",
            summary: "시즌과 변이 시너지가 안정되고 장기 성장 가치가 열려요.",
            unlockedFeatures: ["장기 성장 보너스", "시즌 시너지 강화", "완성 기록 보관"],
            nextFocus: "이후에는 조합과 기록 운영이 중심이 돼요."
        ),
    ]

    public static let surgePaceSeconds = 310
    public static let steadyPaceSeconds = 340
    public static let surgeCadence = 172
    public static let steadyCadence = 168
    public static let recoveryHeartRate = 172

    public static func companionExperienceRequirement(forNextLevel currentLevel: Int) -> Int {
        let clamped = min(max(currentLevel, 1), companionLevelCap - 1)
        let bandStep: Int
        switch clamped {
        case 1...10:
            bandStep = 0
        case 11...20:
            bandStep = 8
        case 21...30:
            bandStep = 18
        case 31...40:
            bandStep = 34
        default:
            bandStep = 56
        }

        return 22 + (clamped * 4) + ((clamped * clamped) / 5) + bandStep
    }

    public static func companionExperienceTotal(forLevel level: Int) -> Int {
        let clamped = min(max(level, 1), companionLevelCap)
        guard clamped > 1 else { return 0 }

        return (1..<clamped).reduce(0) { partial, currentLevel in
            partial + companionExperienceRequirement(forNextLevel: currentLevel)
        }
    }

    public static func companionLevel(forExperience totalExperience: Int) -> Int {
        let clampedXP = max(totalExperience, 0)
        var level = 1

        while level < companionLevelCap &&
                clampedXP >= companionExperienceTotal(forLevel: level + 1) {
            level += 1
        }

        return level
    }

    public static func companionLevelRatio(for level: Int) -> Double {
        let clamped = min(max(level, 1), companionLevelCap)
        guard companionLevelCap > 1 else { return 1 }
        return min(max(Double(clamped - 1) / Double(companionLevelCap - 1), 0), 1)
    }

    public static func cappedExperienceGain(
        currentExperience: Int,
        proposedGain: Int,
        currentLevel: Int,
        runDistanceKm: Double
    ) -> Int {
        guard runDistanceKm < 10 else { return proposedGain }

        let cappedLevel = min(currentLevel + 1, companionLevelCap)
        guard cappedLevel < companionLevelCap else { return proposedGain }

        let cappedTotalExperience = companionExperienceTotal(forLevel: cappedLevel + 1) - 1
        let remainingWindow = max(cappedTotalExperience - max(currentExperience, 0), 0)
        return min(proposedGain, remainingWindow)
    }

    public static func companionStageUnlock(at stageIndex: Int) -> CompanionStageUnlock? {
        guard companionStageUnlocks.indices.contains(stageIndex) else { return nil }
        return companionStageUnlocks[stageIndex]
    }

    public static func unlockedLateGrowthMilestones(forLevel level: Int) -> [CompanionLateGrowthMilestone] {
        companionLateGrowthMilestones.filter { level >= $0.requiredLevel }
    }

    public static func lateGrowthWindow(forLevel level: Int) -> [CompanionLateGrowthMilestone] {
        let unlocked = unlockedLateGrowthMilestones(forLevel: level)
        let next = companionLateGrowthMilestones.first { level < $0.requiredLevel }

        if let current = unlocked.last, let next {
            return [current, next]
        }
        if let current = unlocked.last {
            return [current]
        }
        if let next {
            return [next]
        }
        return []
    }

    public static func lateGrowthFeatures(forLevel level: Int) -> CompanionLateGrowthFeatures {
        var insightLabelLimit = 2
        var storedPotentialCap = 60
        var potentialSpendCapBonus = 0
        var seasonRecordEcho = false
        var preservesWorldSignals = false
        var completedRecordMark = false

        if level >= 31 {
            insightLabelLimit = 4
        }
        if level >= 35 {
            storedPotentialCap = 80
            potentialSpendCapBonus = 4
        }
        if level >= 40 {
            seasonRecordEcho = true
        }
        if level >= 45 {
            preservesWorldSignals = true
        }
        if level >= 50 {
            insightLabelLimit = 5
            storedPotentialCap = 90
            potentialSpendCapBonus = 6
            completedRecordMark = true
        }

        return CompanionLateGrowthFeatures(
            insightLabelLimit: insightLabelLimit,
            storedPotentialCap: storedPotentialCap,
            potentialSpendCapBonus: potentialSpendCapBonus,
            seasonRecordEcho: seasonRecordEcho,
            preservesWorldSignals: preservesWorldSignals,
            completedRecordMark: completedRecordMark
        )
    }

    public static func evolutionProfile(for species: PetSpecies) -> CompanionEvolutionProfile {
        switch species {
        case .seedle:
            return CompanionEvolutionProfile(
                species: species,
                summary: "던스프리그는 첫 반응은 빠르되, 성장 갈래가 완전히 자리 잡는 시점은 꽤 뒤로 미룹니다.",
                levelMilestones: [1, 5, 11, 18, 24]
            )
        case .sparkfang:
            return CompanionEvolutionProfile(
                species: species,
                summary: "신더래시는 초반 반응은 빠르지만, 성년기는 템포와 열기를 오래 유지해야 안정됩니다.",
                levelMilestones: [1, 5, 12, 19, 25]
            )
        case .windrunner:
            return CompanionEvolutionProfile(
                species: species,
                summary: "에이라리스는 장거리 적응형이라 초중후반 간격이 가장 고르게 벌어지는 표준 장기 성장선으로 둡니다.",
                levelMilestones: [1, 6, 13, 20, 27]
            )
        case .mosshop:
            return CompanionEvolutionProfile(
                species: species,
                summary: "모스베일은 안정된 호흡을 오래 쌓아야 성숙해지는 종이라 중후반 단계 요구치를 더 높게 둡니다.",
                levelMilestones: [1, 6, 14, 21, 28]
            )
        case .stoneback:
            return CompanionEvolutionProfile(
                species: species,
                summary: "크래그맨틀은 몸이 무겁고 늦게 크게 자라는 종이라 유년기 이후 모든 단계가 한 템포 늦습니다.",
                levelMilestones: [1, 6, 15, 22, 29]
            )
        case .shadebit:
            return CompanionEvolutionProfile(
                species: species,
                summary: "셰이드빗은 황혼 계열 특수종이라 형태 안정화가 가장 늦고, 최종 완성도 가장 뒤에 옵니다.",
                levelMilestones: [1, 6, 16, 23, 30]
            )
        }
    }

    public static func evolutionLevelMilestones(for species: PetSpecies?) -> [Int] {
        guard let species else { return defaultEvolutionLevelMilestones }
        return evolutionProfile(for: species).levelMilestones
    }

    public static func evolutionThresholds(for species: PetSpecies?) -> [Int] {
        evolutionLevelMilestones(for: species).map { companionExperienceTotal(forLevel: $0) }
    }

    public static func evolutionMilestones(for species: PetSpecies?) -> [CompanionEvolutionMilestone] {
        let levels = evolutionLevelMilestones(for: species)
        let profileSummary = species.map { evolutionProfile(for: $0).summary }
        return evolutionStageLabels.enumerated().map { index, label in
            let level = levels[index]
            return CompanionEvolutionMilestone(
                stageIndex: index,
                stageLabel: label,
                requiredLevel: level,
                requiredExperience: companionExperienceTotal(forLevel: level),
                summary: profileSummary
            )
        }
    }
}

public struct CompanionStageUnlock: Equatable, Identifiable, Sendable {
    public let stageIndex: Int
    public let stageLabel: String
    public let title: String
    public let summary: String
    public let unlockedFeatures: [String]
    public let nextFocus: String

    public var id: String {
        "\(stageIndex)-\(stageLabel)"
    }

    public init(
        stageIndex: Int,
        stageLabel: String,
        title: String,
        summary: String,
        unlockedFeatures: [String],
        nextFocus: String
    ) {
        self.stageIndex = stageIndex
        self.stageLabel = stageLabel
        self.title = title
        self.summary = summary
        self.unlockedFeatures = unlockedFeatures
        self.nextFocus = nextFocus
    }
}

public struct CompanionLateGrowthMilestone: Equatable, Identifiable, Sendable {
    public let requiredLevel: Int
    public let title: String
    public let summary: String
    public let unlockedFeatures: [String]
    public let bonusLabel: String

    public var id: String {
        "late-\(requiredLevel)-\(title)"
    }

    public init(
        requiredLevel: Int,
        title: String,
        summary: String,
        unlockedFeatures: [String],
        bonusLabel: String
    ) {
        self.requiredLevel = requiredLevel
        self.title = title
        self.summary = summary
        self.unlockedFeatures = unlockedFeatures
        self.bonusLabel = bonusLabel
    }
}

public struct CompanionEvolutionProfile: Equatable, Sendable {
    public let species: PetSpecies
    public let summary: String
    public let levelMilestones: [Int]

    public init(species: PetSpecies, summary: String, levelMilestones: [Int]) {
        self.species = species
        self.summary = summary
        self.levelMilestones = levelMilestones
    }
}

public struct CompanionEvolutionMilestone: Equatable, Identifiable, Sendable {
    public let stageIndex: Int
    public let stageLabel: String
    public let requiredLevel: Int
    public let requiredExperience: Int
    public let summary: String?

    public var id: String {
        "\(stageIndex)-\(stageLabel)-\(requiredLevel)"
    }

    public init(
        stageIndex: Int,
        stageLabel: String,
        requiredLevel: Int,
        requiredExperience: Int,
        summary: String?
    ) {
        self.stageIndex = stageIndex
        self.stageLabel = stageLabel
        self.requiredLevel = requiredLevel
        self.requiredExperience = requiredExperience
        self.summary = summary
    }
}

public struct CompanionStageInteractionPolicy: Equatable, Sendable {
    public let stageIndex: Int
    public let unlockedEvents: Set<CompanionProgressionEvent>
    public let capBonus: Int
    public let seasonAffinityBonus: Int

    public init(
        stageIndex: Int,
        unlockedEvents: Set<CompanionProgressionEvent>,
        capBonus: Int,
        seasonAffinityBonus: Int
    ) {
        self.stageIndex = stageIndex
        self.unlockedEvents = unlockedEvents
        self.capBonus = capBonus
        self.seasonAffinityBonus = seasonAffinityBonus
    }
}

public enum CompanionProgressionEvent: String, CaseIterable, Sendable {
    case firstFeedOfDay
    case matchingSpecies
    case matchingVariant
    case seasonAffinity
    case masteryLink
    case homeRegion
    case episodeSignal
    case regionUnlock
    case seasonUnlock
    case episodeUnlock

    public var label: String {
        switch self {
        case .firstFeedOfDay: return "하루 첫 교감"
        case .matchingSpecies: return "잘 맞는 종류"
        case .matchingVariant: return "변이 공명"
        case .seasonAffinity: return "시즌 호흡"
        case .masteryLink: return "목표 달성"
        case .homeRegion: return "익숙한 길"
        case .episodeSignal: return "이야기 신호"
        case .regionUnlock: return "새 구역"
        case .seasonUnlock: return "새 시즌"
        case .episodeUnlock: return "에피소드 개방"
        }
    }

    public var fixedExperience: Int {
        switch self {
        case .firstFeedOfDay: return 10
        case .matchingSpecies: return 14
        case .matchingVariant: return 12
        case .seasonAffinity: return 8
        case .masteryLink: return 10
        case .homeRegion: return 8
        case .episodeSignal: return 14
        case .regionUnlock: return 18
        case .seasonUnlock: return 22
        case .episodeUnlock: return 28
        }
    }
}

public struct CompanionInteractionBonus: Equatable, Sendable {
    public let bonusExperience: Int
    public let labels: [String]
    public let capped: Bool

    public init(bonusExperience: Int, labels: [String], capped: Bool) {
        self.bonusExperience = bonusExperience
        self.labels = labels
        self.capped = capped
    }
}

public struct CompanionLateGrowthBonus: Equatable, Sendable {
    public let bonusExperience: Int
    public let labels: [String]

    public init(bonusExperience: Int, labels: [String]) {
        self.bonusExperience = bonusExperience
        self.labels = labels
    }
}

public struct CompanionLateGrowthFeatures: Equatable, Sendable {
    public let insightLabelLimit: Int
    public let storedPotentialCap: Int
    public let potentialSpendCapBonus: Int
    public let seasonRecordEcho: Bool
    public let preservesWorldSignals: Bool
    public let completedRecordMark: Bool

    public init(
        insightLabelLimit: Int,
        storedPotentialCap: Int,
        potentialSpendCapBonus: Int,
        seasonRecordEcho: Bool,
        preservesWorldSignals: Bool,
        completedRecordMark: Bool
    ) {
        self.insightLabelLimit = insightLabelLimit
        self.storedPotentialCap = storedPotentialCap
        self.potentialSpendCapBonus = potentialSpendCapBonus
        self.seasonRecordEcho = seasonRecordEcho
        self.preservesWorldSignals = preservesWorldSignals
        self.completedRecordMark = completedRecordMark
    }
}

public enum RunimalCompanionProgressionEngine {
    public static func interactionPolicy(for stageIndex: Int) -> CompanionStageInteractionPolicy {
        let clamped = min(max(stageIndex, 0), RunimalBalanceConfig.evolutionStageLabels.count - 1)
        let baseEvents: Set<CompanionProgressionEvent> = [
            .firstFeedOfDay,
            .matchingSpecies,
            .masteryLink,
            .regionUnlock,
            .seasonUnlock,
            .episodeUnlock,
        ]

        switch clamped {
        case 0, 1:
            return CompanionStageInteractionPolicy(
                stageIndex: clamped,
                unlockedEvents: baseEvents,
                capBonus: 0,
                seasonAffinityBonus: 0
            )
        case 2:
            return CompanionStageInteractionPolicy(
                stageIndex: clamped,
                unlockedEvents: baseEvents.union([.seasonAffinity, .homeRegion]),
                capBonus: 0,
                seasonAffinityBonus: 0
            )
        case 3:
            return CompanionStageInteractionPolicy(
                stageIndex: clamped,
                unlockedEvents: baseEvents.union([.seasonAffinity, .homeRegion, .matchingVariant, .episodeSignal]),
                capBonus: 4,
                seasonAffinityBonus: 0
            )
        default:
            return CompanionStageInteractionPolicy(
                stageIndex: clamped,
                unlockedEvents: baseEvents.union([.seasonAffinity, .homeRegion, .matchingVariant, .episodeSignal]),
                capBonus: 8,
                seasonAffinityBonus: 6
            )
        }
    }

    public static func interactionBonus(
        baseExperience: Int,
        events: [CompanionProgressionEvent],
        stageIndex: Int = RunimalBalanceConfig.evolutionStageLabels.count - 1
    ) -> CompanionInteractionBonus {
        guard events.isEmpty == false else {
            return CompanionInteractionBonus(bonusExperience: 0, labels: [], capped: false)
        }

        let policy = interactionPolicy(for: stageIndex)
        let uniqueEvents = Array(NSOrderedSet(array: events)) as? [CompanionProgressionEvent] ?? events
        let filteredEvents = uniqueEvents.filter { policy.unlockedEvents.contains($0) }
        guard filteredEvents.isEmpty == false else {
            return CompanionInteractionBonus(bonusExperience: 0, labels: [], capped: false)
        }

        var labels = filteredEvents.map(\.label)
        var rawBonus = filteredEvents.reduce(0) { $0 + $1.fixedExperience }

        if policy.seasonAffinityBonus > 0, filteredEvents.contains(.seasonAffinity) {
            rawBonus += policy.seasonAffinityBonus
            labels.append("완성 호흡")
        }

        let rawCap = Int((Double(max(baseExperience, 1)) * 0.4).rounded()) + policy.capBonus
        let cap = min(48 + policy.capBonus, max(16, rawCap))
        let appliedBonus = min(rawBonus, cap)

        return CompanionInteractionBonus(
            bonusExperience: appliedBonus,
            labels: labels,
            capped: rawBonus > cap
        )
    }

    public static func lateGrowthBonus(
        level: Int,
        dataProfile: RunCoreDataProfile,
        potentialSpend: Int,
        seasonAligned: Bool,
        worldImpact: WorldRunImpact?
    ) -> CompanionLateGrowthBonus {
        guard level >= 31 else {
            return CompanionLateGrowthBonus(bonusExperience: 0, labels: [])
        }

        var rawBonus = 0
        var labels: [String] = []

        if level >= 31, dataProfile.bonusExperience >= 8 {
            rawBonus += 6
            labels.append("기록 해석")
        }
        if level >= 35, potentialSpend > 0 {
            rawBonus += 6
            labels.append("잠재 응축")
        }
        if level >= 40, seasonAligned {
            rawBonus += 8
            labels.append("시즌 숙련")
        }
        if level >= 45, worldImpact?.episodeID != nil || worldImpact?.unlockedRegion == true || worldImpact?.unlockedSeason == true || worldImpact?.unlockedEpisode == true {
            rawBonus += 10
            labels.append("이야기 정착")
        }

        let appliedBonus = min(rawBonus, 18)
        return CompanionLateGrowthBonus(
            bonusExperience: appliedBonus,
            labels: Array(labels.prefix(3))
        )
    }

    public static func lateGrowthRetentionLabels(
        level: Int,
        run: CompletedRunRecord,
        dataProfile: RunCoreDataProfile,
        seasonTitle: String?,
        seasonAligned: Bool
    ) -> [String] {
        let features = RunimalBalanceConfig.lateGrowthFeatures(forLevel: level)
        var labels: [String] = []

        if dataProfile.bonusExperience > 0 {
            labels.append("기록 밀도 +\(dataProfile.bonusExperience)")
        }

        labels.append(
            contentsOf: RunimalRunCoreGrowthBalanceEngine.retainedDataLabels(
                for: run,
                limit: features.insightLabelLimit
            )
        )

        if features.seasonRecordEcho, seasonAligned {
            labels.append("\(seasonTitle ?? "시즌") 기록 보관")
        }

        if features.completedRecordMark,
           dataProfile.informationScore >= 10 || run.worldImpact != nil {
            labels.append("완성 기록 보관")
        }

        if features.preservesWorldSignals {
            labels.append(contentsOf: lateGrowthWorldSignalLabels(for: run.worldImpact))
        }

        let unique = Array(NSOrderedSet(array: labels)) as? [String] ?? labels
        let labelCap = features.completedRecordMark ? 10 : (features.preservesWorldSignals ? 9 : 6)
        return Array(unique.prefix(labelCap))
    }

    private static func lateGrowthWorldSignalLabels(for impact: WorldRunImpact?) -> [String] {
        guard let impact else { return [] }

        var labels: [String] = []

        if impact.unlockedRegion {
            labels.append("\(impact.regionTitle) 정착")
        }
        if impact.unlockedEpisode, let episodeTitle = impact.episodeTitle {
            labels.append("\(episodeTitle) 기록")
        } else if impact.episodeID != nil {
            labels.append("이야기 신호 보관")
        }
        if impact.unlockedSeason, let seasonTitle = impact.seasonTitle {
            labels.append("\(seasonTitle) 보관")
        }

        return labels
    }
}

public struct EvolutionTreeNode: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let status: String
    public let unlocked: Bool
    public let current: Bool

    public init(id: String, title: String, detail: String, status: String, unlocked: Bool, current: Bool) {
        self.id = id
        self.title = title
        self.detail = detail
        self.status = status
        self.unlocked = unlocked
        self.current = current
    }
}

public extension RunimalGameEngine {
    static func evolutionTree(
        for pet: GeneratedPet,
        progress: EvolutionProgress,
        season: WeeklySeason? = nil
    ) -> [EvolutionTreeNode] {
        let titles = evolutionTitles(for: pet, season: season)
        let currentIndex = max(
            0,
            RunimalBalanceConfig.evolutionStageLabels.firstIndex(of: progress.stageLabel) ?? 0
        )

        return titles.enumerated().map { index, title in
            let status: String

            if index < currentIndex {
                status = "cleared"
            } else if index == currentIndex {
                status = "current"
            } else {
                status = "locked"
            }

            return EvolutionTreeNode(
                id: "stage-\(index)-\(title)",
                title: title,
                detail: evolutionDetail(for: pet, stageIndex: index, season: season),
                status: status,
                unlocked: index <= currentIndex,
                current: index == currentIndex
            )
        }
    }

    static func seasonAffinity(for pet: GeneratedPet, season: WeeklySeason) -> Bool {
        pet.species == season.focusSpecies || pet.rareVariant == season.focusVariant
    }

    static func balanceTuningNotes(for pet: GeneratedPet) -> [String] {
        let milestoneText = RunimalBalanceConfig.evolutionMilestones(for: pet.species)
            .dropFirst()
            .map { "\($0.stageLabel) Lv.\($0.requiredLevel)" }
            .joined(separator: " / ")
        let passiveText = pet.rareVariant.flatMap { RareVariantMeta.passives[$0] } ?? "없음"

        var notes = [
            "진화 레벨 기준: \(milestoneText)",
            "스프린트 판정: \(RunimalBalanceConfig.surgePaceSeconds)s 이하 + 케이던스 \(RunimalBalanceConfig.surgeCadence)+",
        ]

        if pet.rareVariant != nil {
            notes.append("현재 변이 패시브: \(passiveText)")
        } else {
            notes.append("기본 동행: 다음 러닝에서 페이스와 경로 패턴에 따라 특별한 모습이 열릴 수 있습니다.")
        }

        return notes
    }

    static func mythicTitle(for pet: GeneratedPet, season: WeeklySeason? = nil) -> String {
        evolutionTitles(for: pet, season: season).last ?? RunimalBalanceConfig.finalStageLabel
    }

    static func mythicSignalLine(for pet: GeneratedPet, season: WeeklySeason? = nil) -> String {
        let title = mythicTitle(for: pet, season: season)
        if let season, seasonAffinity(for: pet, season: season) {
            return "\(title)이 이번 시즌 흐름과 잘 맞아 더 또렷하게 자랍니다."
        }

        if let rareVariant = pet.rareVariant,
           let passive = RareVariantMeta.passives[rareVariant] {
            return "\(title)에서는 \(passive)"
        }

        return "\(title)은 장기 성장의 마무리 단계입니다."
    }

    private static func evolutionTitles(for pet: GeneratedPet, season: WeeklySeason?) -> [String] {
        let apexTitle: String

        if let season, seasonAffinity(for: pet, season: season) {
            apexTitle = "\(pet.displayBaseName) \(season.title)"
        } else {
            switch pet.rareVariant {
            case .tempoSurge:
                apexTitle = "\(pet.displayBaseName) 빠른 질주"
            case .zenBloom:
                apexTitle = "\(pet.displayBaseName) 편안한 호흡"
            case .summitHeart:
                apexTitle = "\(pet.displayBaseName) 언덕 돌파"
            case .eclipseMark:
                apexTitle = "\(pet.displayBaseName) 밤의 흔적"
            case .loopSigil:
                apexTitle = "\(pet.displayBaseName) 익숙한 길"
            case nil:
                apexTitle = "\(pet.displayBaseName) 성년기"
            }
        }

        return [
            RunimalBalanceConfig.eggStageLabel,
            "\(pet.displayBaseName) 유아기",
            "\(pet.displayBaseName) 유년기",
            "\(pet.displayBaseName) 청소년기",
            apexTitle,
        ]
    }

    private static func evolutionDetail(for pet: GeneratedPet, stageIndex: Int, season: WeeklySeason?) -> String {
        switch stageIndex {
        case 0:
            return "첫 러닝 흔적을 흡수하는 준비 단계입니다."
        case 1:
            return "거리와 케이던스가 이 동행의 기본 성향을 잡아 줍니다."
        case 2:
            return "러닝 시간대와 특별한 조건이 겉모습과 분위기를 바꿉니다."
        case 3:
            return "누적 XP와 반복된 패턴이 이 동행만의 역할을 분명하게 만듭니다."
        default:
            let variantLabel = pet.rareVariant.map { RareVariantMeta.labels[$0] ?? $0.rawValue } ?? "기본"
            let elementLabel = elementLabel(for: pet.element)
            if let season, seasonAffinity(for: pet, season: season) {
                return "\(elementLabel) 성향의 \(variantLabel) 완성 단계입니다. 이번 시즌에서는 \(season.title) 흐름과 특히 잘 맞습니다."
            }
            return "\(elementLabel) 성향의 \(variantLabel) 완성 단계입니다. 꾸준히 함께할수록 장기 보너스가 붙습니다."
        }
    }

    private static func elementLabel(for element: PetElement) -> String {
        switch element {
        case .light: return "빛"
        case .flame: return "불꽃"
        case .leaf: return "풀"
        case .lunar: return "달빛"
        case .earth: return "대지"
        }
    }
}

private extension GeneratedPet {
    var displayBaseName: String {
        species.displayName
    }
}
