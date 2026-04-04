import XCTest
@testable import RunimalCore

final class SpeciesGrowthMutationBridgeEngineTests: XCTestCase {
    func testWindrunnerRiverBranchStartsFromSharedWingStage() {
        let bridge = SpeciesGrowthMutationBridgeEngine.bridge(
            for: .windrunner,
            axis: .ecology,
            branchID: "river-open"
        )

        XCTAssertEqual(bridge?.startStageIndex, 2)
        XCTAssertEqual(bridge?.startStageTitle, "유년기")
        XCTAssertTrue(bridge?.inheritedParts.contains(where: { $0.id == "wing-line" }) ?? false)
        XCTAssertFalse(bridge?.redirectedParts.isEmpty ?? true)
    }

    func testStonebackBodyBranchStartsFromShoulderGrowthStage() {
        let bridge = SpeciesGrowthMutationBridgeEngine.bridge(
            for: .stoneback,
            axis: .body,
            branchID: "ridge-guard"
        )

        XCTAssertEqual(bridge?.startStageIndex, 1)
        XCTAssertEqual(bridge?.startStageTitle, "유아기")
        XCTAssertTrue(bridge?.inheritedParts.contains(where: { $0.id == "shoulder-line" }) ?? false)
    }

    func testBridgeFromFormReturnsThreeAxes() {
        let form = MutationFormSnapshot(
            speciesID: "seedle",
            formID: "seedle.bud-runner.twilight-bud.grow-loop",
            shortLabel: "Twilight Bloom",
            bodyBranchID: "bud-runner",
            ecologyBranchID: "twilight-bud",
            rhythmBranchID: "grow-loop",
            confidence: 0.88
        )

        let bridges = SpeciesGrowthMutationBridgeEngine.bridge(for: .seedle, form: form)
        XCTAssertEqual(bridges.count, 3)
        XCTAssertEqual(Set(bridges.map(\.axis)), Set<SpeciesLineageAxis>([.body, .ecology, .rhythm]))
    }
}
