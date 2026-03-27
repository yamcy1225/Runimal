import RunimalCore
import SwiftUI

struct PhoneRaidBossPatternPanel: View {
    let patterns: [RaidBossPattern]
    let turns: [RaidTurnResult]

    var body: some View {
        GameSurface(title: "Boss Pattern Read") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(patterns) { pattern in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(pattern.title)
                                .foregroundStyle(.white)
                            Spacer()
                            TraitChip(label: pattern.emphasis.uppercased(), accent: .red.opacity(0.72))
                        }
                        Text(pattern.detail)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }

                Divider()
                    .overlay(.white.opacity(0.12))

                ForEach(turns) { turn in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(turn.title)
                                .foregroundStyle(.white)
                            Text(turn.detail)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.66))
                        }
                        Spacer()
                        TraitChip(label: "\(turn.score)", accent: .orange.opacity(0.72))
                    }
                }
            }
        }
    }
}
