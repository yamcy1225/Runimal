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
    let mutationReaction: MutationRuntimeReactionSnapshot?
    let countdownValue: Int?
    let interactionSummaryLabel: String?
    let pendingHomeBonusLabel: String?
    let onPrimaryAction: () -> Void
    let onRefreshCompanion: () -> Void
    let onCompanionInteraction: (WatchCompanionInteractionStyle) -> WatchInteractionAwardFeedback?

    private var primaryButtonLabel: String {
        sessionStateLabel == "running" ? "러닝 종료" : "러닝 시작"
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
        GameSurface(compact: true, showsFrameChrome: false) {
            VStack(spacing: 4) {
                statusHeader
                companionField
                companionSummary
                primaryButton
            }
        }
        .task {
            onRefreshCompanion()
        }
    }

    private var statusHeader: some View {
        HStack(spacing: 6) {
            statusPill(
                label: sessionStateLabel == "running" ? "LIVE" : "HOME",
                accent: sessionStateLabel == "running" ? accent : GameBoyPalette.mediumDark
            )

            HStack(spacing: 5) {
                Circle()
                    .fill(gpsSignalColor)
                    .frame(width: 6, height: 6)
                Text(gpsHeaderLabel)
                    .font(.caption2.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.mediumDark)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(GameBoyPalette.lightest.opacity(0.72))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(GameBoyPalette.darkest.opacity(0.85), lineWidth: 1)
                    )
            )

            Spacer(minLength: 0)
        }
    }

    private var companionField: some View {
        ZStack {
            companionFieldAtmosphere

            if let companion {
                WatchCompanionActionField(
                    companion: companion,
                    accent: accent,
                    heartResonance: heartResonance,
                    isRunning: sessionStateLabel == "running",
                    presentation: .hero,
                    reaction: mutationReaction,
                    onInteraction: onCompanionInteraction
                )
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles.rectangle.stack")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(GameBoyPalette.mediumDark)
                    Text("동행 연결 중")
                        .font(.footnote.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.darkest)
                    Text("잠깐만, 첫 친구를 불러오는 중")
                        .font(.caption2.monospaced())
                        .foregroundStyle(GameBoyPalette.mediumDark)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(height: 76)
    }

    private var companionFieldAtmosphere: some View {
        ZStack {
            Ellipse()
                .fill(accent.opacity(0.12))
                .frame(width: 150, height: 62)
                .blur(radius: 12)

            Capsule(style: .continuous)
                .fill(accent.opacity(0.08))
                .frame(width: 116, height: 20)
                .blur(radius: 7)
                .offset(y: 24)
        }
    }

    private var companionSummary: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(companion?.displayName ?? "동행 대기")
                        .font(.footnote.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.darkest)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text(summaryTitle)
                        .font(.caption2.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.mediumDark)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Spacer(minLength: 4)

                HStack(spacing: 4) {
                    if let stageBadgeLabel, !(sessionStateLabel != "running" && pendingHomeBonusLabel != nil) {
                        stageBadge(label: stageBadgeLabel)
                    }
                    if let pendingHomeBonusLabel, sessionStateLabel != "running" {
                        stageBadge(label: pendingHomeBonusLabel, accentOverride: .green)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(summaryMeterTitle)
                        .font(.caption2.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.mediumDark)
                    Spacer(minLength: 6)
                    HStack(spacing: 4) {
                        if let interactionSummaryLabel, sessionStateLabel == "running" {
                            Text(interactionSummaryLabel)
                                .font(.caption2.monospaced().weight(.black))
                                .foregroundStyle(accent)
                        }
                        Text(summaryMeterLabel)
                            .font(.caption2.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.darkest)
                    }
                }

                RunimalProgressBar(
                    progress: sessionStateLabel == "running" ? heartResonance : gpsSignalStrength,
                    accent: accent,
                    height: 7
                )
                .frame(height: 7)
            }

            if let companionFooterLine {
                Text(companionFooterLine)
                    .font(.caption2.monospaced())
                    .foregroundStyle(GameBoyPalette.mediumDark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }

        }
    }

    private var summaryTitle: String {
        if companion?.selection.kind == .egg {
            return sessionStateLabel == "running" ? "부화 파동" : "첫 생명 준비"
        }
        return sessionStateLabel == "running" ? "탭 반응" : "함께 달릴 준비"
    }

    private var stageBadgeLabel: String? {
        guard let level = companion?.companionLevel else { return nil }
        return "Lv.\(level)"
    }

    private var companionFooterLine: String? {
        guard let companion else {
            return "첫 친구를 불러오는 중"
        }

        if companion.selection.kind == .egg {
            return sessionStateLabel == "running" ? "탭하면 알이 흔들려요" : nil
        }

        if sessionStateLabel == "running" {
            return nil
        }

        return nil
    }

    private var summaryMeterTitle: String {
        sessionStateLabel == "running" ? "교감 강도" : "출발 신호"
    }

    private var summaryMeterLabel: String {
        if sessionStateLabel == "running" {
            return "\(Int(heartResonance * 100))%"
        }
        return launchStatusLabel
    }

    private var launchStatusLabel: String {
        if locationStatusLabel.contains("denied") || locationStatusLabel.contains("restricted") {
            return "GPS OFF"
        }
        if isGPSStale {
            return "위치 잡는 중"
        }
        switch gpsSignalStrength {
        case 0.85...:
            return "출발 가능"
        case 0.45...:
            return "보정 중"
        default:
            return "신호 약함"
        }
    }

    private var gpsHeaderLabel: String {
        if locationStatusLabel.contains("denied") || locationStatusLabel.contains("restricted") {
            return "OFF"
        }
        if isGPSStale {
            return "WAIT"
        }
        switch gpsSignalStrength {
        case 0.85...:
            return "OK"
        case 0.45...:
            return "FAIR"
        default:
            return "SOFT"
        }
    }

    private var primaryButton: some View {
        Button(action: onPrimaryAction) {
            HStack(spacing: 6) {
                Image(systemName: sessionStateLabel == "running" ? "stop.fill" : "figure.run")
                    .font(.system(size: 11, weight: .black))
                Text(primaryButtonLabel)
                    .font(.caption.monospaced().weight(.black))
            }
            .frame(maxWidth: .infinity, minHeight: 26)
        }
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

    private func stageBadge(label: String, accentOverride: Color? = nil) -> some View {
        Text(label)
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
                            .stroke((accentOverride ?? accent).opacity(0.88), lineWidth: 1)
                    )
            )
    }

    private func statusPill(label: String, accent: Color) -> some View {
        Text(label)
            .font(.caption2.monospaced().weight(.black))
            .foregroundStyle(GameBoyPalette.lightest)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(accent)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(GameBoyPalette.darkest.opacity(0.9), lineWidth: 1)
                    )
            )
    }
}
