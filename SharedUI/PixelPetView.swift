import RunimalCore
import SwiftUI

struct PixelPetView: View {
    let pet: GeneratedPet
    var pixelSize: CGFloat = 10
    var growthStageIndex: Int? = nil
    var mutationForm: MutationFormSnapshot? = nil
    var mutationHistory: MutationHistorySnapshot? = nil
    var mutationVisualState: MutationVisualState? = nil
    var seasonalLayers: [SeasonalVisualLayer] = []
    var showsAura: Bool = true
    @State private var hovering = false
    @State private var tiltDegrees = 0.0
    @State private var blink = false
    @State private var auraShift = false

    var body: some View {
        let infantStage = growthStageIndex == 1
        let bodyPixels = coordinates(SpeciesVisualRenderProfile.bodySpritePixels(for: pet.species, stageIndex: growthStageIndex))
        let eyePixels = coordinates(SpeciesVisualRenderProfile.eyePixels(for: pet.species, stageIndex: growthStageIndex))
        let accentPixels = accent(for: pet.rareVariant, infantStage: infantStage)
        let resolvedVisualState = mutationVisualState ?? MutationVisualEvolutionEngine.state(
            for: mutationHistory,
            fallbackForm: mutationForm
        )
        let visualState = infantStage ? MutationVisualState(bodyStage: 0, ecologyStage: 0, rhythmStage: 0) : resolvedVisualState

        ZStack(alignment: .topLeading) {
            if showsAura {
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
                    .offset(y: pixelSize * 0.8)

                Circle()
                    .stroke(pet.accentColor.opacity(auraShift ? 0.34 : 0.16), style: StrokeStyle(lineWidth: max(1, pixelSize * 0.16), dash: [3, 5]))
                    .frame(width: 8.9 * pixelSize, height: 8.9 * pixelSize)
                    .rotationEffect(.degrees(auraShift ? 14 : -12))
            }

            pixelLayer(bodyPixels, color: pet.accentColor)
            pixelLayer(baseBodyIdentityPixels, color: pet.accentColor.opacity(0.82), inset: pixelSize * 0.08)
            pixelLayer(growthBodyPixels, color: pet.accentColor.opacity(0.78), inset: pixelSize * 0.12)
            pixelLayer(faceAccentPixels, color: .white.opacity(0.96), inset: pixelSize * 0.1)
            pixelLayer(eyePixels, color: blink ? .white.opacity(0.12) : .white)
            pixelLayer(eyePixels, color: .black, inset: blink ? pixelSize * 0.58 : pixelSize * 0.22)
            pixelLayer(accentPixels, color: .white.opacity(0.95))
            pixelLayer(baseAccentPixels, color: .white.opacity(0.92), inset: pixelSize * 0.18)
            pixelLayer(growthAccentPixels, color: .white.opacity(0.9), inset: pixelSize * 0.26)
            pixelLayer(seasonShellPixels(infantStage: infantStage), color: pet.accentColor.opacity(0.32))
            pixelLayer(raidStripePixels(infantStage: infantStage), color: .yellow.opacity(0.92), inset: pixelSize * 0.18)
            pixelLayer(crestPixels(infantStage: infantStage), color: .white.opacity(0.92), inset: pixelSize * 0.12)
            pixelLayer(sparkPixels(infantStage: infantStage), color: .white.opacity(auraShift ? 0.92 : 0.4), inset: pixelSize * 0.46)
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
            if showsAura && pet.rareVariant != nil && !infantStage {
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

    private var baseBodyIdentityPixels: [(Int, Int)] {
        coordinates(SpeciesVisualRenderProfile.baseIdentityPixels(for: pet.species, stageIndex: growthStageIndex))
    }

    private var baseAccentPixels: [(Int, Int)] {
        coordinates(SpeciesVisualRenderProfile.baseAccentPixels(for: pet.species, stageIndex: growthStageIndex))
    }

    private var growthBodyPixels: [(Int, Int)] {
        coordinates(SpeciesVisualRenderProfile.growthBodyPixels(for: pet.species, stageIndex: growthStageIndex))
    }

    private var growthAccentPixels: [(Int, Int)] {
        coordinates(SpeciesVisualRenderProfile.growthAccentPixels(for: pet.species, stageIndex: growthStageIndex))
    }

    private func accent(for variant: RareVariant?, infantStage: Bool) -> [(Int, Int)] {
        guard !infantStage else { return [] }

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

    private var faceAccentPixels: [(Int, Int)] {
        coordinates(SpeciesVisualRenderProfile.faceAccentPixels(for: pet.species, stageIndex: growthStageIndex))
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

    private func seasonShellPixels(infantStage: Bool) -> [(Int, Int)] {
        guard !infantStage else { return [] }
        guard seasonalLayers.contains(.seasonShell) else { return [] }
        return [(1, 2), (1, 3), (1, 4), (8, 2), (8, 3), (8, 4), (3, 0), (6, 0)]
    }

    private func raidStripePixels(infantStage: Bool) -> [(Int, Int)] {
        guard !infantStage else { return [] }
        guard seasonalLayers.contains(.raidStripe) else { return [] }
        return [(2, 5), (3, 6), (4, 7), (6, 5), (5, 6)]
    }

    private func crestPixels(infantStage: Bool) -> [(Int, Int)] {
        guard !infantStage else { return [] }

        if mutationForm != nil {
            return [(4, 0), (5, 0), (4, 1), (5, 1)]
        }

        if seasonalLayers.contains(.seasonShell) {
            return [(4, 0), (5, 0)]
        }

        guard pet.rareVariant != nil else { return [] }
        return [(4, 1), (5, 1)]
    }

    private func sparkPixels(infantStage: Bool) -> [(Int, Int)] {
        guard !infantStage else { return [] }
        return [(1, 2), (8, 2), (2, 7), (7, 7)]
    }

    private func mutationBodyPixels(stage: Int) -> [(Int, Int)] {
        guard stage > 0 else { return [] }
        let phases = SpeciesVisualRenderProfile.mutationBodyPhases(for: mutationForm?.bodyBranchID)
        return stagedPixels(stage: stage, phases: phases)
    }

    private func mutationEcologyPixels(stage: Int) -> [(Int, Int)] {
        guard stage > 0 else { return [] }
        let phases = SpeciesVisualRenderProfile.mutationEcologyPhases(for: mutationForm?.ecologyBranchID)
        return stagedPixels(stage: stage, phases: phases)
    }

    private func mutationRhythmPixels(stage: Int) -> [(Int, Int)] {
        guard stage > 0 else { return [] }
        let phases = SpeciesVisualRenderProfile.mutationRhythmPhases(for: mutationForm?.rhythmBranchID)
        return stagedPixels(stage: stage, phases: phases)
    }

    private func stagedPixels(stage: Int, phases: PixelOverlayPhases) -> [(Int, Int)] {
        switch stage {
        case 1:
            return coordinates(phases.phaseOne)
        case 2:
            return coordinates(phases.phaseOne + phases.phaseTwo)
        default:
            return coordinates(phases.phaseOne + phases.phaseTwo + phases.phaseThree)
        }
    }

    private func bodySignaturePixels(stage: Int) -> [(Int, Int)] {
        guard stage >= 3 else { return [] }
        return coordinates(SpeciesVisualRenderProfile.bodySignaturePixels(for: mutationForm?.bodyBranchID))
    }

    private func ecologySignaturePixels(stage: Int) -> [(Int, Int)] {
        guard stage >= 3 else { return [] }
        return coordinates(SpeciesVisualRenderProfile.ecologySignaturePixels(for: mutationForm?.ecologyBranchID))
    }

    private func rhythmSignaturePixels(stage: Int) -> [(Int, Int)] {
        guard stage >= 3 else { return [] }
        return coordinates(SpeciesVisualRenderProfile.rhythmSignaturePixels(for: mutationForm?.rhythmBranchID))
    }

    private func coordinates(_ pixels: [PixelCoordinate]) -> [(Int, Int)] {
        pixels.map { ($0.x, $0.y) }
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
