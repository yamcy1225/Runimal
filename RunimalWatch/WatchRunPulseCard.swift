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
        GameSurface(title: "러닝 상태", accent: accent, compact: true) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TraitChip(label: feedback.label.uppercased(), accent: accent)
                    TraitChip(
                        label: interactionPreview.projectedPotentialExperience > 0
                            ? "잠재 +\(interactionPreview.projectedPotentialExperience)"
                            : "잠재 대기",
                        accent: accent.opacity(0.72)
                    )
                    Spacer(minLength: 8)
                    Text("\(Int(feedback.intensity * 100))%")
                        .font(.caption.monospacedDigit().weight(.black))
                        .foregroundStyle(GameBoyPalette.mediumDark)
                }

                if let level = companion?.companionLevel,
                   let stageLabel = companion?.companionStageLabel {
                    HStack(spacing: 6) {
                        TraitChip(label: "Lv.\(level)", accent: accent.opacity(0.82))
                        TraitChip(label: stageLabel, accent: .white.opacity(0.14))
                        Spacer(minLength: 6)
                        Text("활성 \(activePotentialCount)건")
                            .font(.caption2.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.mediumDark)
                    }
                }

                Text(interactionPreview.headline)
                    .font(.headline.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.darkest)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                VStack(alignment: .leading, spacing: 3) {
                    Text("지금 반응")
                        .font(.caption2.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.mediumDark)
                    Text(interactionPreview.detail)
                        .font(.caption2.monospaced())
                        .foregroundStyle(GameBoyPalette.darkest)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                }

                Text(feedback.headline)
                    .font(.caption2.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.mediumDark)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                VStack(alignment: .leading, spacing: 5) {
                    ForEach(Array(interactionPreview.cues.prefix(3))) { cue in
                        cueRow(cue)
                    }
                }

                if let reaction, interactionPreview.cues.contains(where: { $0.id == reaction.id }) == false {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(reaction.title)
                            .font(.caption2.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.mediumDark)
                        Text(reaction.detail)
                            .font(.caption2.monospaced())
                            .foregroundStyle(GameBoyPalette.darkest)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                    }
                }

                if badges.isEmpty == false {
                    HStack(spacing: 6) {
                        ForEach(Array(badges.prefix(2).enumerated()), id: \.offset) { _, badge in
                            TraitChip(label: badge, accent: accent.opacity(0.82))
                        }
                    }
                }

                if let nextPotentialCue {
                    Text("다음 열림: \(nextPotentialCue.title)")
                        .font(.caption2.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.mediumDark)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
            }
        }
    }

    private var activePotentialCount: Int {
        interactionPreview.cues.filter { $0.category == .potential && $0.isActive }.count
    }

    private var nextPotentialCue: LiveCompanionInteractionCue? {
        interactionPreview.cues.first { $0.category == .potential && $0.isActive == false }
    }

    private func cueRow(_ cue: LiveCompanionInteractionCue) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(cue.title)
                    .font(.caption2.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.darkest)
                    .lineLimit(1)
                Spacer(minLength: 6)
                Text(cue.statusLabel)
                    .font(.caption2.monospacedDigit().weight(.black))
                    .foregroundStyle(cue.isActive ? accent : GameBoyPalette.mediumDark)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(GameBoyPalette.mediumLight.opacity(0.55))
                    Capsule()
                        .fill(cue.isActive ? accent : GameBoyPalette.mediumDark.opacity(0.7))
                        .frame(width: max(proxy.size.width * cue.progress, cue.progress > 0 ? 8 : 0))
                }
            }
            .frame(height: 5)

            Text(cue.detail)
                .font(.caption2.monospaced())
                .foregroundStyle(GameBoyPalette.mediumDark)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}
