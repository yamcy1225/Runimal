import Foundation

public enum PetSpecies: String, Codable, CaseIterable, Sendable {
    case windrunner
    case stoneback
    case sparkfang
    case mosshop
    case shadebit
    case seedle
}

public enum PetElement: String, Codable, Sendable {
    case light
    case flame
    case leaf
    case lunar
    case earth
}

public enum RareVariant: String, Codable, CaseIterable, Sendable {
    case tempoSurge = "tempo-surge"
    case zenBloom = "zen-bloom"
    case summitHeart = "summit-heart"
    case eclipseMark = "eclipse-mark"
    case loopSigil = "loop-sigil"
}

public enum RunTimeAura: String, Codable, CaseIterable, Sendable {
    case dawn
    case day
    case dusk
    case night
}

public enum RouteShape: String, Codable, CaseIterable, Sendable {
    case loop
    case outAndBack = "out-and-back"
    case maze
    case freeform
}

public struct RunSummary: Codable, Equatable, Sendable {
    public let distanceKm: Double
    public let averagePaceSeconds: Int
    public let cadence: Int
    public let elevationGainM: Int
    public let variability: Double
    public let aura: RunTimeAura
    public let shape: RouteShape

    public init(
        distanceKm: Double,
        averagePaceSeconds: Int,
        cadence: Int,
        elevationGainM: Int,
        variability: Double,
        aura: RunTimeAura,
        shape: RouteShape
    ) {
        self.distanceKm = distanceKm
        self.averagePaceSeconds = averagePaceSeconds
        self.cadence = cadence
        self.elevationGainM = elevationGainM
        self.variability = variability
        self.aura = aura
        self.shape = shape
    }
}

public struct LiveRunSnapshot: Codable, Equatable, Sendable {
    public let elapsedSeconds: Int
    public let distanceMeters: Double
    public let currentHeartRate: Double?
    public let cadence: Int?
    public let elevationGainM: Int
    public let averagePaceSeconds: Int?

    public init(
        elapsedSeconds: Int,
        distanceMeters: Double,
        currentHeartRate: Double?,
        cadence: Int?,
        elevationGainM: Int,
        averagePaceSeconds: Int?
    ) {
        self.elapsedSeconds = elapsedSeconds
        self.distanceMeters = distanceMeters
        self.currentHeartRate = currentHeartRate
        self.cadence = cadence
        self.elevationGainM = elevationGainM
        self.averagePaceSeconds = averagePaceSeconds
    }
}

public struct PetStats: Codable, Equatable, Sendable {
    public let vitality: Int
    public let agility: Int
    public let dexterity: Int
    public let focus: Int
    public let defense: Int

    public init(vitality: Int, agility: Int, dexterity: Int, focus: Int, defense: Int) {
        self.vitality = vitality
        self.agility = agility
        self.dexterity = dexterity
        self.focus = focus
        self.defense = defense
    }
}

public struct GeneratedPet: Codable, Equatable, Sendable {
    public let species: PetSpecies
    public let element: PetElement
    public let palette: String
    public let rareVariant: RareVariant?
    public let explanation: [String]
    public let stats: PetStats

    public init(
        species: PetSpecies,
        element: PetElement,
        palette: String,
        rareVariant: RareVariant?,
        explanation: [String],
        stats: PetStats
    ) {
        self.species = species
        self.element = element
        self.palette = palette
        self.rareVariant = rareVariant
        self.explanation = explanation
        self.stats = stats
    }
}

public struct RunQuestStatus: Equatable, Sendable {
    public let label: String
    public let reward: String
    public let completed: Bool
    public let detail: String

    public init(label: String, reward: String, completed: Bool, detail: String) {
        self.label = label
        self.reward = reward
        self.completed = completed
        self.detail = detail
    }
}

public struct WorkoutPlanSuggestion: Codable, Equatable, Sendable {
    public let title: String
    public let summary: String
    public let scheduledDistanceKm: Double
    public let targetPaceBand: String

    public init(title: String, summary: String, scheduledDistanceKm: Double, targetPaceBand: String) {
        self.title = title
        self.summary = summary
        self.scheduledDistanceKm = scheduledDistanceKm
        self.targetPaceBand = targetPaceBand
    }
}

public struct PetCollectionEntry: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let pet: GeneratedPet
    public let level: Int
    public let bond: Int
    public let totalDistanceKm: Double
    public let headline: String

    public init(
        id: String,
        pet: GeneratedPet,
        level: Int,
        bond: Int,
        totalDistanceKm: Double,
        headline: String
    ) {
        self.id = id
        self.pet = pet
        self.level = level
        self.bond = bond
        self.totalDistanceKm = totalDistanceKm
        self.headline = headline
    }
}

public struct VariantCodexEntry: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let variant: RareVariant
    public let label: String
    public let passive: String
    public let detail: String
    public let discovered: Bool

    public init(
        variant: RareVariant,
        label: String,
        passive: String,
        detail: String,
        discovered: Bool
    ) {
        self.id = variant.rawValue
        self.variant = variant
        self.label = label
        self.passive = passive
        self.detail = detail
        self.discovered = discovered
    }
}

public struct RunRewardSummary: Codable, Equatable, Sendable {
    public let pet: GeneratedPet
    public let coreLabel: String
    public let experience: Int
    public let completedQuestCount: Int
    public let flavorText: String

    public init(
        pet: GeneratedPet,
        coreLabel: String,
        experience: Int,
        completedQuestCount: Int,
        flavorText: String
    ) {
        self.pet = pet
        self.coreLabel = coreLabel
        self.experience = experience
        self.completedQuestCount = completedQuestCount
        self.flavorText = flavorText
    }
}

public struct RunJournalEntry: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let createdAt: Date
    public let reward: RunRewardSummary
    public let distanceKm: Double
    public let cadence: Int

    public init(
        id: String,
        createdAt: Date,
        reward: RunRewardSummary,
        distanceKm: Double,
        cadence: Int
    ) {
        self.id = id
        self.createdAt = createdAt
        self.reward = reward
        self.distanceKm = distanceKm
        self.cadence = cadence
    }
}

public struct EvolutionProgress: Codable, Equatable, Sendable {
    public let stageLabel: String
    public let totalExperience: Int
    public let nextThreshold: Int
    public let progressRatio: Double
    public let headline: String

    public init(
        stageLabel: String,
        totalExperience: Int,
        nextThreshold: Int,
        progressRatio: Double,
        headline: String
    ) {
        self.stageLabel = stageLabel
        self.totalExperience = totalExperience
        self.nextThreshold = nextThreshold
        self.progressRatio = progressRatio
        self.headline = headline
    }
}

public struct CompanionGrowthRecord: Codable, Equatable, Identifiable, Sendable {
    public let companionID: String
    public let totalExperience: Int
    public let feedCount: Int
    public let assignedRunIDs: [String]
    public let lastFedAt: Date?

    public var id: String {
        companionID
    }

    public init(
        companionID: String,
        totalExperience: Int,
        feedCount: Int,
        assignedRunIDs: [String],
        lastFedAt: Date?
    ) {
        self.companionID = companionID
        self.totalExperience = totalExperience
        self.feedCount = feedCount
        self.assignedRunIDs = assignedRunIDs
        self.lastFedAt = lastFedAt
    }
}

public struct ForgeInventory: Codable, Equatable, Sendable {
    public let overdriveCharges: Int
    public let seasonSigils: Int

    public init(overdriveCharges: Int, seasonSigils: Int) {
        self.overdriveCharges = overdriveCharges
        self.seasonSigils = seasonSigils
    }
}

public struct EssenceForgeOption: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let cost: Int
    public let rewardLabel: String

    public init(id: String, title: String, detail: String, cost: Int, rewardLabel: String) {
        self.id = id
        self.title = title
        self.detail = detail
        self.cost = cost
        self.rewardLabel = rewardLabel
    }
}

public enum CompanionRole: String, Codable, CaseIterable, Sendable {
    case vanguard
    case relay
    case oracle
}

public struct CompanionBuildState: Codable, Equatable, Identifiable, Sendable {
    public let companionID: String
    public let selectedRole: CompanionRole
    public let unlockedNodeIDs: [String]

    public var id: String {
        companionID
    }

    public init(companionID: String, selectedRole: CompanionRole, unlockedNodeIDs: [String]) {
        self.companionID = companionID
        self.selectedRole = selectedRole
        self.unlockedNodeIDs = unlockedNodeIDs
    }
}

public struct CompanionSkillNode: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let cost: Int
    public let unlocked: Bool

    public init(id: String, title: String, detail: String, cost: Int, unlocked: Bool) {
        self.id = id
        self.title = title
        self.detail = detail
        self.cost = cost
        self.unlocked = unlocked
    }
}

public struct RoutePoint: Codable, Equatable, Identifiable, Sendable {
    public let latitude: Double
    public let longitude: Double
    public let altitude: Double
    public let timestamp: Date

    public var id: String {
        "\(timestamp.timeIntervalSince1970)-\(latitude)-\(longitude)"
    }

    public init(latitude: Double, longitude: Double, altitude: Double, timestamp: Date) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.timestamp = timestamp
    }
}

public struct CompletedRunRecord: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let startedAt: Date
    public let endedAt: Date
    public let distanceMeters: Double
    public let durationSeconds: Int
    public let averageHeartRate: Double?
    public let averagePaceSeconds: Int?
    public let cadence: Int?
    public let elevationGainM: Int
    public let reward: RunRewardSummary
    public let route: [RoutePoint]
    public let source: String

    public init(
        id: String,
        startedAt: Date,
        endedAt: Date,
        distanceMeters: Double,
        durationSeconds: Int,
        averageHeartRate: Double?,
        averagePaceSeconds: Int?,
        cadence: Int?,
        elevationGainM: Int,
        reward: RunRewardSummary,
        route: [RoutePoint],
        source: String
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.distanceMeters = distanceMeters
        self.durationSeconds = durationSeconds
        self.averageHeartRate = averageHeartRate
        self.averagePaceSeconds = averagePaceSeconds
        self.cadence = cadence
        self.elevationGainM = elevationGainM
        self.reward = reward
        self.route = route
        self.source = source
    }
}

public struct RetirableCompanionOffer: Codable, Equatable, Identifiable, Sendable {
    public let companion: PetCollectionEntry
    public let essenceReward: Int
    public let reason: String

    public var id: String {
        companion.id
    }

    public init(companion: PetCollectionEntry, essenceReward: Int, reason: String) {
        self.companion = companion
        self.essenceReward = essenceReward
        self.reason = reason
    }
}

public struct SyncDiagnosticEvent: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let timestamp: Date
    public let title: String
    public let detail: String

    public init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        title: String,
        detail: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.title = title
        self.detail = detail
    }
}
