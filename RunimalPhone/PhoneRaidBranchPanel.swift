import RunimalCore
import SwiftUI

struct PhoneRaidBranchPanel: View {
    let reward: RaidBranchReward

    var body: some View {
        GameSurface(title: "Season Branch Reward") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(reward.branchTitle)
                        .foregroundStyle(.white)
                    Spacer()
                    TraitChip(label: "+\(reward.extraEssence) essence", accent: .orange.opacity(0.72))
                }

                HStack {
                    TraitChip(label: "+\(reward.extraSigils) sigil", accent: .mint.opacity(0.72))
                    TraitChip(label: "+\(reward.extraOverdrive) overdrive", accent: .red.opacity(0.72))
                }
            }
        }
    }
}
