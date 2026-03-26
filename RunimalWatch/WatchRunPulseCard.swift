import RunimalCore
import SwiftUI

struct WatchRunPulseCard: View {
    let feedback: LiveRunFeedback
    let accent: Color

    var body: some View {
        GameSurface {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    TraitChip(label: feedback.label.uppercased(), accent: accent)
                    Spacer(minLength: 8)
                    Text("\(Int(feedback.intensity * 100))%")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.68))
                }

                Text(feedback.headline)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)

                Text(feedback.detail)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)

                RunimalProgressBar(progress: feedback.intensity, accent: accent, height: 7)
            }
        }
    }
}
