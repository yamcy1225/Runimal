import RunimalCore
import SwiftUI

struct GameSurface<Content: View>: View {
    let title: String?
    @ViewBuilder var content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
            }

            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.black.opacity(0.88), .black.opacity(0.68)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
}

struct TraitChip: View {
    let label: String
    let accent: Color

    var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(accent.opacity(0.22), in: Capsule())
            .foregroundStyle(.white)
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
