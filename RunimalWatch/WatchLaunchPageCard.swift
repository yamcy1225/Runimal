import RunimalCore
import SwiftUI

struct WatchLaunchPageCard: View {
    let companion: WatchMainCompanionContext?
    let accent: Color
    let sessionStateLabel: String
    let heartResonance: Double
    let gpsAccuracyMeters: Double?
    let lastGPSUpdateAt: Date?
    let locationStatusLabel: String
    let countdownValue: Int?
    let onPrimaryAction: () -> Void
    let onRefreshCompanion: () -> Void

    private var primaryButtonLabel: String {
        sessionStateLabel == "running" ? "운동 끝내기" : "러닝 시작하기"
    }

    private var primaryButtonAccent: Color {
        sessionStateLabel == "running" ? GameBoyPalette.darkest : GameBoyPalette.mediumDark
    }

    private var gpsSignalStrength: Double {
        if locationStatusLabel.contains("denied") || locationStatusLabel.contains("restricted") {
            return 0.12
        }
        guard let gpsAccuracyMeters else { return 0.18 }
        if isGPSStale {
            return 0.2
        }
        switch gpsAccuracyMeters {
        case ..<12:
            return 1.0
        case ..<24:
            return 0.66
        default:
            return 0.34
        }
    }

    private var gpsSignalColor: Color {
        if locationStatusLabel.contains("denied") || locationStatusLabel.contains("restricted") {
            return .red.opacity(0.92)
        }
        guard let gpsAccuracyMeters else { return .orange.opacity(0.88) }
        if isGPSStale {
            return .yellow.opacity(0.9)
        }
        switch gpsAccuracyMeters {
        case ..<12:
            return .green.opacity(0.9)
        case ..<24:
            return .yellow.opacity(0.9)
        default:
            return .red.opacity(0.92)
        }
    }

    private var isGPSStale: Bool {
        guard let lastGPSUpdateAt else { return true }
        return Date().timeIntervalSince(lastGPSUpdateAt) > 8
    }

    var body: some View {
        GameSurface(compact: true) {
            VStack(spacing: 8) {
                gpsHeader
                companionField
                primaryButton
            }
        }
        .task {
            onRefreshCompanion()
        }
    }

    private var gpsHeader: some View {
        HStack(spacing: 8) {
            Text("GPS")
                .font(.caption.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.mediumDark)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(GameBoyPalette.mediumLight.opacity(0.32))
                    Capsule(style: .continuous)
                        .fill(gpsSignalColor)
                        .frame(width: max(geometry.size.width * gpsSignalStrength, 12))
                }
            }
            .frame(height: 10)
        }
    }

    private var companionField: some View {
        VStack(spacing: 6) {
            if let companion {
                companionSummary(companion)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(GameBoyPalette.mediumLight.opacity(0.18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(GameBoyPalette.darkest, lineWidth: 2)
                        )

                    VStack(spacing: 6) {
                        Image(systemName: "applewatch.radiowaves.left.and.right")
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(GameBoyPalette.mediumDark)
                        Text("동행 대기")
                            .font(.caption.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.darkest)
                    }
                }
                .frame(height: 74)
            }
        }
    }

    private func companionSummary(_ companion: WatchMainCompanionContext) -> some View {
        VStack(spacing: 8) {
            WatchCompanionActionField(
                companion: companion,
                accent: accent,
                heartResonance: heartResonance,
                isRunning: sessionStateLabel == "running"
            )

            Text(companion.displayName)
                .font(.subheadline.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.darkest)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
    }

    private var primaryButton: some View {
        Button(primaryButtonLabel) {
            onPrimaryAction()
        }
        .font(.subheadline.monospaced().weight(.black))
        .frame(maxWidth: .infinity, minHeight: 36)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(primaryButtonAccent)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(GameBoyPalette.darkest, lineWidth: 2)
                )
        )
        .foregroundStyle(GameBoyPalette.lightest)
        .buttonStyle(.plain)
        .disabled(countdownValue != nil)
        .opacity(countdownValue != nil ? 0.55 : 1)
    }
}
