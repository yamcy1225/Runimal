import RunimalCore
import SwiftUI

struct WatchGoalTrackCard: View {
    let goals: [LiveGoalTarget]
    let accent: Color

    var body: some View {
        GameSurface(title: "Goal Track") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(goals) { goal in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(goal.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                            Spacer()
                            TraitChip(label: goal.status.uppercased(), accent: accent.opacity(0.82))
                        }

                        Text(goal.detail)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)

                        RunimalProgressBar(progress: goal.progress, accent: accent, height: 6)
                    }
                }
            }
        }
    }
}
