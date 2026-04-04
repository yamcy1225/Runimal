import RunimalCore
import SwiftUI

struct WatchRunStatsPanel: View {
    let snapshot: LiveRunSnapshot
    let gpsAccuracyMeters: Double?
    let lastGPSUpdateAt: Date?
    let locationStatusLabel: String
    let interactionPreview: LiveCompanionInteractionPreview
    let companion: WatchMainCompanionContext?
    let accent: Color

    var body: some View {
        GameSurface(title: nil, accent: accent, compact: true) {
            VStack(alignment: .leading, spacing: 6) {
                heroBand

                HStack(spacing: 5) {
                    metricColumn(title: "PACE", value: paceText, emphasis: true)
                    metricColumn(title: "HR", value: heartRateText, emphasis: false)
                    metricColumn(title: "CAD", value: cadenceText, emphasis: false)
                }

                progressBand
            }
        }
    }

    private var distanceText: String {
        String(format: "%.2f km", snapshot.distanceMeters / 1000)
    }

    private var elapsedText: String {
        let minutes = snapshot.elapsedSeconds / 60
        let seconds = snapshot.elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var paceText: String {
        guard let seconds = snapshot.averagePaceSeconds, seconds > 0 else { return "--:--" }
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%d:%02d", minutes, remainder)
    }

    private var heartRateText: String {
        guard let bpm = snapshot.currentHeartRate else { return "--" }
        return "\(Int(bpm))"
    }

    private var cadenceText: String {
        guard let cadence = snapshot.cadence else { return "--" }
        return "\(cadence)"
    }

    private var heroBand: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("거리")
                    .font(.caption2.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.mediumDark)

                Text(distanceText)
                    .font(.system(size: 21, weight: .black, design: .monospaced))
                    .foregroundStyle(GameBoyPalette.darkest)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text("\(elapsedText) · \(gpsCompactLabel)")
                .font(.caption2.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.mediumDark)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 0)
            companionOrb
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(GameBoyPalette.lightest.opacity(0.84))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(GameBoyPalette.darkest, lineWidth: 1)
                )
        )
    }

    private var companionOrb: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.18))
                .frame(width: 44, height: 44)
            Circle()
                .stroke(accent.opacity(0.55), lineWidth: 2)
                .frame(width: 44, height: 44)

            if let pet = companion?.pet {
                PixelPetView(
                    pet: pet,
                    pixelSize: 3.2,
                    growthStageIndex: companion?.growthStageIndex,
                    mutationVisualState: MutationVisualState(
                        bodyStage: companion?.mutationBodyStage ?? 0,
                        ecologyStage: companion?.mutationEcologyStage ?? 0,
                        rhythmStage: companion?.mutationRhythmStage ?? 0
                    )
                )
                .scaleEffect(0.98)
            } else {
                Image(systemName: "figure.run")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(accent)
            }
        }
    }

    private func metricColumn(title: String, value: String, emphasis: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.mediumDark)

            Text(value)
                .font(emphasis ? .footnote.monospacedDigit().weight(.black) : .caption.monospacedDigit().weight(.black))
                .foregroundStyle(GameBoyPalette.darkest)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(emphasis ? GameBoyPalette.lightest : GameBoyPalette.mediumLight.opacity(0.48))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(GameBoyPalette.darkest, lineWidth: 1)
                )
        )
    }

    private var progressBand: some View {
        let primaryCue = interactionPreview.cues.first(where: \.isActive) ?? interactionPreview.cues.first
        let projectedPotentialLabel: String = {
            guard interactionPreview.projectedPotentialExperience > 0 else { return "잠재 대기" }
            return "잠재 +\(interactionPreview.projectedPotentialExperience)"
        }()
        let companionGrowthLabel: String? = {
            guard let level = companion?.companionLevel,
                  let stageLabel = companion?.companionStageLabel else {
                return nil
            }
            return "Lv.\(level) · \(stageLabel)"
        }()
        let cueProgress = primaryCue?.progress ?? 0.18

        return VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(companionGrowthLabel ?? "성장 파동")
                    .font(.caption2.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.darkest)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Spacer(minLength: 6)
                Text(projectedPotentialLabel)
                    .font(.caption2.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.mediumDark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            RunimalProgressBar(progress: cueProgress, accent: accent, height: 7)
                .frame(height: 7)

            HStack(spacing: 6) {
                Text(primaryCue?.title ?? interactionPreview.headline)
                    .font(.caption2.monospaced())
                    .foregroundStyle(GameBoyPalette.mediumDark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Spacer(minLength: 4)
                Text(primaryCue?.statusLabel ?? "준비")
                    .font(.caption2.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.darkest)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(GameBoyPalette.lightest)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(GameBoyPalette.darkest, lineWidth: 1)
                )
        )
    }

    private var gpsCompactLabel: String {
        if locationStatusLabel.contains("denied") || locationStatusLabel.contains("restricted") {
            return "OFF"
        }
        guard let gpsAccuracyMeters else { return "WAIT" }
        if let lastGPSUpdateAt, Date().timeIntervalSince(lastGPSUpdateAt) > 8 {
            return "WAIT"
        }
        if gpsAccuracyMeters < 12 {
            return "READY"
        }
        if gpsAccuracyMeters < 24 {
            return "FAIR"
        }
        return "SOFT"
    }
}
