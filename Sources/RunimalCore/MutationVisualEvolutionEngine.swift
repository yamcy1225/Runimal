import Foundation

public struct MutationVisualState: Equatable, Sendable {
    public let bodyStage: Int
    public let ecologyStage: Int
    public let rhythmStage: Int

    public init(bodyStage: Int, ecologyStage: Int, rhythmStage: Int) {
        self.bodyStage = bodyStage
        self.ecologyStage = ecologyStage
        self.rhythmStage = rhythmStage
    }

    public static let none = MutationVisualState(bodyStage: 0, ecologyStage: 0, rhythmStage: 0)
}

public enum MutationVisualEvolutionEngine {
    public static func allowsMutationIdentity(growthStageIndex: Int) -> Bool {
        growthStageIndex >= 2
    }

    public static func state(
        for history: MutationHistorySnapshot?,
        fallbackForm: MutationFormSnapshot?
    ) -> MutationVisualState {
        guard let history else {
            guard fallbackForm != nil else { return .none }
            return MutationVisualState(bodyStage: 1, ecologyStage: 1, rhythmStage: 1)
        }

        let body = history.axes.first(where: { $0.axis == .body })?.currentProgress ?? 0
        let ecology = history.axes.first(where: { $0.axis == .ecology })?.currentProgress ?? 0
        let rhythm = history.axes.first(where: { $0.axis == .rhythm })?.currentProgress ?? 0

        return MutationVisualState(
            bodyStage: stage(for: body),
            ecologyStage: stage(for: ecology),
            rhythmStage: stage(for: rhythm)
        )
    }

    public static func visibleState(
        for state: MutationVisualState,
        growthStageIndex: Int
    ) -> MutationVisualState {
        let maxVisibleStage: Int
        switch growthStageIndex {
        case ...1:
            maxVisibleStage = 0
        case 2:
            maxVisibleStage = 1
        case 3:
            maxVisibleStage = 2
        default:
            maxVisibleStage = 3
        }

        return MutationVisualState(
            bodyStage: min(state.bodyStage, maxVisibleStage),
            ecologyStage: min(state.ecologyStage, maxVisibleStage),
            rhythmStage: min(state.rhythmStage, maxVisibleStage)
        )
    }

    private static func stage(for progress: Double) -> Int {
        switch progress {
        case ...0:
            return 0
        case ..<0.38:
            return 1
        case ..<0.5:
            return 2
        default:
            return 3
        }
    }
}
