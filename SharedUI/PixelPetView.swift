import RunimalCore
import SwiftUI

struct PixelPetView: View {
    let pet: GeneratedPet
    var pixelSize: CGFloat = 10
    var seasonalLayers: [SeasonalVisualLayer] = []
    @State private var hovering = false
    @State private var tiltDegrees = 0.0

    var body: some View {
        let bodyPixels = sprite(for: pet.species)
        let eyePixels = [(3, 3), (6, 3)]
        let accentPixels = accent(for: pet.rareVariant)

        ZStack(alignment: .topLeading) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [pet.accentColor.opacity(0.32), .clear],
                        center: .center,
                        startRadius: pixelSize,
                        endRadius: pixelSize * 5
                    )
                )
                .frame(width: 9 * pixelSize, height: 9 * pixelSize)
                .offset(x: pixelSize * 0.5, y: pixelSize * 0.8)

            pixelLayer(bodyPixels, color: pet.accentColor)
            pixelLayer(eyePixels, color: .white)
            pixelLayer([(3, 3), (6, 3)], color: .black, inset: pixelSize * 0.22)
            pixelLayer(accentPixels, color: .white.opacity(0.95))
            pixelLayer(seasonShellPixels, color: pet.accentColor.opacity(0.32))
            pixelLayer(raidStripePixels, color: .yellow.opacity(0.92), inset: pixelSize * 0.18)
            pixelLayer(crestPixels, color: .white.opacity(0.92), inset: pixelSize * 0.12)
        }
        .frame(width: 10 * pixelSize, height: 10 * pixelSize)
        .offset(y: hovering ? -pixelSize * 0.24 : 0)
        .scaleEffect(hovering ? 1.04 : 0.98)
        .rotationEffect(.degrees(hovering ? tiltDegrees : -tiltDegrees * 0.45))
        .shadow(color: pet.accentColor.opacity(0.38), radius: 14, y: 10)
        .overlay(alignment: .bottom) {
            RoundedRectangle(cornerRadius: pixelSize)
                .fill(.black.opacity(0.25))
                .frame(width: 6 * pixelSize, height: pixelSize * 0.7)
                .blur(radius: 6)
                .offset(y: pixelSize * 1.8)
        }
        .overlay {
            if pet.rareVariant != nil {
                Circle()
                    .stroke(pet.accentColor.opacity(0.46), lineWidth: max(1, pixelSize * 0.18))
                    .frame(width: 9.6 * pixelSize, height: 9.6 * pixelSize)
                    .blur(radius: 2)
            }
        }
        .onAppear {
            hovering = true
            tiltDegrees = restTilt(for: pet)
        }
        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: hovering)
        .animation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true), value: tiltDegrees)
    }

    private func pixelLayer(_ pixels: [(Int, Int)], color: Color, inset: CGFloat = 0) -> some View {
        ForEach(Array(pixels.enumerated()), id: \.offset) { _, point in
            Rectangle()
                .fill(color)
                .frame(width: pixelSize - inset, height: pixelSize - inset)
                .position(
                    x: CGFloat(point.0) * pixelSize + pixelSize / 2,
                    y: CGFloat(point.1) * pixelSize + pixelSize / 2
                )
        }
    }

    private func sprite(for species: PetSpecies) -> [(Int, Int)] {
        switch species {
        case .windrunner:
            return [(4, 0), (5, 0), (3, 1), (4, 1), (5, 1), (6, 1), (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2), (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3), (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4), (3, 5), (4, 5), (5, 5), (6, 5), (4, 6), (5, 6), (3, 7), (6, 7)]
        case .stoneback:
            return [(3, 1), (4, 1), (5, 1), (6, 1), (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2), (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3), (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4), (3, 5), (4, 5), (5, 5), (6, 5), (4, 6), (5, 6), (2, 6), (7, 6)]
        case .sparkfang:
            return [(4, 0), (5, 0), (3, 1), (4, 1), (5, 1), (6, 1), (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2), (3, 3), (4, 3), (5, 3), (6, 3), (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4), (3, 5), (4, 5), (5, 5), (6, 5), (4, 6), (5, 6), (2, 6), (7, 6)]
        case .mosshop:
            return [(3, 1), (4, 1), (5, 1), (6, 1), (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2), (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3), (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4), (3, 5), (4, 5), (5, 5), (6, 5), (4, 6), (5, 6), (3, 0), (6, 0)]
        case .shadebit:
            return [(4, 0), (5, 0), (3, 1), (4, 1), (5, 1), (6, 1), (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2), (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3), (3, 4), (4, 4), (5, 4), (6, 4), (4, 5), (5, 5), (3, 6), (6, 6), (2, 7), (7, 7)]
        case .seedle:
            return [(4, 1), (5, 1), (3, 2), (4, 2), (5, 2), (6, 2), (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3), (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4), (3, 5), (4, 5), (5, 5), (6, 5), (4, 6), (5, 6), (4, 0), (5, 0)]
        }
    }

    private func accent(for variant: RareVariant?) -> [(Int, Int)] {
        switch variant {
        case .tempoSurge:
            return [(8, 1), (7, 2), (8, 3), (7, 4)]
        case .zenBloom:
            return [(2, 0), (1, 1), (2, 1), (7, 0), (8, 1), (7, 1)]
        case .summitHeart:
            return [(4, 0), (5, 0), (4, 1), (5, 1)]
        case .eclipseMark:
            return [(1, 2), (1, 3), (1, 4), (2, 2), (2, 4)]
        case .loopSigil:
            return [(1, 5), (2, 6), (7, 6), (8, 5), (2, 7), (7, 7)]
        case nil:
            return []
        }
    }

    private func restTilt(for pet: GeneratedPet) -> Double {
        if let profile = RunimalFeedbackProfileLoader.speciesProfile(for: pet.species) {
            return profile.tilt
        }

        switch pet.species {
        case .windrunner: return -2
        case .stoneback: return 1.2
        case .sparkfang: return -3
        case .mosshop: return 1.5
        case .shadebit: return -1.5
        case .seedle: return 0.8
        }
    }

    private var seasonShellPixels: [(Int, Int)] {
        guard seasonalLayers.contains(.seasonShell) else { return [] }
        return [(1, 2), (1, 3), (1, 4), (8, 2), (8, 3), (8, 4), (3, 0), (6, 0)]
    }

    private var raidStripePixels: [(Int, Int)] {
        guard seasonalLayers.contains(.raidStripe) else { return [] }
        return [(2, 5), (3, 6), (4, 7), (6, 5), (5, 6)]
    }

    private var crestPixels: [(Int, Int)] {
        if seasonalLayers.contains(.seasonShell) {
            return [(4, 0), (5, 0)]
        }

        guard pet.rareVariant != nil else { return [] }
        return [(4, 1), (5, 1)]
    }
}
