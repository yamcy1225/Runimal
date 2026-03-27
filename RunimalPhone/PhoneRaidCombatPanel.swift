import RunimalCore
import SwiftUI

struct PhoneRaidCombatPanel: View {
    let report: RaidCombatReport
    let accent: Color

    var body: some View {
        GameSurface(title: "Raid Combat Read") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(report.title)
                        .foregroundStyle(.white)
                    Spacer()
                    TraitChip(label: report.verdict, accent: accent)
                }

                Text(report.headline)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))

                ForEach(report.steps) { step in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(step.label)
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(Int(step.intensity * 100))%")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.white.opacity(0.68))
                        }
                        RunimalProgressBar(progress: step.intensity, accent: accent, height: 8)
                        Text(step.detail)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.66))
                    }
                }
            }
        }
    }
}
