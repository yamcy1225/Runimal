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
                    Circle()
                        .fill(accent.opacity(0.18))
                        .frame(width: 62, height: 62)
                        .blur(radius: 8)

                    Circle()
                        .stroke(accent.opacity(0.34), lineWidth: 2)
                        .frame(width: 52, height: 52)

                    if sessionStateLabel == "running" {
                        PixelPetView(pet: pet, pixelSize: 4)
                    } else {
                        TraceEggView(accent: accent, shell: sessionShell, pixelSize: 4, resonance: heartResonance)
                    }
                }

                VStack(spacing: 3) {
                    Text(pet.displayName)
                        .font(.footnote.weight(.black))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text(statusTitle)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(accent.opacity(0.92))
                }

                RunimalProgressBar(progress: progress, accent: accent, height: 6)

                WatchStatusChip(label: syncChipLabel, accent: sessionStateLabel == "running" ? accent : .white.opacity(0.14))
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
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white.opacity(0.82))
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(accent)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    )
            )
    }
}
