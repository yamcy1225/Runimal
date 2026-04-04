import XCTest
@testable import RunimalCore

final class SpeciesVisualBlueprintsTests: XCTestCase {
    func testEveryBaseSpeciesHasBaseAnatomyBlueprint() {
        let species: [PetSpecies] = [.windrunner, .stoneback, .sparkfang, .mosshop, .seedle]

        XCTAssertEqual(DefaultSpeciesVisualBlueprints.baseSpeciesBlueprints.count, 5)

        for item in species {
            let blueprint = DefaultSpeciesVisualBlueprints.baseAnatomy(for: item)
            XCTAssertNotNil(blueprint, "Missing base anatomy blueprint for \(item.rawValue)")
            XCTAssertFalse(blueprint?.signatureParts.isEmpty ?? true)
            XCTAssertFalse(blueprint?.pixelShiftTags.isEmpty ?? true)
        }
    }

    func testShadebitFallsBackToSparkfangBaseAnatomy() {
        let shadebit = DefaultSpeciesVisualBlueprints.baseAnatomy(for: .shadebit)
        let sparkfang = DefaultSpeciesVisualBlueprints.baseAnatomy(for: .sparkfang)

        XCTAssertEqual(shadebit?.speciesID, PetSpecies.sparkfang.rawValue)
        XCTAssertEqual(shadebit, sparkfang)
    }

    func testEveryBaseSpeciesHasFiveGrowthStageBlueprints() {
        let species: [PetSpecies] = [.windrunner, .stoneback, .sparkfang, .mosshop, .seedle]

        for item in species {
            let stages = (0...4).compactMap { DefaultSpeciesVisualBlueprints.growthStage(for: item, stageIndex: $0) }
            XCTAssertEqual(stages.count, 5, "Missing growth stage blueprint for \(item.rawValue)")
            XCTAssertEqual(stages.map(\.stageIndex), [0, 1, 2, 3, 4])
            XCTAssertTrue(stages.allSatisfy { !$0.developedParts.isEmpty })
            XCTAssertTrue(stages.allSatisfy { !$0.pixelShiftTags.isEmpty })
        }
    }

    func testEveryExpansionBranchHasVisualBlueprint() {
        let branchIDs = DefaultSpeciesExpansionBlueprints.baseSpeciesBlueprints.flatMap {
            $0.bodyBranches.map(\.id) + $0.ecologyBranches.map(\.id) + $0.rhythmBranches.map(\.id)
        }

        for branchID in branchIDs {
            let blueprint = DefaultSpeciesVisualBlueprints.anatomy(for: branchID)
            XCTAssertNotNil(blueprint, "Missing anatomy blueprint for \(branchID)")
            XCTAssertEqual(blueprint?.id, branchID)
            XCTAssertFalse(blueprint?.affectedParts.isEmpty ?? true)
            XCTAssertFalse(blueprint?.pixelShiftTags.isEmpty ?? true)
        }
    }

    func testFormLookupReturnsThreeAxisBlueprints() {
        let form = MutationFormSnapshot(
            speciesID: "windrunner",
            formID: "windrunner.aero-swift.river-open.draft-route",
            shortLabel: "Aero",
            bodyBranchID: "aero-swift",
            ecologyBranchID: "river-open",
            rhythmBranchID: "draft-route",
            confidence: 0.91
        )

        let blueprints = DefaultSpeciesVisualBlueprints.anatomy(for: form)
        let axes = Set(blueprints.map { $0.axis })

        XCTAssertEqual(blueprints.count, 3)
        XCTAssertEqual(axes, Set<SpeciesLineageAxis>([.body, .ecology, .rhythm]))
    }

    func testRenderProfileUsesBaseBlueprintTags() {
        let pixels = SpeciesVisualRenderProfile.baseIdentityPixels(for: .stoneback)

        XCTAssertEqual(pixels, [
            PixelCoordinate(2, 2),
            PixelCoordinate(7, 2),
            PixelCoordinate(2, 5),
            PixelCoordinate(7, 5),
            PixelCoordinate(4, 6),
            PixelCoordinate(5, 6),
        ])
    }

    func testRenderProfileUsesGrowthBlueprintTags() {
        let pixels = SpeciesVisualRenderProfile.growthAccentPixels(for: .windrunner, stageIndex: 3)

        XCTAssertEqual(pixels, [])
    }

    func testInfantSpritesUseDedicatedBabySilhouettes() {
        let windrunner = SpeciesVisualRenderProfile.bodySpritePixels(for: .windrunner, stageIndex: 1)
        let stoneback = SpeciesVisualRenderProfile.bodySpritePixels(for: .stoneback, stageIndex: 1)
        let sparkfang = SpeciesVisualRenderProfile.bodySpritePixels(for: .sparkfang, stageIndex: 1)
        let mosshop = SpeciesVisualRenderProfile.bodySpritePixels(for: .mosshop, stageIndex: 1)
        let seedle = SpeciesVisualRenderProfile.bodySpritePixels(for: .seedle, stageIndex: 1)

        XCTAssertTrue(windrunner.contains(PixelCoordinate(4, 0)))
        XCTAssertTrue(windrunner.contains(PixelCoordinate(5, 0)))
        XCTAssertTrue(stoneback.contains(PixelCoordinate(2, 4)))
        XCTAssertTrue(stoneback.contains(PixelCoordinate(6, 6)))
        XCTAssertTrue(sparkfang.contains(PixelCoordinate(3, 0)))
        XCTAssertTrue(sparkfang.contains(PixelCoordinate(6, 0)))
        XCTAssertFalse(sparkfang.contains(PixelCoordinate(4, 0)))
        XCTAssertTrue(mosshop.contains(PixelCoordinate(2, 3)))
        XCTAssertTrue(mosshop.contains(PixelCoordinate(7, 4)))
        XCTAssertTrue(seedle.contains(PixelCoordinate(4, 0)))
        XCTAssertTrue(seedle.contains(PixelCoordinate(5, 0)))
        XCTAssertTrue(seedle.contains(PixelCoordinate(7, 4)))
        XCTAssertFalse(windrunner.contains(PixelCoordinate(2, 3)))
        XCTAssertNotEqual(windrunner, stoneback)
        XCTAssertNotEqual(windrunner, sparkfang)
        XCTAssertNotEqual(windrunner, mosshop)
        XCTAssertNotEqual(windrunner, seedle)
    }

    func testInfantFaceAccentsFavorRoundedCheeks() {
        let windrunner = SpeciesVisualRenderProfile.faceAccentPixels(for: .windrunner, stageIndex: 1)
        let stoneback = SpeciesVisualRenderProfile.faceAccentPixels(for: .stoneback, stageIndex: 1)
        let sparkfang = SpeciesVisualRenderProfile.faceAccentPixels(for: .sparkfang, stageIndex: 1)
        let mosshop = SpeciesVisualRenderProfile.faceAccentPixels(for: .mosshop, stageIndex: 1)
        let seedle = SpeciesVisualRenderProfile.faceAccentPixels(for: .seedle, stageIndex: 1)

        XCTAssertEqual(windrunner, [
            PixelCoordinate(2, 3),
            PixelCoordinate(3, 3),
            PixelCoordinate(6, 3),
            PixelCoordinate(7, 3),
            PixelCoordinate(2, 4),
            PixelCoordinate(3, 4),
            PixelCoordinate(4, 4),
            PixelCoordinate(5, 4),
            PixelCoordinate(6, 4),
            PixelCoordinate(7, 4),
            PixelCoordinate(3, 5),
            PixelCoordinate(4, 5),
            PixelCoordinate(5, 5),
            PixelCoordinate(6, 5),
        ])
        XCTAssertEqual(sparkfang, [
            PixelCoordinate(2, 3),
            PixelCoordinate(7, 3),
            PixelCoordinate(2, 4),
            PixelCoordinate(3, 4),
            PixelCoordinate(4, 4),
            PixelCoordinate(5, 4),
            PixelCoordinate(6, 4),
            PixelCoordinate(7, 4),
            PixelCoordinate(3, 5),
            PixelCoordinate(6, 5),
        ])
        XCTAssertTrue(stoneback.contains(PixelCoordinate(2, 5)))
        XCTAssertTrue(stoneback.contains(PixelCoordinate(7, 5)))
        XCTAssertTrue(mosshop.contains(PixelCoordinate(1, 3)))
        XCTAssertTrue(mosshop.contains(PixelCoordinate(8, 4)))
        XCTAssertTrue(seedle.contains(PixelCoordinate(4, 5)))
        XCTAssertTrue(seedle.contains(PixelCoordinate(7, 4)))
        XCTAssertFalse(seedle.contains(PixelCoordinate(2, 3)))
    }

    func testFourthStageSpritesUseDedicatedSpeciesSilhouettes() {
        let windrunner = SpeciesVisualRenderProfile.bodySpritePixels(for: .windrunner, stageIndex: 3)
        let stoneback = SpeciesVisualRenderProfile.bodySpritePixels(for: .stoneback, stageIndex: 3)
        let sparkfang = SpeciesVisualRenderProfile.bodySpritePixels(for: .sparkfang, stageIndex: 3)
        let mosshop = SpeciesVisualRenderProfile.bodySpritePixels(for: .mosshop, stageIndex: 3)
        let seedle = SpeciesVisualRenderProfile.bodySpritePixels(for: .seedle, stageIndex: 3)

        XCTAssertTrue(windrunner.contains(PixelCoordinate(1, 4)))
        XCTAssertTrue(stoneback.contains(PixelCoordinate(1, 3)))
        XCTAssertTrue(sparkfang.contains(PixelCoordinate(3, 0)))
        XCTAssertTrue(mosshop.contains(PixelCoordinate(1, 5)))
        XCTAssertTrue(seedle.contains(PixelCoordinate(4, 0)))
        XCTAssertFalse(seedle.contains(PixelCoordinate(1, 4)))
        XCTAssertNotEqual(windrunner, stoneback)
        XCTAssertNotEqual(windrunner, sparkfang)
        XCTAssertNotEqual(mosshop, seedle)
    }

    func testFourthStageAccentsAddHandsFeetAndCheekReadability() {
        let mosshopFace = SpeciesVisualRenderProfile.faceAccentPixels(for: .mosshop, stageIndex: 3)
        let mosshopLimb = SpeciesVisualRenderProfile.baseAccentPixels(for: .mosshop, stageIndex: 3)
        let sparkfangLimb = SpeciesVisualRenderProfile.baseAccentPixels(for: .sparkfang, stageIndex: 3)

        XCTAssertTrue(mosshopFace.contains(PixelCoordinate(2, 4)))
        XCTAssertTrue(mosshopFace.contains(PixelCoordinate(7, 4)))
        XCTAssertTrue(mosshopLimb.contains(PixelCoordinate(1, 6)))
        XCTAssertTrue(mosshopLimb.contains(PixelCoordinate(8, 6)))
        XCTAssertTrue(sparkfangLimb.contains(PixelCoordinate(2, 8)))
        XCTAssertTrue(sparkfangLimb.contains(PixelCoordinate(7, 8)))
    }

    func testRenderProfileUsesMutationBlueprintTags() {
        let bodyPhases = SpeciesVisualRenderProfile.mutationBodyPhases(for: "ridge-guard")
        let ecologySignature = SpeciesVisualRenderProfile.ecologySignaturePixels(for: "storm-slope")
        let rhythmSignature = SpeciesVisualRenderProfile.rhythmSignaturePixels(for: "tailwind-pulse")

        XCTAssertEqual(bodyPhases.phaseThree, [
            PixelCoordinate(2, 7),
            PixelCoordinate(7, 7),
        ])
        XCTAssertEqual(ecologySignature, [
            PixelCoordinate(0, 2),
            PixelCoordinate(9, 2),
            PixelCoordinate(0, 3),
            PixelCoordinate(9, 3),
        ])
        XCTAssertEqual(rhythmSignature, [
            PixelCoordinate(0, 4),
            PixelCoordinate(9, 4),
            PixelCoordinate(4, 9),
            PixelCoordinate(5, 9),
        ])
    }
}
