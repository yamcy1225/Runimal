import XCTest
@testable import RunimalCore

final class CompanionLoopModelsTests: XCTestCase {
    func testWatchSelectionTransportPayloadRoundTripsEggContext() {
        let updatedAt = Date(timeIntervalSince1970: 1_234_567)
        let context = WatchMainCompanionContext(
            selection: MainCompanionSelection(kind: .egg, targetID: "egg-1"),
            eggShell: .ember,
            eggTitle: "Blaze Egg",
            eggProgressRatio: 0.75,
            eggReadyToHatch: true,
            updatedAt: updatedAt
        )

        let restored = WatchMainCompanionContext(
            watchSelectionTransportPayload: context.watchSelectionTransportPayload
        )

        XCTAssertNotNil(restored)
        XCTAssertEqual(restored?.selection, context.selection)
        XCTAssertEqual(restored?.eggShell, context.eggShell)
        XCTAssertEqual(restored?.eggTitle, context.eggTitle)
        XCTAssertEqual(restored?.eggProgressRatio, context.eggProgressRatio)
        XCTAssertEqual(restored?.eggReadyToHatch, context.eggReadyToHatch)
        XCTAssertEqual(restored?.updatedAt, updatedAt)
    }

    func testFlattenedPayloadRoundTripsPetContext() {
        let updatedAt = Date(timeIntervalSince1970: 9_876_543)
        let pet = GeneratedPet(
            species: .windrunner,
            element: .light,
            palette: "mist",
            rareVariant: .tempoSurge,
            explanation: [],
            stats: PetStats(vitality: 1, agility: 2, dexterity: 3, focus: 4, defense: 5)
        )
        let context = WatchMainCompanionContext(
            selection: MainCompanionSelection(kind: .pet, targetID: "pet-1"),
            pet: pet,
            petName: "Misty",
            petHeadline: "steady runner",
            mutationBodyStage: 3,
            mutationEcologyStage: 2,
            mutationRhythmStage: 1,
            updatedAt: updatedAt
        )

        let restored = WatchMainCompanionContext(flattenedWCPayload: context.flattenedWCPayload)

        XCTAssertNotNil(restored)
        XCTAssertEqual(restored?.selection, context.selection)
        XCTAssertEqual(restored?.petName, context.petName)
        XCTAssertEqual(restored?.petHeadline, context.petHeadline)
        XCTAssertEqual(restored?.pet?.species, context.pet?.species)
        XCTAssertEqual(restored?.pet?.element, context.pet?.element)
        XCTAssertEqual(restored?.pet?.palette, context.pet?.palette)
        XCTAssertEqual(restored?.pet?.rareVariant, context.pet?.rareVariant)
        XCTAssertEqual(restored?.mutationBodyStage, context.mutationBodyStage)
        XCTAssertEqual(restored?.mutationEcologyStage, context.mutationEcologyStage)
        XCTAssertEqual(restored?.mutationRhythmStage, context.mutationRhythmStage)
        XCTAssertEqual(restored?.updatedAt, updatedAt)
    }
}
