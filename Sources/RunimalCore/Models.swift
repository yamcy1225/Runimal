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

public enum RunTimeAura: String, Codable, Sendable {
    case dawn
    case day
    case dusk
    case night
}

public enum RouteShape: String, Codable, Sendable {
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
