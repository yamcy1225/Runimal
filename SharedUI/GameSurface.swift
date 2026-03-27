import RunimalCore
import SwiftUI

struct GameSurface<Content: View>: View {
    let title: String?
    let accent: Color?
    let eyebrow: String?
    @ViewBuilder var content: Content

    init(title: String? = nil, accent: Color? = nil, eyebrow: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.accent = accent
        self.eyebrow = eyebrow
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if title != nil || eyebrow != nil {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        if let eyebrow {
                            Text(eyebrow.uppercased())
                                .font(.caption2.weight(.black))
                                .tracking(1.4)
                                .foregroundStyle((accent ?? .white).opacity(0.86))
                        }

                        if let title {
                            Text(title)
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white.opacity(0.94))
                        }
                    }

                    Spacer()

                    if let accent {
                        Capsule()
                            .fill(accent.opacity(0.22))
                            .frame(width: 46, height: 12)
                            .overlay(
                                Capsule()
                                    .fill(accent)
                                    .frame(width: 18, height: 4)
                            )
                    }
                }
            }

            content
        }
        .padding(18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.08, green: 0.09, blue: 0.12),
                                Color(red: 0.03, green: 0.04, blue: 0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [(accent ?? .white).opacity(0.18), .clear],
                            center: .topLeading,
                            startRadius: 12,
                            endRadius: 260
                        )
                    )

                VStack(spacing: 10) {
                    Capsule()
                        .fill(.white.opacity(0.10))
                        .frame(height: 1)
                    Spacer()
                    HStack(spacing: 10) {
                        ForEach(0..<7, id: \.self) { _ in
                            Capsule()
                                .fill(.white.opacity(0.03))
                                .frame(height: 2)
                        }
                    }
                }
                .padding(16)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
        .overlay(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder((accent ?? .white).opacity(0.16), lineWidth: 1)
                .blur(radius: 10)
                .padding(-1)
        }
    }
}

struct TraitChip: View {
    let label: String
    let accent: Color

    var body: some View {
        Text(label.uppercased())
            .font(.caption2.weight(.black))
            .tracking(0.8)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(accent.opacity(0.18))
                    .overlay(
                        Capsule()
                            .stroke(accent.opacity(0.34), lineWidth: 1)
                    )
            )
            .foregroundStyle(.white.opacity(0.96))
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
        case .light: return Color(red: 0.96, green: 0.81, blue: 0.34)
        case .flame: return Color(red: 0.94, green: 0.39, blue: 0.24)
        case .leaf: return Color(red: 0.36, green: 0.73, blue: 0.42)
        case .lunar: return Color(red: 0.41, green: 0.58, blue: 0.93)
        case .earth: return Color(red: 0.63, green: 0.49, blue: 0.32)
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
