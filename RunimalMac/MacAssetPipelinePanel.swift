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
    var previewCards: [String] = []

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
            previewCards = []
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
            previewCards = []
            return
        }

        previewCards = catalog.species.sorted(by: { $0.key < $1.key }).map { key, value in
            "\(key) · hatch \(value.hatchSound) · evo \(value.evolutionSound) · tilt \(String(format: "%.1f", value.tilt))"
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

                if !store.previewCards.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Preview Render")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.72))
                        ForEach(store.previewCards.prefix(4), id: \.self) { card in
                            HStack(spacing: 10) {
                                DotPreviewTile(label: card)
                                Text(card)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.white.opacity(0.72))
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct DotPreviewTile: View {
    let label: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.white.opacity(0.08))
                .frame(width: 44, height: 44)

            VStack(spacing: 2) {
                Rectangle()
                    .fill(headColor)
                    .frame(width: bodyWidth, height: 12)
                Rectangle()
                    .fill(accentColor)
                    .frame(width: 20, height: 6)
                if label.contains("sparkfang") || label.contains("windrunner") {
                    Rectangle()
                        .fill(.yellow.opacity(0.8))
                        .frame(width: 8, height: 4)
                }
            }
            .rotationEffect(.degrees(label.contains("tilt -") ? -8 : 8))
        }
    }

    private var headColor: Color {
        if label.contains("stoneback") { return .brown.opacity(0.82) }
        if label.contains("mosshop") { return .green.opacity(0.82) }
        if label.contains("shadebit") { return .blue.opacity(0.82) }
        return .white.opacity(0.9)
    }

    private var accentColor: Color {
        if label.contains("sparkfang") { return .orange.opacity(0.82) }
        if label.contains("windrunner") { return .cyan.opacity(0.82) }
        return .purple.opacity(0.7)
    }

    private var bodyWidth: CGFloat {
        if label.contains("stoneback") { return 18 }
        if label.contains("seedle") { return 10 }
        return 14
    }
}
