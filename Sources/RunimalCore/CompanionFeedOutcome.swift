import Foundation

public struct CompanionFeedOutcome: Equatable, Sendable {
    public let runID: String
    public let coreLabel: String
    public let gainedExperience: Int
    public let bonusLabels: [String]
    public let beforeProgress: EvolutionProgress
    public let afterProgress: EvolutionProgress
    public let stageAdvanced: Bool

    public init(
        runID: String,
        coreLabel: String,
        gainedExperience: Int,
        bonusLabels: [String] = [],
        beforeProgress: EvolutionProgress,
        afterProgress: EvolutionProgress,
        stageAdvanced: Bool
    ) {
        self.runID = runID
        self.coreLabel = coreLabel
        self.gainedExperience = gainedExperience
        self.bonusLabels = bonusLabels
        self.beforeProgress = beforeProgress
        self.afterProgress = afterProgress
        self.stageAdvanced = stageAdvanced
    }
}
