import RunimalCore
import SwiftUI

struct WatchRunPulseCard: View {
    let feedback: LiveRunFeedback
    let accent: Color
    let reaction: MutationRuntimeReactionSnapshot?
    let badges: [String]
    let goalTitle: String?
    let goalDetail: String

    var body: some View {
        GameSurface(title: "러닝 상태", accent: accent, compact: true) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TraitChip(label: feedback.label.uppercased(), accent: accent)
                    Spacer(minLength: 8)
                    Text("\(Int(feedback.intensity * 100))%")
                        .font(.caption.monospacedDigit().weight(.black))
                        .foregroundStyle(GameBoyPalette.mediumDark)
                }

                Text(feedback.headline)
                    .font(.headline.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.darkest)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                VStack(alignment: .leading, spacing: 3) {
                    Text(goalTitle ?? "지금 목표")
                        .font(.caption2.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.mediumDark)
                    Text(goalDetail)
                        .font(.caption2.monospaced())
                        .foregroundStyle(GameBoyPalette.darkest)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                }

                if let reaction {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(reaction.title)
                            .font(.caption2.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.mediumDark)
                        Text(reaction.detail)
                            .font(.caption2.monospaced())
                            .foregroundStyle(GameBoyPalette.darkest)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                    }
                }

                if badges.isEmpty == false {
                    HStack(spacing: 6) {
                        ForEach(Array(badges.prefix(2).enumerated()), id: \.offset) { _, badge in
                            TraitChip(label: badge, accent: accent.opacity(0.82))
                        }
                    }
                }
            }
        }
    }
}
