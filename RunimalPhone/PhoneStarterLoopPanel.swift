import RunimalCore
import SwiftUI

struct PhoneStarterLoopPanel: View {
    let steps: [StarterLoopStep]

    var body: some View {
        GameSurface(title: "Starter Decode Path") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(steps) { step in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(step.completed ? .green.opacity(0.8) : .white.opacity(0.16))
                            .frame(width: 10, height: 10)
                            .padding(.top, 5)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(step.title)
                                    .foregroundStyle(.white)
                                Spacer()
                                TraitChip(label: step.completed ? "LOCKED IN" : "NEXT", accent: step.completed ? .green : .orange)
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
}
