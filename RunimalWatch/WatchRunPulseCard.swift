import RunimalCore
import SwiftUI

struct WatchRunPulseCard: View {
    let feedback: LiveRunFeedback
    let accent: Color
    let interactionPreview: LiveCompanionInteractionPreview
    let companion: WatchMainCompanionContext?
    let badges: [String]
    let reaction: MutationRuntimeReactionSnapshot?

    var body: some View {
        GameSurface(title: nil, accent: accent, compact: true) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    TraitChip(label: feedbackBadgeLabel, accent: accent)
                    levelBadge
                    Spacer(minLength: 0)
                    Text("\(Int(feedback.intensity * 100))%")
                        .font(.caption.monospacedDigit().weight(.black))
                        .foregroundStyle(GameBoyPalette.darkest)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(pulseHeadline)
                        .font(.subheadline.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.darkest)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)

                    Text(feedbackHeadline)
                        .font(.caption2.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.mediumDark)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                spotlightBand

                if let activeCue = interactionPreview.cues.first(where: \.isActive) ?? interactionPreview.cues.first {
                    signalRow(
                        title: activeCue.title,
                        status: activeCue.statusLabel,
                        detail: activeCue.detail,
                        progress: activeCue.progress,
                        accent: accent
                    )
                }

                if companion?.companionStageLabel != nil || activePotentialCount > 0 {
                    footerBand
                }
            }
        }
    }

    private var levelBadge: some View {
        Text(levelBadgeLabel)
            .font(.caption2.monospaced().weight(.black))
            .foregroundStyle(GameBoyPalette.darkest)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(GameBoyPalette.lightest.opacity(0.84))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(GameBoyPalette.darkest, lineWidth: 1)
                    )
            )
    }

    private var spotlightBand: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(reaction?.title ?? "현재 반응")
                    .font(.caption2.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.darkest)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Spacer(minLength: 4)
                Text(projectedPotentialLabel)
                    .font(.caption2.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.mediumDark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Text(spotlightDetailLabel)
                .font(.caption2.monospaced())
                .foregroundStyle(GameBoyPalette.darkest)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            RunimalProgressBar(progress: feedback.intensity, accent: accent, height: 8)
                .frame(height: 8)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(GameBoyPalette.lightest.opacity(0.84))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(GameBoyPalette.darkest, lineWidth: 1)
                )
        )
    }

    private var footerBand: some View {
        HStack(spacing: 6) {
            if let stageLabel = companion?.companionStageLabel {
                TraitChip(label: stageLabel, accent: accent.opacity(0.82))
            }
            Spacer(minLength: 0)
            Text("활성 \(activePotentialCount)건")
                .font(.caption2.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.mediumDark)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
    }

    private var projectedPotentialLabel: String {
        if interactionPreview.projectedPotentialExperience > 0 {
            return "잠재 +\(interactionPreview.projectedPotentialExperience)"
        }
        return "잠재 대기"
    }

    private var feedbackBadgeLabel: String {
        switch feedback.label {
        case "Rare Window":
            return "RARE"
        case "Surge":
            return "SURGE"
        case "Stable":
            return "FLOW"
        case "Recover":
            return "CALM"
        default:
            return "LIVE"
        }
    }

    private var levelBadgeLabel: String {
        if let level = companion?.companionLevel {
            return "Lv.\(level)"
        }
        return "WATCH"
    }

    private var pulseHeadline: String {
        reaction?.title ?? interactionPreview.headline
    }

    private var feedbackHeadline: String {
        if feedback.label == "Rare Window" {
            return "희귀 변이 창이 열려 있습니다"
        }
        return feedback.headline
    }

    private var spotlightDetailLabel: String {
        if feedback.label == "Rare Window" {
            return "희귀 변이 창이 가까워졌어요"
        }
        guard let reaction else {
            return "지금 리듬을 안정적으로 유지 중"
        }
        switch reaction.axis {
        case .body:
            return "힘이 올라오며 반응이 선명해져요"
        case .ecology:
            return "호흡과 주변 흐름이 안정되고 있어요"
        case .rhythm:
            return "페이스와 케이던스가 잘 맞고 있어요"
        }
    }

    private var activePotentialCount: Int {
        interactionPreview.cues.filter { $0.category == .potential && $0.isActive }.count
    }

    private func signalRow(
        title: String,
        status: String,
        detail: String,
        progress: Double,
        accent: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.caption2.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.darkest)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Spacer(minLength: 6)
                Text(status)
                    .font(.caption2.monospacedDigit().weight(.black))
                    .foregroundStyle(accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            RunimalProgressBar(progress: progress, accent: accent, height: 6)
                .frame(height: 6)

        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(GameBoyPalette.mediumLight.opacity(0.34))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(GameBoyPalette.darkest, lineWidth: 1)
                )
        )
    }
}
