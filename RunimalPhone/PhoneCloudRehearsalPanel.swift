import RunimalCore
import SwiftUI

struct PhoneCloudRehearsalPanel: View {
    let steps: [CloudRehearsalStep]

    var body: some View {
        GameSurface(title: "Device Sync Rehearsal") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(steps) { step in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(step.title)
                                .foregroundStyle(.white)
                            Spacer()
                            TraitChip(label: step.ready ? "READY" : "RUN", accent: step.ready ? .green.opacity(0.72) : .orange.opacity(0.72))
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
