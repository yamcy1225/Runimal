import RunimalCore
import SwiftUI

struct WatchGoalTrackCard: View {
    let goals: [LiveGoalTarget]
    let accent: Color

    var body: some View {
        GameSurface(title: "목표", accent: accent, compact: true) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(goals.prefix(1)) { goal in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(goal.title)
                                .font(.headline.monospaced().weight(.black))
                                .foregroundStyle(GameBoyPalette.darkest)
                                .lineLimit(2)
                                .minimumScaleFactor(0.78)
                            Spacer()
                            TraitChip(label: goal.status.uppercased(), accent: accent.opacity(0.82))
                        }
                    }
                }
            }
        }
    }
}
