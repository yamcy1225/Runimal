import Foundation
import SwiftUI

struct MacAssetPackPanel: View {
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

    private let catalog: Catalog?

    init() {
        catalog = Self.loadCatalog()
    }

    var body: some View {
        GameSurface(title: "Asset Pack Inspector") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    TraitChip(label: "\(catalog?.species.count ?? 0) species", accent: .blue.opacity(0.72))
                    TraitChip(label: "\(catalog?.variants.count ?? 0) variants", accent: .purple.opacity(0.72))
                }

                if let species = catalog?.species.sorted(by: { $0.key < $1.key }).first {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Species Profile")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.72))
                        Text(species.key)
                            .foregroundStyle(.white)
                        HStack {
                            TraitChip(label: "hatch \(species.value.hatchSound)", accent: .white.opacity(0.18))
                            TraitChip(label: "evo \(species.value.evolutionSound)", accent: .white.opacity(0.18))
                            TraitChip(label: String(format: "tilt %.1f", species.value.tilt), accent: .cyan.opacity(0.72))
                        }
                    }
                }

                if let variant = catalog?.variants.sorted(by: { $0.key < $1.key }).first {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Variant Burst")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.72))
                        Text(variant.key)
                            .foregroundStyle(.white)
                        HStack {
                            TraitChip(label: "evo \(variant.value.evolutionSound)", accent: .orange.opacity(0.72))
                            TraitChip(label: "\(variant.value.points.count) points", accent: .white.opacity(0.18))
                        }
                        Text(variant.value.points.map { point in
                            "(\(Int(point[0])), \(Int(point[1])))"
                        }.joined(separator: "  "))
                        .font(.caption.monospaced())
                        .foregroundStyle(.white.opacity(0.66))
                    }
                }
            }
        }
    }

    private static func loadCatalog() -> Catalog? {
        guard let url = Bundle.main.url(forResource: "feedback-profiles", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }

        return try? JSONDecoder().decode(Catalog.self, from: data)
    }
}
