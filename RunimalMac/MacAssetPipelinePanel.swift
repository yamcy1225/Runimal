import Foundation
import Observation
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

    var draft = ""
    var status = "Asset pipeline idle"

    init() {
        load()
    }

    func load() {
        do {
            draft = try String(contentsOf: RunimalPaths.feedbackProfiles, encoding: .utf8)
            status = "Loaded asset pack"
        } catch {
            draft = ""
            status = "Load failed"
        }
    }

    func save() {
        do {
            _ = try JSONSerialization.jsonObject(with: Data(draft.utf8))
            try draft.write(to: RunimalPaths.feedbackProfiles, atomically: true, encoding: .utf8)
            status = "Saved asset pack"
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
            }
        }
    }
}
