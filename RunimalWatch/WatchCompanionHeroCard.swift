import RunimalCore
import SwiftUI

struct WatchCompanionHeroCard: View {
    let companion: WatchMainCompanionContext
    let accent: Color
    let sessionStateLabel: String
    let heartResonance: Double
    let gpsAccuracyMeters: Double?
    let lastGPSUpdateAt: Date?
    let locationStatusLabel: String
    let countdownValue: Int?
    let onPrimaryAction: () -> Void

    private var statusTitle: String {
        if sessionStateLabel == "running" {
            return companion.selection.kind == .egg ? "부화 추적 중" : "기록 중"
        }
        return companion.selection.kind == .egg ? "알 동기화 대기" : "출발 대기"
    }

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
            return Color.red.opacity(0.92)
        }
        guard let gpsAccuracyMeters else { return Color.orange.opacity(0.88) }
        if isGPSStale {
            return Color.yellow.opacity(0.9)
        }
        switch gpsAccuracyMeters {
        case ..<12:
            return Color.green.opacity(0.9)
        case ..<24:
            return Color.yellow.opacity(0.9)
        default:
            return Color.red.opacity(0.92)
        }
    }

    private var isGPSStale: Bool {
        guard let lastGPSUpdateAt else { return true }
        return Date().timeIntervalSince(lastGPSUpdateAt) > 8
    }

    var body: some View {
        GameSurface(
            title: "동행",
            accent: accent,
            eyebrow: "GPS",
            headerGauge: .init(progress: gpsSignalStrength, fill: gpsSignalColor),
            compact: true
        ) {
            VStack(spacing: 8) {
                WatchCompanionActionField(
                    companion: companion,
                    accent: accent,
                    heartResonance: heartResonance,
                    isRunning: sessionStateLabel == "running"
                )

                VStack(spacing: 2) {
                    Text(companion.displayName)
                        .font(.headline.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.darkest)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text(statusTitle)
                        .font(.caption.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.mediumDark)
                }

                Button(primaryButtonLabel) {
                    onPrimaryAction()
                }
                .font(.subheadline.monospaced().weight(.black))
                .frame(maxWidth: .infinity, minHeight: 38)
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
    }

}
