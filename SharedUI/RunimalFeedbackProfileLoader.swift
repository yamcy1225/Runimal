import Foundation
import RunimalCore

struct RunimalFeedbackProfileLoader {
    private struct Catalog: Decodable {
        let species: [String: SpeciesProfile]
        let variants: [String: VariantProfile]
    }

    private struct SpeciesProfile: Decodable {
        let hatchSound: UInt32
        let evolutionSound: UInt32
        let tilt: Double
    }

    private struct VariantProfile: Decodable {
        let evolutionSound: UInt32
        let points: [[Double]]
    }

    private static let catalog: Catalog? = {
        guard let url = Bundle.main.url(forResource: "feedback-profiles", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }

        return try? JSONDecoder().decode(Catalog.self, from: data)
    }()

    static func speciesProfile(for species: PetSpecies) -> (hatchSound: UInt32, evolutionSound: UInt32, tilt: Double)? {
        guard let profile = catalog?.species[species.rawValue] else { return nil }
        return (profile.hatchSound, profile.evolutionSound, profile.tilt)
    }

    static func variantEvolutionSound(for variant: RareVariant?) -> UInt32? {
        guard let variant else { return nil }
        return catalog?.variants[variant.rawValue]?.evolutionSound
    }

    static func burstPoints(for pet: GeneratedPet) -> [CGPoint]? {
        guard let variant = pet.rareVariant,
              let points = catalog?.variants[variant.rawValue]?.points else {
            return nil
        }

        return points.map { CGPoint(x: $0[0], y: $0[1]) }
    }
}
