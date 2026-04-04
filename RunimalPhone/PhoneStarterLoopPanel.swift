import RunimalCore
import SwiftUI

struct PhoneStarterLoopPanel: View {
    let steps: [StarterLoopStep]
    let accent: Color

    var body: some View {
        GameSurface(title: "첫 3번의 러닝 약속", accent: accent, eyebrow: "RUN TO LIFE") {
            VStack(alignment: .leading, spacing: 12) {
                Text("첫 러닝은 알, 둘째 러닝은 부화, 셋째 러닝은 첫 단계 상승으로 이어져야 합니다.")
                    .font(.caption.monospaced())
                    .foregroundStyle(GameBoyPalette.mediumDark)

                ForEach(steps) { step in
                    HStack(alignment: .top, spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(step.completed ? accent.opacity(0.9) : GameBoyPalette.mediumLight.opacity(0.7))
                                .frame(width: 24, height: 24)
                            Image(systemName: step.completed ? "checkmark" : "figure.run")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(step.completed ? GameBoyPalette.lightest : GameBoyPalette.darkest)
                        }
                        .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(step.title)
                                    .font(.subheadline.monospaced().weight(.black))
                                    .foregroundStyle(GameBoyPalette.darkest)
                                Spacer()
                                TraitChip(label: step.completed ? "완료" : "다음", accent: step.completed ? accent : .orange)
                            }
                            Text(step.detail)
                                .font(.caption.monospaced())
                                .foregroundStyle(GameBoyPalette.mediumDark)
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(GameBoyPalette.lightest.opacity(step.completed ? 0.92 : 0.72))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(step.completed ? accent.opacity(0.45) : GameBoyPalette.mediumDark.opacity(0.22), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
}
