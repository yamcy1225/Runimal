import RunimalCore
import SwiftUI

struct HatchBurstView: View {
    let accent: Color
    let pet: GeneratedPet?
    var scale: CGFloat
    @State private var ringRotation = -14.0
    @State private var flare = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(accent.opacity(flare ? 0.66 : 0.38), lineWidth: 2)
                .frame(width: 86 * scale, height: 86 * scale)

            Circle()
                .stroke(accent.opacity(0.24), style: StrokeStyle(lineWidth: 5, dash: [4, 6]))
                .frame(width: 112 * scale, height: 112 * scale)
                .rotationEffect(.degrees(ringRotation))

            Circle()
                .fill(accent.opacity(flare ? 0.24 : 0.12))
                .frame(width: 64 * scale, height: 64 * scale)
                .blur(radius: 10)

            if let pet {
                ForEach(signatureOffsets(for: pet), id: \.x) { point in
                    Circle()
                        .fill(accent.opacity(flare ? 1 : 0.82))
                        .frame(width: flare ? 7 : 5, height: flare ? 7 : 5)
                        .offset(x: point.x * scale, y: point.y * scale)
                }
            }
        }
        .onAppear {
            ringRotation = 14
            flare = true
        }
        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: ringRotation)
        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: flare)
    }

    private func signatureOffsets(for pet: GeneratedPet) -> [CGPoint] {
        if let loadedPoints = RunimalFeedbackProfileLoader.burstPoints(for: pet) {
            return loadedPoints
        }

        if let rareVariant = pet.rareVariant {
            switch rareVariant {
            case .tempoSurge:
                return [CGPoint(x: -44, y: -12), CGPoint(x: 38, y: -24), CGPoint(x: 18, y: 36)]
            case .zenBloom:
                return [CGPoint(x: -36, y: -30), CGPoint(x: 0, y: -42), CGPoint(x: 34, y: -18)]
            case .summitHeart:
                return [CGPoint(x: -40, y: 20), CGPoint(x: 0, y: -38), CGPoint(x: 40, y: 22)]
            case .eclipseMark:
                return [CGPoint(x: -30, y: -34), CGPoint(x: 26, y: -34), CGPoint(x: 0, y: 38)]
            case .loopSigil:
                return [CGPoint(x: -42, y: 0), CGPoint(x: 0, y: -42), CGPoint(x: 42, y: 0)]
            }
        }

        switch pet.species {
        case .windrunner: return [CGPoint(x: -34, y: -20), CGPoint(x: 34, y: -20)]
        case .stoneback: return [CGPoint(x: -30, y: 24), CGPoint(x: 30, y: 24)]
        case .sparkfang: return [CGPoint(x: -40, y: -8), CGPoint(x: 34, y: 18)]
        case .mosshop: return [CGPoint(x: -28, y: -30), CGPoint(x: 28, y: -30)]
        case .shadebit: return [CGPoint(x: -24, y: -34), CGPoint(x: 24, y: -34)]
        case .seedle: return [CGPoint(x: 0, y: -38), CGPoint(x: 0, y: 34)]
        }
    }
}
