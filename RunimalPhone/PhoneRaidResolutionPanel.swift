import RunimalCore
import SwiftUI

struct PhoneRaidResolutionPanel: View {
    let resolution: RaidResolution?

    var body: some View {
        if let resolution {
            GameSurface(title: "Latest Raid Result") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(resolution.title)
                            .foregroundStyle(.white)
                        Spacer()
                        TraitChip(label: "Tier \(resolution.tier)", accent: .purple.opacity(0.76))
                    }

                    Text("+\(resolution.shardReward) shard · +\(resolution.essenceReward) essence")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                }
            }
        }
    }
}
