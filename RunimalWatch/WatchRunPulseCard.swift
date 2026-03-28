import RunimalCore
import SwiftUI

struct WatchRunPulseCard: View {
    let feedback: LiveRunFeedback
    let accent: Color
    let badges: [String]

    var body: some View {
        GameSurface(compact: true) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TraitChip(label: feedback.label.uppercased(), accent: accent)
                    Spacer(minLength: 8)
                    Text("\(Int(feedback.intensity * 100))%")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.68))
                }

                Text(feedback.headline)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text(feedback.detail)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(3)

                if badges.isEmpty == false {
                    HStack(spacing: 6) {
                        ForEach(Array(badges.prefix(2).enumerated()), id: \.offset) { _, badge in
                            TraitChip(label: badge, accent: accent.opacity(0.82))
                        }
                    }
                }

                RunimalProgressBar(progress: feedback.intensity, accent: accent, height: 7)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.20), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}
