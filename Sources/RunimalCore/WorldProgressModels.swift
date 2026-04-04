import Foundation

public struct WorldRunImpact: Codable, Equatable, Sendable {
    public let regionID: String
    public let regionTitle: String
    public let seasonID: String?
    public let seasonTitle: String?
    public let episodeID: String?
    public let episodeTitle: String?
    public let unlockedRegion: Bool
    public let unlockedSeason: Bool
    public let unlockedEpisode: Bool
    public let regionRunCountDelta: Int
    public let seasonRunCountDelta: Int
    public let episodeRunCountDelta: Int
    public let distanceKmDelta: Double
    public let elevationGainDelta: Int
    public let nightRunDelta: Int
    public let cadencePeakDelta: Int

    public init(
        regionID: String,
        regionTitle: String,
        seasonID: String?,
        seasonTitle: String?,
        episodeID: String?,
        episodeTitle: String?,
        unlockedRegion: Bool,
        unlockedSeason: Bool,
        unlockedEpisode: Bool,
        regionRunCountDelta: Int = 1,
        seasonRunCountDelta: Int = 1,
        episodeRunCountDelta: Int = 1,
        distanceKmDelta: Double,
        elevationGainDelta: Int,
        nightRunDelta: Int,
        cadencePeakDelta: Int
    ) {
        self.regionID = regionID
        self.regionTitle = regionTitle
        self.seasonID = seasonID
        self.seasonTitle = seasonTitle
        self.episodeID = episodeID
        self.episodeTitle = episodeTitle
        self.unlockedRegion = unlockedRegion
        self.unlockedSeason = unlockedSeason
        self.unlockedEpisode = unlockedEpisode
        self.regionRunCountDelta = regionRunCountDelta
        self.seasonRunCountDelta = seasonRunCountDelta
        self.episodeRunCountDelta = episodeRunCountDelta
        self.distanceKmDelta = distanceKmDelta
        self.elevationGainDelta = elevationGainDelta
        self.nightRunDelta = nightRunDelta
        self.cadencePeakDelta = cadencePeakDelta
    }
}

public struct WorldRegionProgress: Codable, Equatable, Identifiable, Sendable {
    public let regionID: String
    public let title: String
    public let runCount: Int
    public let totalDistanceKm: Double
    public let unlockedAt: Date
    public let lastRunAt: Date

    public var id: String { regionID }

    public init(
        regionID: String,
        title: String,
        runCount: Int,
        totalDistanceKm: Double,
        unlockedAt: Date,
        lastRunAt: Date
    ) {
        self.regionID = regionID
        self.title = title
        self.runCount = runCount
        self.totalDistanceKm = totalDistanceKm
        self.unlockedAt = unlockedAt
        self.lastRunAt = lastRunAt
    }
}

public struct WorldSeasonProgress: Codable, Equatable, Identifiable, Sendable {
    public let seasonID: String
    public let title: String
    public let runCount: Int
    public let totalDistanceKm: Double
    public let unlockedAt: Date
    public let lastRunAt: Date

    public var id: String { seasonID }

    public init(
        seasonID: String,
        title: String,
        runCount: Int,
        totalDistanceKm: Double,
        unlockedAt: Date,
        lastRunAt: Date
    ) {
        self.seasonID = seasonID
        self.title = title
        self.runCount = runCount
        self.totalDistanceKm = totalDistanceKm
        self.unlockedAt = unlockedAt
        self.lastRunAt = lastRunAt
    }
}

public struct WorldEpisodeProgress: Codable, Equatable, Identifiable, Sendable {
    public let episodeID: String
    public let title: String
    public let regionID: String
    public let seasonID: String
    public let runCount: Int
    public let totalDistanceKm: Double
    public let nightRunCount: Int
    public let cadencePeak: Int
    public let totalElevationGainM: Int
    public let unlockedAt: Date?
    public let lastRunAt: Date

    public var id: String { episodeID }

    public init(
        episodeID: String,
        title: String,
        regionID: String,
        seasonID: String,
        runCount: Int,
        totalDistanceKm: Double,
        nightRunCount: Int,
        cadencePeak: Int,
        totalElevationGainM: Int,
        unlockedAt: Date?,
        lastRunAt: Date
    ) {
        self.episodeID = episodeID
        self.title = title
        self.regionID = regionID
        self.seasonID = seasonID
        self.runCount = runCount
        self.totalDistanceKm = totalDistanceKm
        self.nightRunCount = nightRunCount
        self.cadencePeak = cadencePeak
        self.totalElevationGainM = totalElevationGainM
        self.unlockedAt = unlockedAt
        self.lastRunAt = lastRunAt
    }
}

public struct WorldProgressSnapshot: Codable, Equatable, Sendable {
    public let regions: [WorldRegionProgress]
    public let seasons: [WorldSeasonProgress]
    public let episodes: [WorldEpisodeProgress]
    public let lastImpact: WorldRunImpact?
    public let lastUpdatedAt: Date?

    public init(
        regions: [WorldRegionProgress],
        seasons: [WorldSeasonProgress],
        episodes: [WorldEpisodeProgress],
        lastImpact: WorldRunImpact?,
        lastUpdatedAt: Date?
    ) {
        self.regions = regions
        self.seasons = seasons
        self.episodes = episodes
        self.lastImpact = lastImpact
        self.lastUpdatedAt = lastUpdatedAt
    }

    public static let empty = WorldProgressSnapshot(
        regions: [],
        seasons: [],
        episodes: [],
        lastImpact: nil,
        lastUpdatedAt: nil
    )
}
