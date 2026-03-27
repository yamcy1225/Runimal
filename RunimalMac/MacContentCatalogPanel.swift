import Foundation
import SwiftUI

struct MacContentCatalogPanel: View {
    private struct RotationEntry: Decodable, Identifiable {
        let id: String
        let title: String
        let detail: String
        let reward: String
    }

    private struct RaidTemplate: Decodable, Identifiable {
        let id: String
        let title: String
        let detail: String
        let recommendedReward: String
        let claimThreshold: Int
    }

    private let rotationEntries: [RotationEntry]
    private let raidTemplates: [RaidTemplate]

    init() {
        rotationEntries = Self.load("rotation", as: [RotationEntry].self) ?? []
        raidTemplates = Self.load("raids", as: [RaidTemplate].self) ?? []
    }

    var body: some View {
        GameSurface(title: "Content Catalog") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    TraitChip(label: "\(rotationEntries.count) rotations", accent: .mint.opacity(0.72))
                    TraitChip(label: "\(raidTemplates.count) raids", accent: .orange.opacity(0.72))
                }

                if let firstRotation = rotationEntries.first {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Rotation Preview")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.72))
                        Text(firstRotation.title)
                            .foregroundStyle(.white)
                        Text(firstRotation.detail)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                        TraitChip(label: firstRotation.reward, accent: .white.opacity(0.18))
                    }
                }

                if let firstRaid = raidTemplates.first {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Raid Preview")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.72))
                        Text(firstRaid.title)
                            .foregroundStyle(.white)
                        Text(firstRaid.detail)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                        HStack {
                            TraitChip(label: firstRaid.recommendedReward, accent: .red.opacity(0.72))
                            TraitChip(label: "threshold \(firstRaid.claimThreshold)", accent: .white.opacity(0.18))
                        }
                    }
                }
            }
        }
    }

    private static func load<T: Decodable>(_ name: String, as type: T.Type) -> T? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }

        return try? JSONDecoder().decode(T.self, from: data)
    }
}
