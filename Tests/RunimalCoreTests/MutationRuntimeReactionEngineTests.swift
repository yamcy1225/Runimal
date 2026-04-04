import Testing
@testable import RunimalCore

struct MutationRuntimeReactionEngineTests {
    @Test
    func rhythmStageUsesCadenceAndPaceSignals() {
        let reaction = MutationRuntimeReactionEngine.reaction(
            for: MutationVisualState(bodyStage: 1, ecologyStage: 0, rhythmStage: 3),
            snapshot: LiveRunSnapshot(
                elapsedSeconds: 420,
                distanceMeters: 1600,
                currentHeartRate: 154,
                cadence: 172,
                elevationGainM: 12,
                averagePaceSeconds: 320
            ),
            gpsAccuracyMeters: 10,
            isGPSFresh: true
        )

        #expect(reaction?.axis == .rhythm)
        #expect(reaction?.title == "박동 각성")
    }

    @Test
    func ecologyStageRequiresStableGpsAndRouteDistance() {
        let reaction = MutationRuntimeReactionEngine.reaction(
            for: MutationVisualState(bodyStage: 0, ecologyStage: 2, rhythmStage: 0),
            snapshot: LiveRunSnapshot(
                elapsedSeconds: 600,
                distanceMeters: 900,
                currentHeartRate: 132,
                cadence: 160,
                elevationGainM: 9,
                averagePaceSeconds: 355
            ),
            gpsAccuracyMeters: 11,
            isGPSFresh: true
        )

        #expect(reaction?.axis == .ecology)
    }

    @Test
    func bodyStageRespondsToClimbAndHeartRate() {
        let reaction = MutationRuntimeReactionEngine.reaction(
            for: MutationVisualState(bodyStage: 3, ecologyStage: 1, rhythmStage: 0),
            snapshot: LiveRunSnapshot(
                elapsedSeconds: 540,
                distanceMeters: 1800,
                currentHeartRate: 158,
                cadence: 162,
                elevationGainM: 26,
                averagePaceSeconds: 348
            ),
            gpsAccuracyMeters: 22,
            isGPSFresh: true
        )

        #expect(reaction?.axis == .body)
        #expect(reaction?.title == "실루엣 각성")
    }

    @Test
    func bridgeSnapshotProducesTransitionAwareDetail() {
        let bridge = SpeciesGrowthMutationBridgeEngine.bridge(
            for: .windrunner,
            axis: .ecology,
            branchID: "river-open"
        )

        let reaction = MutationRuntimeReactionEngine.reaction(
            for: MutationVisualState(bodyStage: 0, ecologyStage: 3, rhythmStage: 0),
            snapshot: LiveRunSnapshot(
                elapsedSeconds: 620,
                distanceMeters: 1400,
                currentHeartRate: 138,
                cadence: 164,
                elevationGainM: 12,
                averagePaceSeconds: 350
            ),
            gpsAccuracyMeters: 9,
            isGPSFresh: true,
            bridgeSnapshots: bridge.map { [.ecology: $0] } ?? [:]
        )

        #expect(reaction?.axis == .ecology)
        #expect(reaction?.transitionStageTitle == bridge?.startStageTitle)
        #expect(reaction?.detail.contains("갈래") == true)
    }

    @Test
    func bridgeSnapshotUsesHumanBranchTitleInsteadOfRawBranchID() {
        let bridge = SpeciesGrowthMutationBridgeEngine.bridge(
            for: .windrunner,
            axis: .ecology,
            branchID: "river-open"
        )

        #expect(bridge?.branchTitle == "River Open")
    }
}
