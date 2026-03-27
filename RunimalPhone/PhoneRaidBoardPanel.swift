import RunimalCore
import SwiftUI

struct PhoneRaidBoardPanel: View {
    let encounters: [RaidEncounter]

    var body: some View {
        GameSurface(title: "Raid Board") {
            VStack(alignment: .leading, spacing: 10) {
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
                    }
                }
            }
        }
    }
}
