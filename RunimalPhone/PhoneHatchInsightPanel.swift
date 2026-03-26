import RunimalCore
import SwiftUI

struct PhoneHatchInsightPanel: View {
    let insights: [HatchInsight]
    let target: EvolutionTarget
    let accent: Color

    var body: some View {
        GameSurface(title: "Hatch Analysis") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(insights) { insight in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(insight.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Spacer()
                            TraitChip(label: insight.emphasis, accent: accent)
                        }

                        Text(insight.detail)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }

                Divider()
                    .overlay(.white.opacity(0.12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(target.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(target.detail)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                    Text(target.status.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(accent)
                }
            }
        }
    }
}
