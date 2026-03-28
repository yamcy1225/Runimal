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
        sessionStateLabel == "running" ? "동행체 동기화 중" : "출발 대기"
    }

    private var statusDetail: String {
        sessionStateLabel == "running" ? "워치 단독 러닝도 자동으로 기록을 넘깁니다." : "펫을 데리고 바로 달리기를 시작할 수 있습니다."
    }

    var body: some View {
        GameSurface(title: "메인 동행체", accent: accent, compact: true) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.18))
                        .frame(width: 66, height: 66)
                        .blur(radius: 8)

                    Circle()
                        .stroke(accent.opacity(0.34), lineWidth: 2)
                        .frame(width: 56, height: 56)

                    if sessionStateLabel == "running" {
                        PixelPetView(pet: pet, pixelSize: 5)
                    } else {
                        TraceEggView(accent: accent, shell: sessionShell, pixelSize: 5, resonance: heartResonance)
                    }
                }

                VStack(spacing: 2) {
                    Text(pet.displayName)
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(statusTitle)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(accent.opacity(0.92))
                }

                RunimalProgressBar(progress: progress, accent: accent, height: 6)

                HStack(spacing: 6) {
                    WatchStatusChip(label: sessionStateLabel == "running" ? "기록 중" : "대기 중", accent: accent)
                    WatchStatusChip(label: syncStatusLabel, accent: .white.opacity(0.14))
                }
            }
        }
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
            .padding(.horizontal, 8)
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
