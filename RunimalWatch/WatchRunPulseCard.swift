import RunimalCore
import SwiftUI

struct WatchRunPulseCard: View {
    let feedback: LiveRunFeedback
    let accent: Color
    let badges: [String]

    var body: some View {
        GameSurface(title: "피드백", accent: accent, compact: true) {
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

                if badges.isEmpty == false {
                    HStack(spacing: 6) {
                        ForEach(Array(badges.prefix(1).enumerated()), id: \.offset) { _, badge in
                            TraitChip(label: badge, accent: accent.opacity(0.82))
                        }
                    }
                }
            }
        }
    }
}
