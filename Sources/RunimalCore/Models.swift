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

public enum EnvironmentCondition: String, Codable, CaseIterable, Sendable {
    case clear
    case rain
    case snow
    case wind
    case heat
    case cold
    case overcast
    case unknown
}

public struct RunSummary: Codable, Equatable, Sendable {
    public let distanceKm: Double
    public let averagePaceSeconds: Int
    public let cadence: Int
    public let elevationGainM: Int
    public let variability: Double
    public let aura: RunTimeAura
    public let shape: RouteShape
    public let environmentCondition: EnvironmentCondition
    public let rareEventCompleted: Bool

    public init(
        distanceKm: Double,
        averagePaceSeconds: Int,
        cadence: Int,
        elevationGainM: Int,
        variability: Double,
        aura: RunTimeAura,
        shape: RouteShape,
        environmentCondition: EnvironmentCondition = .unknown,
        rareEventCompleted: Bool = false
    ) {
        self.distanceKm = distanceKm
        self.averagePaceSeconds = averagePaceSeconds
        self.cadence = cadence
        self.elevationGainM = elevationGainM
        self.variability = variability
        self.aura = aura
        self.shape = shape
        self.environmentCondition = environmentCondition
        self.rareEventCompleted = rareEventCompleted
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

public struct MutationFormSnapshot: Codable, Equatable, Sendable {
    public let speciesID: String
    public let formID: String
    public let shortLabel: String
    public let bodyBranchID: String
    public let ecologyBranchID: String
    public let rhythmBranchID: String
    public let confidence: Double

    public init(
        speciesID: String,
        formID: String,
        shortLabel: String,
        bodyBranchID: String,
        ecologyBranchID: String,
        rhythmBranchID: String,
        confidence: Double
    ) {
        self.speciesID = speciesID
        self.formID = formID
        self.shortLabel = shortLabel
        self.bodyBranchID = bodyBranchID
        self.ecologyBranchID = ecologyBranchID
        self.rhythmBranchID = rhythmBranchID
        self.confidence = confidence
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
    public let bonusLabels: [String]

    public init(
        pet: GeneratedPet,
        coreLabel: String,
        experience: Int,
        completedQuestCount: Int,
        flavorText: String,
        bonusLabels: [String] = []
    ) {
        self.pet = pet
        self.coreLabel = coreLabel
        self.experience = experience
        self.completedQuestCount = completedQuestCount
        self.flavorText = flavorText
        self.bonusLabels = bonusLabels
    }

    enum CodingKeys: String, CodingKey {
        case pet
        case coreLabel
        case experience
        case completedQuestCount
        case flavorText
        case bonusLabels
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pet = try container.decode(GeneratedPet.self, forKey: .pet)
        coreLabel = try container.decode(String.self, forKey: .coreLabel)
        experience = try container.decode(Int.self, forKey: .experience)
        completedQuestCount = try container.decode(Int.self, forKey: .completedQuestCount)
        flavorText = try container.decode(String.self, forKey: .flavorText)
        bonusLabels = try container.decodeIfPresent([String].self, forKey: .bonusLabels) ?? []
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

public struct RunimalProgressSnapshot: Codable, Equatable, Sendable {
    public let savedAt: Date
    public let originDeviceID: String
    public let journal: [RunJournalEntry]
    public let completedRuns: [CompletedRunRecord]
    public let ownedCompanions: [PetCollectionEntry]
    public let eggInventory: [EggInventoryEntry]
    public let unlockedEggAchievementIDs: [String]
    public let claimedWeeklyRewards: [String]
    public let activeCompanionID: String?
    public let mainCompanionSelection: MainCompanionSelection?
    public let growthRecords: [CompanionGrowthRecord]
    public let retiredCompanionIDs: [String]
    public let essenceBalance: Int
    public let overdriveCharges: Int
    public let seasonSigils: Int
    public let buildStates: [CompanionBuildState]
    public let claimedSeasonRewardIDs: [String]
    public let claimedRaidRewardIDs: [String]
    public let raidShardBalance: Int
    public let raidContributionTotal: Int

    public init(
        savedAt: Date,
        originDeviceID: String,
        journal: [RunJournalEntry],
        completedRuns: [CompletedRunRecord],
        ownedCompanions: [PetCollectionEntry] = [],
        eggInventory: [EggInventoryEntry] = [],
        unlockedEggAchievementIDs: [String] = [],
        claimedWeeklyRewards: [String],
        activeCompanionID: String?,
        mainCompanionSelection: MainCompanionSelection? = nil,
        growthRecords: [CompanionGrowthRecord],
        retiredCompanionIDs: [String],
        essenceBalance: Int,
        overdriveCharges: Int,
        seasonSigils: Int,
        buildStates: [CompanionBuildState],
        claimedSeasonRewardIDs: [String],
        claimedRaidRewardIDs: [String],
        raidShardBalance: Int,
        raidContributionTotal: Int = 0
    ) {
        self.savedAt = savedAt
        self.originDeviceID = originDeviceID
        self.journal = journal
        self.completedRuns = completedRuns
        self.ownedCompanions = ownedCompanions
        self.eggInventory = eggInventory
        self.unlockedEggAchievementIDs = unlockedEggAchievementIDs
        self.claimedWeeklyRewards = claimedWeeklyRewards
        self.activeCompanionID = activeCompanionID
        self.mainCompanionSelection = mainCompanionSelection
        self.growthRecords = growthRecords
        self.retiredCompanionIDs = retiredCompanionIDs
        self.essenceBalance = essenceBalance
        self.overdriveCharges = overdriveCharges
        self.seasonSigils = seasonSigils
        self.buildStates = buildStates
        self.claimedSeasonRewardIDs = claimedSeasonRewardIDs
        self.claimedRaidRewardIDs = claimedRaidRewardIDs
        self.raidShardBalance = raidShardBalance
        self.raidContributionTotal = raidContributionTotal
    }

    private enum CodingKeys: String, CodingKey {
        case savedAt
        case originDeviceID
        case journal
        case completedRuns
        case ownedCompanions
        case eggInventory
        case unlockedEggAchievementIDs
        case claimedWeeklyRewards
        case activeCompanionID
        case mainCompanionSelection
        case growthRecords
        case retiredCompanionIDs
        case essenceBalance
        case overdriveCharges
        case seasonSigils
        case buildStates
        case claimedSeasonRewardIDs
        case claimedRaidRewardIDs
        case raidShardBalance
        case raidContributionTotal
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        savedAt = try container.decode(Date.self, forKey: .savedAt)
        originDeviceID = try container.decode(String.self, forKey: .originDeviceID)
        journal = try container.decode([RunJournalEntry].self, forKey: .journal)
        completedRuns = try container.decode([CompletedRunRecord].self, forKey: .completedRuns)
        ownedCompanions = try container.decodeIfPresent([PetCollectionEntry].self, forKey: .ownedCompanions) ?? []
        eggInventory = try container.decodeIfPresent([EggInventoryEntry].self, forKey: .eggInventory) ?? []
        unlockedEggAchievementIDs = try container.decodeIfPresent([String].self, forKey: .unlockedEggAchievementIDs) ?? []
        claimedWeeklyRewards = try container.decode([String].self, forKey: .claimedWeeklyRewards)
        activeCompanionID = try container.decodeIfPresent(String.self, forKey: .activeCompanionID)
        mainCompanionSelection = try container.decodeIfPresent(MainCompanionSelection.self, forKey: .mainCompanionSelection)
        growthRecords = try container.decode([CompanionGrowthRecord].self, forKey: .growthRecords)
        retiredCompanionIDs = try container.decode([String].self, forKey: .retiredCompanionIDs)
        essenceBalance = try container.decode(Int.self, forKey: .essenceBalance)
        overdriveCharges = try container.decode(Int.self, forKey: .overdriveCharges)
        seasonSigils = try container.decode(Int.self, forKey: .seasonSigils)
        buildStates = try container.decode([CompanionBuildState].self, forKey: .buildStates)
        claimedSeasonRewardIDs = try container.decode([String].self, forKey: .claimedSeasonRewardIDs)
        claimedRaidRewardIDs = try container.decode([String].self, forKey: .claimedRaidRewardIDs)
        raidShardBalance = try container.decode(Int.self, forKey: .raidShardBalance)
        raidContributionTotal = try container.decodeIfPresent(Int.self, forKey: .raidContributionTotal) ?? completedRuns.reduce(0) { $0 + $1.raidContribution }
    }
}

public struct QAReplayScenario: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let trigger: String
    public let recoveryExpectation: String

    public init(id: String, title: String, trigger: String, recoveryExpectation: String) {
        self.id = id
        self.title = title
        self.trigger = trigger
        self.recoveryExpectation = recoveryExpectation
    }
}

public struct QAReplayReport: Codable, Equatable, Sendable {
    public let title: String
    public let severity: String
    public let checkpoints: [String]

    public init(title: String, severity: String, checkpoints: [String]) {
        self.title = title
        self.severity = severity
        self.checkpoints = checkpoints
    }
}

public struct SeasonEconomyBoard: Codable, Equatable, Sendable {
    public let seasonID: String
    public let title: String
    public let headline: String
    public let affinityCount: Int
    public let requiredCount: Int
    public let rewardLabel: String
    public let claimable: Bool

    public init(
        seasonID: String,
        title: String,
        headline: String,
        affinityCount: Int,
        requiredCount: Int,
        rewardLabel: String,
        claimable: Bool
    ) {
        self.seasonID = seasonID
        self.title = title
        self.headline = headline
        self.affinityCount = affinityCount
        self.requiredCount = requiredCount
        self.rewardLabel = rewardLabel
        self.claimable = claimable
    }
}

public struct ChallengeTrial: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let score: Int
    public let verdict: String

    public init(id: String, title: String, detail: String, score: Int, verdict: String) {
        self.id = id
        self.title = title
        self.detail = detail
        self.score = score
        self.verdict = verdict
    }
}

public struct StarterLoopStep: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let completed: Bool

    public init(id: String, title: String, detail: String, completed: Bool) {
        self.id = id
        self.title = title
        self.detail = detail
        self.completed = completed
    }
}

public struct ContentRotationEntry: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let reward: String

    public init(id: String, title: String, detail: String, reward: String) {
        self.id = id
        self.title = title
        self.detail = detail
        self.reward = reward
    }
}

public struct RaidEncounter: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let readinessScore: Int
    public let recommendedReward: String
    public let claimThreshold: Int

    public init(id: String, title: String, detail: String, readinessScore: Int, recommendedReward: String, claimThreshold: Int) {
        self.id = id
        self.title = title
        self.detail = detail
        self.readinessScore = readinessScore
        self.recommendedReward = recommendedReward
        self.claimThreshold = claimThreshold
    }
}

public struct RaidResolution: Codable, Equatable, Sendable {
    public let encounterID: String
    public let title: String
    public let tier: String
    public let shardReward: Int
    public let essenceReward: Int

    public init(encounterID: String, title: String, tier: String, shardReward: Int, essenceReward: Int) {
        self.encounterID = encounterID
        self.title = title
        self.tier = tier
        self.shardReward = shardReward
        self.essenceReward = essenceReward
    }
}

public struct CloudValidationState: Codable, Equatable, Sendable {
    public let title: String
    public let detail: String
    public let success: Bool

    public init(title: String, detail: String, success: Bool) {
        self.title = title
        self.detail = detail
        self.success = success
    }
}

public enum SnapshotConflictPolicy: String, Codable, CaseIterable, Sendable {
    case merged
    case localPreferred = "local-preferred"
    case cloudPreferred = "cloud-preferred"
}

public struct SnapshotConflictReport: Codable, Equatable, Sendable {
    public let title: String
    public let detail: String
    public let localRunCount: Int
    public let cloudRunCount: Int
    public let localJournalCount: Int
    public let cloudJournalCount: Int
    public let recommendedPolicy: SnapshotConflictPolicy
    public let hasConflict: Bool

    public init(
        title: String,
        detail: String,
        localRunCount: Int,
        cloudRunCount: Int,
        localJournalCount: Int,
        cloudJournalCount: Int,
        recommendedPolicy: SnapshotConflictPolicy,
        hasConflict: Bool
    ) {
        self.title = title
        self.detail = detail
        self.localRunCount = localRunCount
        self.cloudRunCount = cloudRunCount
        self.localJournalCount = localJournalCount
        self.cloudJournalCount = cloudJournalCount
        self.recommendedPolicy = recommendedPolicy
        self.hasConflict = hasConflict
    }
}

public struct RaidCombatStep: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let label: String
    public let detail: String
    public let intensity: Double

    public init(id: String, label: String, detail: String, intensity: Double) {
        self.id = id
        self.label = label
        self.detail = detail
        self.intensity = intensity
    }
}

public struct RaidCombatReport: Codable, Equatable, Sendable {
    public let title: String
    public let verdict: String
    public let headline: String
    public let steps: [RaidCombatStep]

    public init(title: String, verdict: String, headline: String, steps: [RaidCombatStep]) {
        self.title = title
        self.verdict = verdict
        self.headline = headline
        self.steps = steps
    }
}

public struct DeviceQACheckItem: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let detail: String

    public init(id: String, title: String, detail: String) {
        self.id = id
        self.title = title
        self.detail = detail
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
    public let sourceLabel: String?
    public let raidContribution: Int
    public let environmentCondition: EnvironmentCondition
    public let rareEventCompleted: Bool
    public let mutationForm: MutationFormSnapshot?
    public let mutationContribution: MutationRunContributionSnapshot?

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
        source: String,
        sourceLabel: String? = nil,
        raidContribution: Int = 0,
        environmentCondition: EnvironmentCondition = .unknown,
        rareEventCompleted: Bool = false,
        mutationForm: MutationFormSnapshot? = nil,
        mutationContribution: MutationRunContributionSnapshot? = nil
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
        self.sourceLabel = sourceLabel
        self.raidContribution = raidContribution
        self.environmentCondition = environmentCondition
        self.rareEventCompleted = rareEventCompleted
        self.mutationForm = mutationForm
        self.mutationContribution = mutationContribution
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case startedAt
        case endedAt
        case distanceMeters
        case durationSeconds
        case averageHeartRate
        case averagePaceSeconds
        case cadence
        case elevationGainM
        case reward
        case route
        case source
        case sourceLabel
        case raidContribution
        case environmentCondition
        case rareEventCompleted
        case mutationForm
        case mutationContribution
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        endedAt = try container.decode(Date.self, forKey: .endedAt)
        distanceMeters = try container.decode(Double.self, forKey: .distanceMeters)
        durationSeconds = try container.decode(Int.self, forKey: .durationSeconds)
        averageHeartRate = try container.decodeIfPresent(Double.self, forKey: .averageHeartRate)
        averagePaceSeconds = try container.decodeIfPresent(Int.self, forKey: .averagePaceSeconds)
        cadence = try container.decodeIfPresent(Int.self, forKey: .cadence)
        elevationGainM = try container.decode(Int.self, forKey: .elevationGainM)
        reward = try container.decode(RunRewardSummary.self, forKey: .reward)
        route = try container.decodeIfPresent([RoutePoint].self, forKey: .route) ?? []
        source = try container.decode(String.self, forKey: .source)
        sourceLabel = try container.decodeIfPresent(String.self, forKey: .sourceLabel)
        raidContribution = try container.decodeIfPresent(Int.self, forKey: .raidContribution) ?? 0
        environmentCondition = try container.decodeIfPresent(EnvironmentCondition.self, forKey: .environmentCondition) ?? .unknown
        rareEventCompleted = try container.decodeIfPresent(Bool.self, forKey: .rareEventCompleted) ?? false
        mutationForm = try container.decodeIfPresent(MutationFormSnapshot.self, forKey: .mutationForm)
        mutationContribution = try container.decodeIfPresent(MutationRunContributionSnapshot.self, forKey: .mutationContribution)
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
