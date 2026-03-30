import RunimalCore
import SwiftUI

enum GameBoyPalette {
    static let darkest = Color(red: 0.10, green: 0.18, blue: 0.14)
    static let mediumDark = Color(red: 0.29, green: 0.40, blue: 0.30)
    static let mediumLight = Color(red: 0.54, green: 0.66, blue: 0.54)
    static let lightest = Color(red: 0.82, green: 0.89, blue: 0.82)
}

struct GameSurface<Content: View>: View {
    struct HeaderGauge {
        let progress: Double
        let fill: Color
    }

    let title: String?
    let accent: Color?
    let eyebrow: String?
    let headerGauge: HeaderGauge?
    let compact: Bool
    @ViewBuilder var content: Content

    init(
        title: String? = nil,
        accent: Color? = nil,
        eyebrow: String? = nil,
        headerGauge: HeaderGauge? = nil,
        compact: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.accent = accent
        self.eyebrow = eyebrow
        self.headerGauge = headerGauge
        self.compact = compact
        self.content = content()
    }

    var body: some View {
        let cornerRadius: CGFloat = compact ? 14 : 18
        let headerAccent = accent ?? GameBoyPalette.mediumDark

        VStack(alignment: .leading, spacing: compact ? 8 : 12) {
            if title != nil || eyebrow != nil {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: compact ? 2 : 4) {
                        if let eyebrow {
                            Text(eyebrow.uppercased())
                                .font(.caption2.monospaced().weight(.black))
                                .tracking(compact ? 1.0 : 1.4)
                                .foregroundStyle(headerAccent.opacity(0.96))
                        }

                        if let title {
                            Text(title)
                                .font(compact ? .subheadline.monospaced().weight(.black) : .headline.monospaced().weight(.black))
                                .foregroundStyle(GameBoyPalette.darkest)
                        }
                    }

                    Spacer()

                    if let headerGauge {
                        Rectangle()
                            .fill(GameBoyPalette.mediumLight)
                            .frame(width: compact ? 34 : 42, height: compact ? 10 : 12)
                            .overlay(alignment: .leading) {
                                Rectangle()
                                    .fill(headerGauge.fill)
                                    .frame(
                                        width: headerGaugeWidth(
                                            progress: headerGauge.progress,
                                            compact: compact
                                        ),
                                        height: compact ? 4 : 5
                                    )
                                    .padding(.horizontal, 3)
                            }
                            .overlay(
                                Rectangle()
                                    .stroke(GameBoyPalette.darkest, lineWidth: 1)
                            )
                    }
                }
            }

            content
                .foregroundStyle(GameBoyPalette.darkest)
        }
        .padding(compact ? 12 : 18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(GameBoyPalette.lightest)

                RoundedRectangle(cornerRadius: cornerRadius - 4, style: .continuous)
                    .fill(GameBoyPalette.mediumLight.opacity(0.22))
                    .padding(4)

                GameBoyLCDOverlay()
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

                RoundedRectangle(cornerRadius: cornerRadius - 5, style: .continuous)
                    .stroke(headerAccent.opacity(0.34), lineWidth: 1)
                    .padding(6)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(GameBoyPalette.darkest, lineWidth: 2)
        )
        .shadow(color: GameBoyPalette.darkest.opacity(0.12), radius: 0, x: 1, y: 2)
    }

    private func headerGaugeWidth(progress: Double, compact: Bool) -> CGFloat {
        let totalWidth: CGFloat = compact ? 28 : 36
        let clampedProgress = min(max(progress, 0.08), 1)
        return totalWidth * clampedProgress
    }
}

struct TraitChip: View {
    let label: String
    let accent: Color

    var body: some View {
        Text(label.uppercased())
            .font(.caption2.monospaced().weight(.black))
            .tracking(0.8)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(GameBoyPalette.lightest)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(GameBoyPalette.darkest, lineWidth: 1)
                    )
            )
            .foregroundStyle(GameBoyPalette.darkest)
            .overlay(alignment: .topLeading) {
                Rectangle()
                    .fill(accent.opacity(0.72))
                    .frame(width: 8, height: 3)
                    .padding(4)
            }
    }
}

struct GameBoyLCDOverlay: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 6
            for x in stride(from: 0, through: size.width, by: step) {
                let rect = CGRect(x: x, y: 0, width: 1, height: size.height)
                context.fill(Path(rect), with: .color(GameBoyPalette.mediumDark.opacity(0.08)))
            }
            for y in stride(from: 0, through: size.height, by: step) {
                let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                context.fill(Path(rect), with: .color(GameBoyPalette.mediumDark.opacity(0.06)))
            }
        }
        .allowsHitTesting(false)
    }
}

extension GeneratedPet {
    var displayName: String {
        switch species {
        case .windrunner: return "Windrunner"
        case .stoneback: return "Stoneback"
        case .sparkfang: return "Sparkfang"
        case .mosshop: return "Mosshop"
        case .shadebit: return "Shadebit"
        case .seedle: return "Seedle"
        }
    }

    var subtitle: String {
        let variantName: String

        switch rareVariant {
        case .tempoSurge: variantName = "Tempo Surge"
        case .zenBloom: variantName = "Zen Bloom"
        case .summitHeart: variantName = "Summit Heart"
        case .eclipseMark: variantName = "Eclipse Mark"
        case .loopSigil: variantName = "Loop Sigil"
        case nil: variantName = "Standard"
        }

        return "\(element.displayName) • \(variantName)"
    }

    var accentColor: Color {
        switch element {
        case .light: return Color(red: 0.78, green: 0.72, blue: 0.34)
        case .flame: return Color(red: 0.78, green: 0.43, blue: 0.26)
        case .leaf: return Color(red: 0.38, green: 0.62, blue: 0.40)
        case .lunar: return Color(red: 0.44, green: 0.56, blue: 0.76)
        case .earth: return Color(red: 0.56, green: 0.48, blue: 0.34)
        }
    }
}

extension PetElement {
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .flame: return "Flame"
        case .leaf: return "Leaf"
        case .lunar: return "Lunar"
        case .earth: return "Earth"
        }
    }
}
