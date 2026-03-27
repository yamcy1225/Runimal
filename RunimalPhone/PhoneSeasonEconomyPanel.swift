import RunimalCore
import SwiftUI

struct PhoneSeasonEconomyPanel: View {
    let board: SeasonEconomyBoard
    let onClaim: () -> Void

    var body: some View {
        GameSurface(title: "Season Cache") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    TraitChip(label: "\(board.affinityCount)/\(board.requiredCount)", accent: .mint.opacity(0.76))
                    TraitChip(label: board.rewardLabel, accent: .orange.opacity(0.72))
                }

                Text(board.headline)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))

                if board.claimable {
                    Button("Claim Season Cache") {
                        onClaim()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.mint)
                }
            }
        }
    }
}
