import RunimalCore
import SwiftUI

struct PhoneRaidBoardPanel: View {
    let encounters: [RaidEncounter]
    let claimedRaidRewardIDs: Set<String>
    let raidShardBalance: Int
    let onClaim: (String) -> Void

    var body: some View {
        GameSurface(title: "Raid Board") {
            VStack(alignment: .leading, spacing: 10) {
                TraitChip(label: "Raid shards \(raidShardBalance)", accent: .purple.opacity(0.76))

                ForEach(encounters) { encounter in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(encounter.title)
                                .foregroundStyle(.white)
                            Spacer()
                            TraitChip(label: "\(encounter.readinessScore)", accent: .purple.opacity(0.72))
                        }
                        Text(encounter.detail)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                        Text("Reward · \(encounter.recommendedReward)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.58))

                        if claimedRaidRewardIDs.contains(encounter.id) {
                            TraitChip(label: "CLAIMED", accent: .green.opacity(0.76))
                        } else {
                            Button("Claim Raid Reward") {
                                onClaim(encounter.id)
                            }
                            .buttonStyle(.bordered)
                            .tint(.purple)
                            .disabled(encounter.readinessScore < encounter.claimThreshold)
                        }
                    }
                }
            }
        }
    }
}
