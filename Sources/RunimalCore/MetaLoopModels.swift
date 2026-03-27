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
