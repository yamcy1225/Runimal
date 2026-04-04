import RunimalCore
import SwiftUI

struct PhoneWeeklyBoardPanel: View {
    let board: WeeklyBoard
    let accent: Color
    let claimedRewardIDs: Set<String>
    let activeEffects: [WeeklyRewardEffect]

    var body: some View {
        GameSurface(title: "Weekly Board") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(board.season.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(accent)
                        Text(board.season.subtitle)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.68))
                        Text(board.weekLabel)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.68))
                        Text(board.headline)
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    TraitChip(label: "\(board.discoveredVariants) variants", accent: accent)
                }

                Text(board.season.bonus)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))

                HStack {
                    summaryStat("Runs", value: "\(board.runCount)")
                    summaryStat("Distance", value: "\(board.totalDistanceKm.formatted(.number.precision(.fractionLength(1)))) km")
                    summaryStat("Streak", value: "\(board.streakDays) days")
                }

                HStack {
                    TraitChip(label: "\(board.completedMissionCount)/\(board.missions.count) cleared", accent: accent)
                    if claimedRewardIDs.isEmpty == false {
                        TraitChip(label: "\(claimedRewardIDs.count) claimed", accent: .green)
                    }
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

                VStack(alignment: .leading, spacing: 10) {
                    Text("Weekly Rewards")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.74))

                    ForEach(board.rewards) { reward in
                        let unlocked = board.completedMissionCount >= reward.unlockRequirement
                        let claimed = claimedRewardIDs.contains(reward.id)

                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(claimed ? .green : (unlocked ? accent : .white.opacity(0.15)))
                                .frame(width: 10, height: 10)
                                .padding(.top, 5)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(reward.title)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    TraitChip(
                                        label: claimed ? "받음" : (unlocked ? "받기 가능" : "잠김"),
                                        accent: claimed ? .green : (unlocked ? accent : .white.opacity(0.18))
                                    )
                                }

                                Text(reward.detail)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.68))
                            }
                        }
                    }
                }

                if activeEffects.isEmpty == false {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Active Effects")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.74))

                        ForEach(activeEffects) { effect in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(effect.title)
                                    .foregroundStyle(.white)
                                Text(effect.detail)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.68))
                            }
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
