import XCTest
@testable import RunimalCore

final class SpeciesColorIdentityTests: XCTestCase {
    func testBasePaletteNamesStayUniqueAcrossCoreSpecies() {
        let species: [PetSpecies] = [.windrunner, .stoneback, .sparkfang, .mosshop, .seedle]
        let paletteNames = species.map(\.basePaletteName)
        let hexValues = species.map(\.baseColorHex)

        XCTAssertEqual(Set(paletteNames).count, species.count)
        XCTAssertEqual(Set(hexValues).count, species.count)
    }

    func testPaletteNameKeepsSpeciesBaseWhenVariantAppears() {
        XCTAssertEqual(PetSpecies.windrunner.paletteName(), "Sky Teal")
        XCTAssertEqual(PetSpecies.windrunner.paletteName(rareVariant: .loopSigil), "Sky Teal Sigil")
        XCTAssertEqual(PetSpecies.mosshop.paletteName(rareVariant: .zenBloom), "Moss Jade Zen")
        XCTAssertEqual(PetSpecies.sparkfang.paletteName(rareVariant: .tempoSurge), "Ember Coral Rush")
    }

    func testGeneratedPetPaletteUsesSpeciesIdentityInsteadOfElementFamily() {
        let sampleRun = RunSummary(
            distanceKm: 10.02,
            averagePaceSeconds: 318,
            cadence: 174,
            elevationGainM: 0,
            variability: 0.06,
            aura: .day,
            shape: .outAndBack
        )

        let samplePet = RunimalGameEngine.generatePet(from: sampleRun)

        XCTAssertEqual(samplePet.species, .windrunner)
        XCTAssertEqual(samplePet.rareVariant, .zenBloom)
        XCTAssertEqual(samplePet.palette, "Sky Teal Zen")
    }
}
