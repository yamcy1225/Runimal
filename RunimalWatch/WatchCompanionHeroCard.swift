import RunimalCore
import SwiftUI

struct WatchCompanionHeroCard: View {
    let pet: GeneratedPet
    let sessionShell: EggShellType
    let accent: Color
    let sessionStateLabel: String
    let syncStatusLabel: String
    let heartResonance: Double
    let progress: Double

    private var statusTitle: String {
        sessionStateLabel == "running" ? "기록 중" : "출발 대기"
    }

    var body: some View {
        GameSurface(title: "동행", accent: accent, compact: true) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(GameBoyPalette.mediumLight.opacity(0.2))
                        .frame(width: 62, height: 62)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(GameBoyPalette.darkest, lineWidth: 2)
                        )

                    if sessionStateLabel == "running" {
                        PixelPetView(pet: pet, pixelSize: 4)
                    } else {
                        TraceEggView(accent: accent, shell: sessionShell, pixelSize: 4, resonance: heartResonance)
                    }
                }

                VStack(spacing: 3) {
                    Text(pet.displayName)
                        .font(.footnote.weight(.black))
                        .foregroundStyle(GameBoyPalette.darkest)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text(statusTitle)
                        .font(.caption2.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.mediumDark)
                }

                RunimalProgressBar(progress: progress, accent: accent, height: 6)

                WatchStatusChip(label: syncChipLabel, accent: sessionStateLabel == "running" ? GameBoyPalette.mediumDark : GameBoyPalette.mediumLight)
            }
        }
    }

    private var syncChipLabel: String {
        sessionStateLabel == "running" ? "자동 동기화 \(syncStatusLabel)" : syncStatusLabel
    }
}

private struct WatchStatusChip: View {
    let label: String
    let accent: Color

    var body: some View {
        Text(label)
            .font(.caption2.monospaced().weight(.black))
            .foregroundStyle(GameBoyPalette.darkest)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(accent)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(GameBoyPalette.darkest, lineWidth: 1)
                    )
            )
    }
}
