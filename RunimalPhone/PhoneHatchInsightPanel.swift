import RunimalCore
import SwiftUI

struct PhoneHatchInsightPanel: View {
    let insights: [HatchInsight]
    let target: EvolutionTarget
    let accent: Color

    var body: some View {
        GameSurface(title: "기록 해석", accent: accent, eyebrow: "최근 러닝") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(insights) { insight in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(insight.title)
                                .font(.subheadline.monospaced().weight(.black))
                                .foregroundStyle(GameBoyPalette.darkest)
                            Spacer()
                            TraitChip(label: insight.emphasis, accent: accent)
                        }

                        Text(insight.detail)
                            .font(.caption.monospaced())
                            .foregroundStyle(GameBoyPalette.mediumDark)
                            .lineSpacing(2)
                    }
                }

                Divider()
                    .overlay(GameBoyPalette.darkest.opacity(0.12))

                VStack(alignment: .leading, spacing: 8) {
                    Text(target.title)
                        .font(.subheadline.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.darkest)
                    Text(target.detail)
                        .font(.caption.monospaced())
                        .foregroundStyle(GameBoyPalette.mediumDark)
                        .lineSpacing(2)

                    guidanceRow(title: target.focusTitle, detail: target.focusDetail)
                    guidanceRow(title: target.actionTitle, detail: target.actionDetail)
                    guidanceRow(title: target.checkpointTitle, detail: target.checkpointDetail)

                    if target.badges.isEmpty == false {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(target.badges, id: \.self) { badge in
                                    TraitChip(label: badge, accent: accent.opacity(0.18))
                                }
                            }
                            .padding(.horizontal, 1)
                        }
                    }
                }
            }
        }
    }

    private func guidanceRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.monospaced().weight(.black))
                .foregroundStyle(accent.opacity(0.9))
            Text(detail)
                .font(.caption.monospaced())
                .foregroundStyle(GameBoyPalette.mediumDark)
                .lineSpacing(2)
        }
    }
}
