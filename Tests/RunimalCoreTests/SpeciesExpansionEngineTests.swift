import XCTest
@testable import RunimalCore

final class SpeciesExpansionEngineTests: XCTestCase {
    func testBaseSpeciesBlueprintCountIsFive() {
        XCTAssertEqual(DefaultSpeciesExpansionBlueprints.baseSpeciesBlueprints.count, 5)
    }

    func testFiveSpeciesWithThreeAxesProduceOneHundredThirtyFiveForms() {
        XCTAssertEqual(DefaultSpeciesExpansionBlueprints.maxExpandableForms, 135)
    }

    func testStarterShowcaseRosterContainsTwentyUniqueExamples() {
        XCTAssertEqual(DefaultSpeciesExpansionBlueprints.starterShowcaseRoster.count, 20)
        XCTAssertEqual(Set(DefaultSpeciesExpansionBlueprints.starterShowcaseRoster.map(\.formID)).count, 20)
    }

    func testEachBlueprintExpandsToTwentySevenForms() {
        for blueprint in DefaultSpeciesExpansionBlueprints.baseSpeciesBlueprints {
            XCTAssertEqual(SpeciesExpansionEngine.expandedForms(for: blueprint).count, 27)
        }
    }
}
