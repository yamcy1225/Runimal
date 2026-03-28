import RunimalCore
import SwiftUI

struct WatchGoalTrackCard: View {
    let goals: [LiveGoalTarget]
    let accent: Color

    var body: some View {
        GameSurface(title: "목표", compact: true) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(goals.prefix(2)) { goal in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(goal.title)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Spacer()
                            TraitChip(label: goal.status.uppercased(), accent: accent.opacity(0.82))
                        }

                        Text(goal.detail)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.72))
                            .lineLimit(2)

                        RunimalProgressBar(progress: goal.progress, accent: accent, height: 6)
                    }
                }
            }
        }
    }
}
