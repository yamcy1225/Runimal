import Testing
@testable import RunimalCore

struct MutationVisualEvolutionEngineTests {
    @Test
    func historyProgressMapsToDeterministicVisualStages() {
        let history = MutationHistorySnapshot(
            speciesID: "windrunner",
            runCount: 4,
            currentForm: MutationFormSnapshot(
                speciesID: "windrunner",
                formID: "windrunner.aero-swift.river-open.draft-route",
                shortLabel: "Aero Swift · River Open · Draft Route",
                bodyBranchID: "aero-swift",
                ecologyBranchID: "river-open",
                rhythmBranchID: "draft-route",
                confidence: 0.82
            ),
            unlockedForms: [],
            axes: [
                MutationAxisHistory(
                    axis: .body,
                    currentBranchID: "aero-swift",
                    currentTitle: "Aero Swift",
                    currentScore: 8,
                    currentProgress: 0.37,
                    unlockedBranchIDs: ["aero-swift"],
                    unlockedTitles: ["Aero Swift"],
                    branches: []
                ),
                MutationAxisHistory(
                    axis: .ecology,
                    currentBranchID: "river-open",
                    currentTitle: "River Open",
                    currentScore: 10,
                    currentProgress: 0.44,
                    unlockedBranchIDs: ["river-open"],
                    unlockedTitles: ["River Open"],
                    branches: []
                ),
                MutationAxisHistory(
                    axis: .rhythm,
                    currentBranchID: "draft-route",
                    currentTitle: "Draft Route",
                    currentScore: 12,
                    currentProgress: 0.58,
                    unlockedBranchIDs: ["draft-route"],
                    unlockedTitles: ["Draft Route"],
                    branches: []
                )
            ]
        )

        let state = MutationVisualEvolutionEngine.state(for: history, fallbackForm: history.currentForm)

        #expect(state.bodyStage == 1)
        #expect(state.ecologyStage == 2)
        #expect(state.rhythmStage == 3)
    }
}
