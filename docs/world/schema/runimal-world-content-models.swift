import Foundation

// Draft-only content models for lore-driven expansion packs.
// This file lives in docs/ and is not wired into build targets yet.

struct WorldContentPack: Codable {
    let schemaVersion: String
    let project: String
    let description: String
    let contentPack: ContentPackSummary
    let speciesBible: [SpeciesBibleEntry]
    let mutationFamilies: [MutationFamilyEntry]
    let rareVariants: [VariantNarrativeEntry]
    let regions: [RegionPackEntry]
    let seasons: [SeasonPackEntry]
    let narrativeEpisodes: [NarrativeEpisodeEntry]
}

struct ContentPackSummary: Codable {
    let packID: String
    let title: String
    let type: ContentPackType
    let status: ContentStatus
    let playerFacingTheme: String
    let featuredRegionIDs: [String]
    let featuredSpeciesIDs: [String]
    let featuredVariantIDs: [String]
    let episodeIDs: [String]
}

enum ContentPackType: String, Codable {
    case season
    case expansion
    case event
}

enum ContentStatus: String, Codable {
    case draft
    case review
    case ready
    case shipped
}

struct SpeciesBibleEntry: Codable {
    let speciesID: String
    let displayName: String
    let baseElement: String
    let fantasy: String
    let metricBias: MetricBiasProfile
    let habitatTags: [String]
    let visualKeywords: [String]
    let narrativeHooks: [String]
    let defaultMutationFamilyIDs: [String]
}

struct MutationFamilyEntry: Codable {
    let familyID: String
    let speciesID: String
    let axis: MutationAxis
    let branchName: String
    let unlockHint: String
    let metricBias: PartialMetricBias
    let visualShift: [String]
    let storyTone: String
}

enum MutationAxis: String, Codable {
    case body
    case habitat
    case rhythm
}

struct VariantNarrativeEntry: Codable {
    let variantID: String
    let displayName: String
    let playerFacingName: String
    let triggerHint: String
    let narrativeMeaning: String
    let suggestedSpeciesIDs: [String]
}

struct RegionPackEntry: Codable {
    let regionID: String
    let title: String
    let unlockCondition: String
    let environmentBias: EnvironmentBiasProfile
    let activeSpeciesIDs: [String]
    let activeVariantIDs: [String]
    let narrativeSummary: String
}

struct SeasonPackEntry: Codable {
    let seasonID: String
    let title: String
    let theme: String
    let featuredRegionIDs: [String]
    let featuredSpeciesIDs: [String]
    let featuredVariantIDs: [String]
    let eventHooks: [String]
}

struct NarrativeEpisodeEntry: Codable {
    let episodeID: String
    let seasonID: String
    let regionID: String
    let triggerRules: EpisodeTriggerRules
    let playerFacingText: String
    let rewardPayload: EpisodeRewardPayload
}

struct EpisodeTriggerRules: Codable {
    let completedRunsMin: Int?
    let distanceKmMin: Double?
    let cadenceMin: Int?
    let nightRunRequired: Bool?
    let elevationGainMin: Int?
}

struct EpisodeRewardPayload: Codable {
    let unlockRegionIDs: [String]
    let unlockSpeciesIDs: [String]
    let unlockVariantIDs: [String]
}

struct EnvironmentBiasProfile: Codable {
    let timeAuras: [String]
    let routeShapes: [String]
    let environmentConditions: [String]
}

struct MetricBiasProfile: Codable {
    let distance: BiasLevel
    let paceStability: BiasLevel
    let cadence: BiasLevel
    let elevation: BiasLevel
    let nightAffinity: BiasLevel
    let routeComplexity: BiasLevel
}

struct PartialMetricBias: Codable {
    let distance: BiasLevel?
    let paceStability: BiasLevel?
    let cadence: BiasLevel?
    let elevation: BiasLevel?
    let nightAffinity: BiasLevel?
    let routeComplexity: BiasLevel?
}

enum BiasLevel: String, Codable {
    case low
    case medium
    case high
}
