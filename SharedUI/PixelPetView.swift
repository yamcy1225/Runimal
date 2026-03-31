import RunimalCore
import SwiftUI

struct PixelPetView: View {
    let pet: GeneratedPet
    var pixelSize: CGFloat = 10
    var mutationForm: MutationFormSnapshot? = nil
    var mutationHistory: MutationHistorySnapshot? = nil
    var mutationVisualState: MutationVisualState? = nil
    var seasonalLayers: [SeasonalVisualLayer] = []
    @State private var hovering = false
    @State private var tiltDegrees = 0.0
    @State private var blink = false
    @State private var auraShift = false

    var body: some View {
        let bodyPixels = sprite(for: pet.species)
        let eyePixels = [(3, 3), (6, 3)]
        let accentPixels = accent(for: pet.rareVariant)
        let visualState = mutationVisualState ?? MutationVisualEvolutionEngine.state(
            for: mutationHistory,
            fallbackForm: mutationForm
        )

        ZStack(alignment: .topLeading) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [pet.accentColor.opacity(auraShift ? 0.42 : 0.26), .clear],
                        center: .center,
                        startRadius: pixelSize,
                        endRadius: pixelSize * 5
                    )
                )
                .frame(width: 9 * pixelSize, height: 9 * pixelSize)
                .offset(x: pixelSize * 0.5, y: pixelSize * 0.8)

            Circle()
                .stroke(pet.accentColor.opacity(auraShift ? 0.34 : 0.16), style: StrokeStyle(lineWidth: max(1, pixelSize * 0.16), dash: [3, 5]))
                .frame(width: 8.9 * pixelSize, height: 8.9 * pixelSize)
                .rotationEffect(.degrees(auraShift ? 14 : -12))

            pixelLayer(bodyPixels, color: pet.accentColor)
            pixelLayer(eyePixels, color: blink ? .white.opacity(0.12) : .white)
            pixelLayer([(3, 3), (6, 3)], color: .black, inset: blink ? pixelSize * 0.58 : pixelSize * 0.22)
            pixelLayer(accentPixels, color: .white.opacity(0.95))
            pixelLayer(seasonShellPixels, color: pet.accentColor.opacity(0.32))
            pixelLayer(raidStripePixels, color: .yellow.opacity(0.92), inset: pixelSize * 0.18)
            pixelLayer(crestPixels, color: .white.opacity(0.92), inset: pixelSize * 0.12)
            pixelLayer(sparkPixels, color: .white.opacity(auraShift ? 0.92 : 0.4), inset: pixelSize * 0.46)
            pixelLayer(mutationBodyPixels(stage: visualState.bodyStage), color: pet.accentColor.opacity(0.86), inset: pixelSize * 0.14)
            pixelLayer(mutationEcologyPixels(stage: visualState.ecologyStage), color: .white.opacity(0.82), inset: pixelSize * 0.24)
            pixelLayer(mutationRhythmPixels(stage: visualState.rhythmStage), color: pet.accentColor.opacity(auraShift ? 0.96 : 0.52), inset: pixelSize * 0.42)
            pixelLayer(bodySignaturePixels(stage: visualState.bodyStage), color: .white.opacity(0.92), inset: pixelSize * 0.1)
            pixelLayer(ecologySignaturePixels(stage: visualState.ecologyStage), color: pet.accentColor.opacity(0.68), inset: pixelSize * 0.18)
            pixelLayer(rhythmSignaturePixels(stage: visualState.rhythmStage), color: .white.opacity(auraShift ? 1 : 0.58), inset: pixelSize * 0.34)
        }
        .frame(width: 10 * pixelSize, height: 10 * pixelSize)
        .offset(y: hovering ? -pixelSize * 0.24 : 0)
        .scaleEffect(hovering ? 1.04 : 0.98)
        .rotationEffect(.degrees(hovering ? tiltDegrees : -tiltDegrees * 0.45))
        .shadow(color: pet.accentColor.opacity(0.22), radius: 8, y: 4)
        .overlay(alignment: .bottom) {
            RoundedRectangle(cornerRadius: pixelSize)
                .fill(.black.opacity(0.25))
                .frame(width: 6 * pixelSize, height: pixelSize * 0.7)
                .blur(radius: 3)
                .offset(y: pixelSize * 1.25)
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
            auraShift = true
            scheduleBlink()
        }
        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: hovering)
        .animation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true), value: tiltDegrees)
        .animation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true), value: auraShift)
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
        if mutationForm != nil {
            return [(4, 0), (5, 0), (4, 1), (5, 1)]
        }

        if seasonalLayers.contains(.seasonShell) {
            return [(4, 0), (5, 0)]
        }

        guard pet.rareVariant != nil else { return [] }
        return [(4, 1), (5, 1)]
    }

    private var sparkPixels: [(Int, Int)] {
        [(1, 2), (8, 2), (2, 7), (7, 7)]
    }

    private func mutationBodyPixels(stage: Int) -> [(Int, Int)] {
        guard let mutationForm, stage > 0 else { return [] }

        let phaseOne: [(Int, Int)]
        let phaseTwo: [(Int, Int)]
        let phaseThree: [(Int, Int)]

        switch mutationForm.bodyBranchID {
        case let branch where branch.contains("swift"), let branch where branch.contains("burst"):
            phaseOne = [(2, 1), (7, 1)]
            phaseTwo = [(1, 2), (8, 2)]
            phaseThree = [(3, 0), (6, 0)]
        case let branch where branch.contains("guard"), let branch where branch.contains("bulwark"), let branch where branch.contains("root"):
            phaseOne = [(2, 6), (7, 6)]
            phaseTwo = [(3, 7), (6, 7)]
            phaseThree = [(2, 7), (7, 7)]
        case let branch where branch.contains("core"), let branch where branch.contains("crown"), let branch where branch.contains("bloom"):
            phaseOne = [(4, 0), (5, 0)]
            phaseTwo = [(3, 1), (6, 1)]
            phaseThree = [(4, 1), (5, 1)]
        default:
            phaseOne = [(2, 1), (7, 1)]
            phaseTwo = [(1, 2), (8, 2)]
            phaseThree = [(3, 0), (6, 0)]
        }

        return stagedPixels(stage: stage, phaseOne: phaseOne, phaseTwo: phaseTwo, phaseThree: phaseThree)
    }

    private func mutationEcologyPixels(stage: Int) -> [(Int, Int)] {
        guard let mutationForm, stage > 0 else { return [] }

        let phaseOne: [(Int, Int)]
        let phaseTwo: [(Int, Int)]
        let phaseThree: [(Int, Int)]

        switch mutationForm.ecologyBranchID {
        case let branch where branch.contains("river"), let branch where branch.contains("open"):
            phaseOne = [(1, 4), (8, 4)]
            phaseTwo = [(2, 5), (7, 5)]
            phaseThree = [(1, 5), (8, 5)]
        case let branch where branch.contains("storm"), let branch where branch.contains("signal"), let branch where branch.contains("twilight"):
            phaseOne = [(1, 2), (8, 2)]
            phaseTwo = [(2, 2), (7, 2)]
            phaseThree = [(1, 1), (8, 1)]
        case let branch where branch.contains("grove"), let branch where branch.contains("rain"), let branch where branch.contains("bud"):
            phaseOne = [(2, 0), (7, 0)]
            phaseTwo = [(1, 1), (8, 1)]
            phaseThree = [(2, 1), (7, 1)]
        default:
            phaseOne = [(1, 4), (8, 4)]
            phaseTwo = [(2, 5), (7, 5)]
            phaseThree = [(1, 5), (8, 5)]
        }

        return stagedPixels(stage: stage, phaseOne: phaseOne, phaseTwo: phaseTwo, phaseThree: phaseThree)
    }

    private func mutationRhythmPixels(stage: Int) -> [(Int, Int)] {
        guard let mutationForm, stage > 0 else { return [] }

        let phaseOne: [(Int, Int)]
        let phaseTwo: [(Int, Int)]
        let phaseThree: [(Int, Int)]

        switch mutationForm.rhythmBranchID {
        case let branch where branch.contains("loop"):
            phaseOne = [(2, 6), (7, 6)]
            phaseTwo = [(3, 7), (6, 7)]
            phaseThree = [(4, 8), (5, 8)]
        case let branch where branch.contains("pulse"), let branch where branch.contains("surge"), let branch where branch.contains("drive"):
            phaseOne = [(1, 3), (8, 3)]
            phaseTwo = [(3, 8), (6, 8)]
            phaseThree = [(1, 4), (8, 4)]
        case let branch where branch.contains("draft"), let branch where branch.contains("pace"), let branch where branch.contains("grow"):
            phaseOne = [(2, 7), (7, 7)]
            phaseTwo = [(4, 8), (5, 8)]
            phaseThree = [(3, 8), (6, 8)]
        default:
            phaseOne = [(1, 3), (8, 3)]
            phaseTwo = [(3, 8), (6, 8)]
            phaseThree = [(1, 4), (8, 4)]
        }

        return stagedPixels(stage: stage, phaseOne: phaseOne, phaseTwo: phaseTwo, phaseThree: phaseThree)
    }

    private func stagedPixels(
        stage: Int,
        phaseOne: [(Int, Int)],
        phaseTwo: [(Int, Int)],
        phaseThree: [(Int, Int)]
    ) -> [(Int, Int)] {
        switch stage {
        case 1:
            return phaseOne
        case 2:
            return phaseOne + phaseTwo
        default:
            return phaseOne + phaseTwo + phaseThree
        }
    }

    private func bodySignaturePixels(stage: Int) -> [(Int, Int)] {
        guard let mutationForm, stage >= 3 else { return [] }

        switch mutationForm.bodyBranchID {
        case let branch where branch.contains("swift"), let branch where branch.contains("burst"):
            return [(1, 1), (8, 1)]
        case let branch where branch.contains("guard"), let branch where branch.contains("bulwark"), let branch where branch.contains("root"):
            return [(2, 8), (7, 8)]
        case let branch where branch.contains("core"), let branch where branch.contains("crown"), let branch where branch.contains("bloom"):
            return [(4, 0), (5, 0), (4, 9), (5, 9)]
        default:
            return [(1, 1), (8, 1)]
        }
    }

    private func ecologySignaturePixels(stage: Int) -> [(Int, Int)] {
        guard let mutationForm, stage >= 3 else { return [] }

        switch mutationForm.ecologyBranchID {
        case let branch where branch.contains("river"), let branch where branch.contains("open"):
            return [(0, 5), (9, 5)]
        case let branch where branch.contains("storm"), let branch where branch.contains("signal"), let branch where branch.contains("twilight"):
            return [(0, 2), (9, 2), (0, 3), (9, 3)]
        case let branch where branch.contains("grove"), let branch where branch.contains("rain"), let branch where branch.contains("bud"):
            return [(2, 0), (7, 0), (1, 0), (8, 0)]
        default:
            return [(0, 5), (9, 5)]
        }
    }

    private func rhythmSignaturePixels(stage: Int) -> [(Int, Int)] {
        guard let mutationForm, stage >= 3 else { return [] }

        switch mutationForm.rhythmBranchID {
        case let branch where branch.contains("loop"):
            return [(3, 9), (6, 9)]
        case let branch where branch.contains("pulse"), let branch where branch.contains("surge"), let branch where branch.contains("drive"):
            return [(0, 4), (9, 4), (4, 9), (5, 9)]
        case let branch where branch.contains("draft"), let branch where branch.contains("pace"), let branch where branch.contains("grow"):
            return [(2, 9), (7, 9), (4, 9), (5, 9)]
        default:
            return [(4, 9), (5, 9)]
        }
    }

    private func scheduleBlink() {
        Task {
            while true {
                try? await Task.sleep(for: .seconds(2.6))
                await MainActor.run {
                    blink = true
                }
                try? await Task.sleep(for: .seconds(0.14))
                await MainActor.run {
                    blink = false
                }
            }
        }
    }
}
