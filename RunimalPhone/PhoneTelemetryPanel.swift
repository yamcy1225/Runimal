import SwiftUI

struct PhoneTelemetryPanel: View {
    let logger: PhoneTelemetryLogger

    private var ftueSummary: PhoneTelemetryLogger.SectionSummary {
        logger.sectionSummary(
            title: "첫 경험",
            events: ["first_run_completed", "egg_created", "egg_hatched", "first_stage_up"]
        )
    }

    private var rewardSummary: PhoneTelemetryLogger.SectionSummary {
        logger.sectionSummary(
            title: "보상",
            events: ["reward_ingested", "reward_pulse_applied", "signal_lock_applied", "decode_lock_applied", "weekly_reward_claimed"]
        )
    }

    private var rareSummary: PhoneTelemetryLogger.SectionSummary {
        logger.sectionSummary(
            title: "희귀",
            events: ["rare_variant_obtained"]
        )
    }

    var body: some View {
        GameSurface(title: "진행 로그", accent: .cyan, eyebrow: "리텐션 계측") {
            VStack(alignment: .leading, spacing: 14) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    summaryTile(ftueSummary, accent: .mint)
                    summaryTile(rewardSummary, accent: .orange)
                    summaryTile(rareSummary, accent: .purple)
                }

                HStack(spacing: 8) {
                    TraitChip(label: "\(logger.eventCount) events", accent: .cyan.opacity(0.76))
                    TraitChip(label: "latest", accent: .white.opacity(0.18))
                }

                Text(logger.lastEventLabel)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.76))

                Text(logger.logPath())
                    .font(.caption2.monospaced())
                    .foregroundStyle(.white.opacity(0.52))
                    .lineLimit(2)
            }
        }
    }

    private func summaryTile(_ summary: PhoneTelemetryLogger.SectionSummary, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(summary.title)
                    .font(.caption.weight(.black))
                    .foregroundStyle(accent)
                Spacer()
                Text("\(summary.count)")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
            }

            Text(summary.lastDetail)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.68))
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(accent.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(accent.opacity(0.22), lineWidth: 1)
                )
        )
    }
}
