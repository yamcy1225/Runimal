import Foundation

public struct CompanionFeedOutcome: Equatable, Sendable {
    public let runID: String
    public let coreLabel: String
    public let gainedExperience: Int
    public let baseExperience: Int
    public let supportBonusExperience: Int
    public let dataBonusExperience: Int
    public let storedPotentialExperienceBefore: Int
    public let potentialExperienceSpent: Int
    public let remainingStoredPotentialExperience: Int
    public let bonusLabels: [String]
    public let beforeSnapshot: CompanionProgressionSnapshot
    public let afterSnapshot: CompanionProgressionSnapshot
    public let beforeProgress: EvolutionProgress
    public let afterProgress: EvolutionProgress
    public let stageAdvanced: Bool

    public init(
        runID: String,
        coreLabel: String,
        gainedExperience: Int,
        baseExperience: Int = 0,
        supportBonusExperience: Int = 0,
        dataBonusExperience: Int = 0,
        storedPotentialExperienceBefore: Int = 0,
        potentialExperienceSpent: Int = 0,
        remainingStoredPotentialExperience: Int = 0,
        bonusLabels: [String] = [],
        beforeSnapshot: CompanionProgressionSnapshot,
        afterSnapshot: CompanionProgressionSnapshot,
        beforeProgress: EvolutionProgress,
        afterProgress: EvolutionProgress,
        stageAdvanced: Bool
    ) {
        self.runID = runID
        self.coreLabel = coreLabel
        self.gainedExperience = gainedExperience
        self.baseExperience = baseExperience
        self.supportBonusExperience = supportBonusExperience
        self.dataBonusExperience = dataBonusExperience
        self.storedPotentialExperienceBefore = storedPotentialExperienceBefore
        self.potentialExperienceSpent = potentialExperienceSpent
        self.remainingStoredPotentialExperience = remainingStoredPotentialExperience
        self.bonusLabels = bonusLabels
        self.beforeSnapshot = beforeSnapshot
        self.afterSnapshot = afterSnapshot
        self.beforeProgress = beforeProgress
        self.afterProgress = afterProgress
        self.stageAdvanced = stageAdvanced
    }
}
