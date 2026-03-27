import RunimalCore
import SwiftUI

struct PhoneWeeklyBoardPanel: View {
    let board: WeeklyBoard
    let accent: Color

    var body: some View {
        GameSurface(title: "Weekly Board") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(board.weekLabel)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.68))
                        Text(board.headline)
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    TraitChip(label: "\(board.discoveredVariants) variants", accent: accent)
                }

                HStack {
                    summaryStat("Runs", value: "\(board.runCount)")
                    summaryStat("Distance", value: "\(board.totalDistanceKm.formatted(.number.precision(.fractionLength(1)))) km")
                    summaryStat("Streak", value: "\(board.streakDays) days")
                }

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(board.missions) { mission in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(mission.title)
                                        .foregroundStyle(.white)
                                    Text(mission.detail)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.68))
                                }
                                Spacer()
                                TraitChip(
                                    label: mission.completed ? "CLEAR" : mission.progressLabel,
                                    accent: mission.completed ? .green : .white.opacity(0.18)
                                )
                            }

                            RunimalProgressBar(
                                progress: mission.progressRatio,
                                accent: mission.completed ? .green : accent,
                                height: 8
                            )
                        }
                    }
                }
            }
        }
    }

    private func summaryStat(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.54))
            Text(value)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
