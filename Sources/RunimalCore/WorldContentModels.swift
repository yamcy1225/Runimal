import Foundation

public struct WorldContentPack: Codable, Equatable, Sendable {
    public let schemaVersion: String
    public let project: String
    public let description: String
    public let contentPack: ContentPackSummary
    public let speciesBible: [SpeciesBibleEntry]
    public let mutationFamilies: [MutationFamilyEntry]
    public let rareVariants: [VariantNarrativeEntry]
    public let regions: [RegionPackEntry]
    public let seasons: [SeasonPackEntry]
    public let narrativeEpisodes: [NarrativeEpisodeEntry]

    public init(
        schemaVersion: String,
        project: String,
        description: String,
        contentPack: ContentPackSummary,
        speciesBible: [SpeciesBibleEntry],
        mutationFamilies: [MutationFamilyEntry],
        rareVariants: [VariantNarrativeEntry],
        regions: [RegionPackEntry],
        seasons: [SeasonPackEntry],
        narrativeEpisodes: [NarrativeEpisodeEntry]
    ) {
        self.schemaVersion = schemaVersion
        self.project = project
        self.description = description
        self.contentPack = contentPack
        self.speciesBible = speciesBible
        self.mutationFamilies = mutationFamilies
        self.rareVariants = rareVariants
        self.regions = regions
        self.seasons = seasons
        self.narrativeEpisodes = narrativeEpisodes
    }
}

public struct ContentPackSummary: Codable, Equatable, Sendable {
    public let packID: String
    public let title: String
    public let type: String
    public let status: String
    public let playerFacingTheme: String
    public let featuredRegionIDs: [String]
    public let featuredSpeciesIDs: [String]
    public let featuredVariantIDs: [String]
    public let episodeIDs: [String]
}

public struct SpeciesBibleEntry: Codable, Equatable, Sendable, Identifiable {
    public let speciesID: String
    public let displayName: String
    public let baseElement: String
    public let fantasy: String
    public let metricBias: MetricBiasProfile
    public let habitatTags: [String]
    public let visualKeywords: [String]
    public let narrativeHooks: [String]
    public let defaultMutationFamilyIDs: [String]

    public var id: String { speciesID }
}

public struct MutationFamilyEntry: Codable, Equatable, Sendable, Identifiable {
    public let familyID: String
    public let speciesID: String
    public let axis: String
    public let branchName: String
    public let unlockHint: String
    public let metricBias: PartialMetricBias
    public let visualShift: [String]
    public let storyTone: String

    public var id: String { familyID }
}

public struct VariantNarrativeEntry: Codable, Equatable, Sendable, Identifiable {
    public let variantID: String
    public let displayName: String
    public let playerFacingName: String
    public let triggerHint: String
    public let narrativeMeaning: String
    public let suggestedSpeciesIDs: [String]

    public var id: String { variantID }
}

public struct RegionPackEntry: Codable, Equatable, Sendable, Identifiable {
    public let regionID: String
    public let title: String
    public let unlockCondition: String
    public let environmentBias: EnvironmentBiasProfile
    public let activeSpeciesIDs: [String]
    public let activeVariantIDs: [String]
    public let narrativeSummary: String

    public var id: String { regionID }
}

public struct SeasonPackEntry: Codable, Equatable, Sendable, Identifiable {
    public let seasonID: String
    public let title: String
    public let theme: String
    public let featuredRegionIDs: [String]
    public let featuredSpeciesIDs: [String]
    public let featuredVariantIDs: [String]
    public let eventHooks: [String]

    public var id: String { seasonID }
}

public struct NarrativeEpisodeEntry: Codable, Equatable, Sendable, Identifiable {
    public let episodeID: String
    public let seasonID: String
    public let regionID: String
    public let triggerRules: EpisodeTriggerRules
    public let playerFacingText: String
    public let rewardPayload: EpisodeRewardPayload

    public var id: String { episodeID }
}

public struct EpisodeTriggerRules: Codable, Equatable, Sendable {
    public let completedRunsMin: Int?
    public let distanceKmMin: Double?
    public let cadenceMin: Int?
    public let nightRunRequired: Bool?
    public let elevationGainMin: Int?
}

public struct EpisodeRewardPayload: Codable, Equatable, Sendable {
    public let unlockRegionIDs: [String]
    public let unlockSpeciesIDs: [String]
    public let unlockVariantIDs: [String]
}

public struct EnvironmentBiasProfile: Codable, Equatable, Sendable {
    public let timeAuras: [String]
    public let routeShapes: [String]
    public let environmentConditions: [String]
}

public struct MetricBiasProfile: Codable, Equatable, Sendable {
    public let distance: String
    public let paceStability: String
    public let cadence: String
    public let elevation: String
    public let nightAffinity: String
    public let routeComplexity: String
}

public struct PartialMetricBias: Codable, Equatable, Sendable {
    public let distance: String?
    public let paceStability: String?
    public let cadence: String?
    public let elevation: String?
    public let nightAffinity: String?
    public let routeComplexity: String?
}
