import RunimalCore
import SwiftUI

struct WatchRunStatsPanel: View {
    let snapshot: LiveRunSnapshot
    let accent: Color


    var body: some View {
        GameSurface(
            title: "러닝 신호",
            accent: accent,
            eyebrow: nil,
            compact: true
        ) {
            VStack(spacing: 4) {
                ForEach(cards) { card in
                    statCard(title: card.title, value: card.value, accent: card.accent)
                }
            }
        }
    }

    private var cards: [WatchStatCardModel] {
        [
            .init(title: "거리", value: distanceText, accent: GameBoyPalette.mediumLight),
            .init(title: "시간", value: elapsedText, accent: GameBoyPalette.lightest),
            .init(title: "페이스", value: paceText, accent: GameBoyPalette.lightest),
            .init(title: "심박", value: heartRateText, accent: GameBoyPalette.mediumLight),
            .init(title: "평균 케이던스", value: cadenceText, accent: GameBoyPalette.mediumLight),
        ]
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
        return "\(Int(bpm)) bpm"
    }

    private var cadenceText: String {
        guard let cadence = snapshot.cadence else { return "--" }
        return "\(cadence) spm"
    }

    private func statCard(title: String, value: String, accent: Color) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption2.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.mediumDark)
                .frame(width: 76, alignment: .leading)
            Text(value)
                .font(.footnote.monospacedDigit().weight(.black))
                .foregroundStyle(GameBoyPalette.darkest)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(accent)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(GameBoyPalette.darkest, lineWidth: 1)
                )
        )
    }
}

private struct WatchStatCardModel: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let accent: Color
}
