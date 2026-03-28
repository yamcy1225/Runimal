import RunimalCore
import SwiftUI

struct PhoneSanctuaryPanel: View {
    let reward: SanctuaryRewardEvent

    var body: some View {
        GameSurface(title: "Sanctuary Mode", accent: .mint, eyebrow: "휴식일 탐색") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "moon.stars.fill")
                        .font(.title3.weight(.black))
                        .foregroundStyle(.mint)
                        .frame(width: 42, height: 42)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.mint.opacity(0.16))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("틈새 세계 탐색 완료")
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)
                        Text(reward.logLine)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.66))
                            .lineLimit(2)
                    }
                }

                HStack(spacing: 8) {
                    TraitChip(label: "+\(reward.essenceGained) ESSENCE", accent: .mint)
                    if let itemLabel = reward.itemLabel {
                        TraitChip(label: itemLabel.uppercased(), accent: .white.opacity(0.2))
                    }
                }
            }
        }
    }
}
