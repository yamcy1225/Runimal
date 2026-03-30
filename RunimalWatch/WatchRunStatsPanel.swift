import RunimalCore
import SwiftUI

struct WatchRunStatsPanel: View {
    let snapshot: LiveRunSnapshot
    let gpsAccuracyMeters: Double?
    let lastGPSUpdateAt: Date?
    let locationStatusLabel: String
    let accent: Color

    var body: some View {
        GameSurface(
            title: nil,
            accent: accent,
            compact: true
        ) {
            VStack(spacing: 5) {
                VStack(spacing: 4) {
                    distanceStatCard
                    HStack(spacing: 5) {
                        primaryStatCard(title: "페이스", value: paceText, accent: GameBoyPalette.lightest)
                        primaryStatCard(title: "시간", value: elapsedText, accent: GameBoyPalette.lightest)
                    }
                }

                HStack(spacing: 5) {
                    secondaryStatCard(title: "심박", value: heartRateText)
                    secondaryStatCard(title: "케이던스", value: cadenceText)
                }
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
        return String(format: "%d:%02d/km", minutes, remainder)
    }

    private var heartRateText: String {
        guard let bpm = snapshot.currentHeartRate else { return "--" }
        return "\(Int(bpm))"
    }

    private var cadenceText: String {
        guard let cadence = snapshot.cadence else { return "--" }
        return "\(cadence)"
    }

    private var distanceStatCard: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("거리")
                .font(.caption2.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.mediumDark)
            Text(distanceText)
                .font(.title2.monospacedDigit().weight(.black))
                .foregroundStyle(GameBoyPalette.darkest)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(GameBoyPalette.mediumLight)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(GameBoyPalette.darkest, lineWidth: 1)
                )
        )
    }

    private func primaryStatCard(title: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.mediumDark)
            Text(value)
                .font(.headline.monospacedDigit().weight(.black))
                .foregroundStyle(GameBoyPalette.darkest)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(accent)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(GameBoyPalette.darkest, lineWidth: 1)
                )
        )
    }

    private func secondaryStatCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.mediumDark)
            Text(value)
                .font(.caption2.monospacedDigit().weight(.black))
                .foregroundStyle(GameBoyPalette.darkest)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(GameBoyPalette.mediumLight.opacity(0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(GameBoyPalette.darkest, lineWidth: 1)
                )
        )
    }
}
