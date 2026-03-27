import Foundation
import Observation
import RunimalCore
import SwiftUI

@MainActor
@Observable
final class MacAssetPipelineStore {
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

    struct PreviewEntry: Identifiable {
        let id: String
        let pet: GeneratedPet
        let label: String
    }

    var draft = ""
    var status = "Asset pipeline idle"
    var previewEntries: [PreviewEntry] = []

    init() {
        load()
    }

    func load() {
        do {
            draft = try String(contentsOf: RunimalPaths.feedbackProfiles, encoding: .utf8)
            status = "Loaded asset pack"
            rebuildPreview()
        } catch {
            draft = ""
            status = "Load failed"
            previewEntries = []
        }
    }

    func save() {
        do {
            _ = try JSONSerialization.jsonObject(with: Data(draft.utf8))
            try draft.write(to: RunimalPaths.feedbackProfiles, atomically: true, encoding: .utf8)
            status = "Saved asset pack"
            rebuildPreview()
        } catch {
            status = "Save failed"
        }
    }

    func exportManifest() {
        do {
            let data = Data(draft.utf8)
            let catalog = try JSONDecoder().decode(Catalog.self, from: data)
            let lines = [
                "species=\(catalog.species.count)",
                "variants=\(catalog.variants.count)",
                "species_keys=\(catalog.species.keys.sorted().joined(separator: ","))",
                "variant_keys=\(catalog.variants.keys.sorted().joined(separator: ","))",
            ]
            try lines.joined(separator: "\n").write(to: RunimalPaths.feedbackManifest, atomically: true, encoding: .utf8)
            status = "Exported manifest"
        } catch {
            status = "Manifest export failed"
        }
    }

    private func rebuildPreview() {
        guard let catalog = try? JSONDecoder().decode(Catalog.self, from: Data(draft.utf8)) else {
            previewEntries = []
            return
        }

        let variants = RareVariant.allCases
        previewEntries = catalog.species.sorted(by: { $0.key < $1.key }).compactMap { entry -> [PreviewEntry]? in
            guard let species = PetSpecies(rawValue: entry.key) else { return nil }
            return variants.map { variant in
                let pet = GeneratedPet(
                    species: species,
                    element: element(for: species),
                    palette: palette(for: species),
                    rareVariant: variant,
                    explanation: ["asset preview"],
                    stats: PetStats(vitality: 5, agility: 5, dexterity: 5, focus: 5, defense: 5)
                )

                return PreviewEntry(
                    id: "\(entry.key)-\(variant.rawValue)",
                    pet: pet,
                    label: "\(entry.key) · \(variant.rawValue)"
                )
            }
        }
        .flatMap { $0 }
    }

    private func element(for species: PetSpecies) -> PetElement {
        switch species {
        case .windrunner: return .light
        case .stoneback: return .earth
        case .sparkfang: return .flame
        case .mosshop, .seedle: return .leaf
        case .shadebit: return .lunar
        }
    }

    private func palette(for species: PetSpecies) -> String {
        switch species {
        case .windrunner: return "aero"
        case .stoneback: return "granite"
        case .sparkfang: return "flare"
        case .mosshop: return "moss"
        case .shadebit: return "eclipse"
        case .seedle: return "sprout"
        }
    }
}

struct MacAssetPipelinePanel: View {
    @State private var store = MacAssetPipelineStore()

    var body: some View {
        GameSurface(title: "Asset Pipeline") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    TraitChip(label: store.status, accent: .purple.opacity(0.72))
                    Spacer()
                    TraitChip(label: "manifest", accent: .white.opacity(0.18))
                }

                TextEditor(text: $store.draft)
                    .font(.caption.monospaced())
                    .frame(minHeight: 220)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                HStack {
                    Button("Reload") {
                        store.load()
                    }
                    .buttonStyle(.bordered)

                    Button("Save Asset Pack") {
                        store.save()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple.opacity(0.82))

                    Button("Export Manifest") {
                        store.exportManifest()
                    }
                    .buttonStyle(.bordered)
                }

                if !store.previewEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Preview Grid")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.72))
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                            ForEach(store.previewEntries.prefix(12)) { entry in
                                VStack(spacing: 6) {
                                    PixelPetView(pet: entry.pet, pixelSize: 3.6)
                                        .frame(width: 46, height: 46)
                                    Text(entry.label)
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.white.opacity(0.72))
                                        .multilineTextAlignment(.center)
                                }
                                .padding(8)
                                .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                    }
                }
            }
        }
    }
}
