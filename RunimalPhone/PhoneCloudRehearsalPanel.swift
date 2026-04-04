import RunimalCore
import SwiftUI

struct PhoneCloudRehearsalPanel: View {
    let steps: [CloudRehearsalStep]

    var body: some View {
        GameSurface(title: "기기 동기화 점검") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(steps) { step in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(step.title)
                                .foregroundStyle(.white)
                            Spacer()
                            TraitChip(label: step.ready ? "준비 완료" : "진행 중", accent: step.ready ? .green.opacity(0.72) : .orange.opacity(0.72))
                        }
                        Text(step.detail)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }
            }
        }
    }
}
