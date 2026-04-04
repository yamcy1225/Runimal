import Foundation

public struct WeeklyMission: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let progressLabel: String
    public let progressRatio: Double
    public let completed: Bool

    public init(
        id: String,
        title: String,
        detail: String,
        progressLabel: String,
        progressRatio: Double,
        completed: Bool
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.progressLabel = progressLabel
        self.progressRatio = progressRatio
        self.completed = completed
    }
}

public struct WeeklyBoard: Codable, Equatable, Sendable {
    public let season: WeeklySeason
    public let weekLabel: String
    public let headline: String
    public let totalDistanceKm: Double
    public let runCount: Int
    public let streakDays: Int
    public let discoveredVariants: Int
    public let completedMissionCount: Int
    public let missions: [WeeklyMission]
    public let rewards: [WeeklyReward]

    public init(
        season: WeeklySeason,
        weekLabel: String,
        headline: String,
        totalDistanceKm: Double,
        runCount: Int,
        streakDays: Int,
        discoveredVariants: Int,
        completedMissionCount: Int,
        missions: [WeeklyMission],
        rewards: [WeeklyReward]
    ) {
        self.season = season
        self.weekLabel = weekLabel
        self.headline = headline
        self.totalDistanceKm = totalDistanceKm
        self.runCount = runCount
        self.streakDays = streakDays
        self.discoveredVariants = discoveredVariants
        self.completedMissionCount = completedMissionCount
        self.missions = missions
        self.rewards = rewards
    }
}

public struct WeeklySeason: Codable, Equatable, Sendable {
    public let title: String
    public let subtitle: String
    public let bonus: String
    public let rewardTitle: String
    public let evolutionTitle: String
    public let focusSpecies: PetSpecies
    public let focusVariant: RareVariant?

    public init(
        title: String,
        subtitle: String,
        bonus: String,
        rewardTitle: String,
        evolutionTitle: String,
        focusSpecies: PetSpecies,
        focusVariant: RareVariant?
    ) {
        self.title = title
        self.subtitle = subtitle
        self.bonus = bonus
        self.rewardTitle = rewardTitle
        self.evolutionTitle = evolutionTitle
        self.focusSpecies = focusSpecies
        self.focusVariant = focusVariant
    }

    public var id: String {
        let variantToken = focusVariant?.rawValue ?? "base"
        return "\(focusSpecies.rawValue)-\(variantToken)-\(rewardTitle)"
    }
}

public struct WeeklyReward: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let unlockRequirement: Int

    public init(id: String, title: String, detail: String, unlockRequirement: Int) {
        self.id = id
        self.title = title
        self.detail = detail
        self.unlockRequirement = unlockRequirement
    }
}

public struct WeeklyRewardEffect: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let detail: String

    public init(id: String, title: String, detail: String) {
        self.id = id
        self.title = title
        self.detail = detail
    }
}

public struct CompanionEffectContext: Codable, Equatable, Sendable {
    public let claimedRewardIDs: [String]
    public let activeEffects: [WeeklyRewardEffect]

    public init(claimedRewardIDs: [String], activeEffects: [WeeklyRewardEffect]) {
        self.claimedRewardIDs = claimedRewardIDs
        self.activeEffects = activeEffects
    }
}

public struct CompanionEffectResonance: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let intensityLabel: String
    public let score: Int

    public init(id: String, title: String, detail: String, intensityLabel: String, score: Int) {
        self.id = id
        self.title = title
        self.detail = detail
        self.intensityLabel = intensityLabel
        self.score = score
    }
}

public struct CompanionResonanceSummary: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let companion: PetCollectionEntry
    public let totalScore: Int
    public let intensityLabel: String
    public let headline: String
    public let topEffectTitle: String?

    public init(
        companion: PetCollectionEntry,
        totalScore: Int,
        intensityLabel: String,
        headline: String,
        topEffectTitle: String?
    ) {
        self.id = companion.id
        self.companion = companion
        self.totalScore = totalScore
        self.intensityLabel = intensityLabel
        self.headline = headline
        self.topEffectTitle = topEffectTitle
    }
}
