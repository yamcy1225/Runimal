import RunimalCore
import SwiftUI

struct WatchCompanionActionField: View {
    let companion: WatchMainCompanionContext
    let accent: Color
    let heartResonance: Double
    let isRunning: Bool
    var reaction: MutationRuntimeReactionSnapshot? = nil

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 18.0)) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate

            GeometryReader { geometry in
                let size = geometry.size
                let spriteSize = min(size.width * 0.36, size.height * 0.74, 46)
                let spritePosition = companion.selection.kind == .egg
                    ? eggPosition(in: size, spriteSize: spriteSize, phase: phase)
                    : roamingPosition(in: size, spriteSize: spriteSize, phase: phase)
                let spriteRotation = companion.selection.kind == .egg
                    ? eggRotation(for: phase)
                    : roamingRotation(for: phase)
                let spriteScale: CGFloat = companion.selection.kind == .egg
                    ? 1.0
                    : roamingScale(for: phase)

                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(GameBoyPalette.mediumLight.opacity(0.18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(GameBoyPalette.darkest, lineWidth: 2)
                        )

                    roamingBackdrop(size: size, phase: phase)

                    if companion.selection.kind == .egg {
                        incubatorPulse(size: size, phase: phase)
                    } else {
                        standbyPulse(size: size, phase: phase)
                    }

                    spriteView
                        .frame(width: spriteSize, height: spriteSize)
                        .scaleEffect(spriteScale)
                        .rotationEffect(.degrees(spriteRotation))
                        .position(spritePosition)
                }
            }
        }
        .frame(height: 68)
        .clipped()
    }

    private var spriteView: some View {
        Group {
            if companion.selection.kind == .pet, let pet = companion.pet {
                PixelPetView(
                    pet: pet,
                    pixelSize: 3.7,
                    growthStageIndex: companion.growthStageIndex,
                    mutationForm: watchMutationForm,
                    mutationVisualState: visualState
                )
            } else if let shell = companion.eggShell {
                TraceEggView(
                    accent: accent,
                    shell: shell,
                    pixelSize: 3.1,
                    cracked: companion.eggReadyToHatch,
                    resonance: heartResonance
                )
            } else {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(accent.opacity(0.24))
            }
        }
    }

    private var visualState: MutationVisualState? {
        guard companion.selection.kind == .pet else { return nil }
        guard companion.mutationBodyStage != nil || companion.mutationEcologyStage != nil || companion.mutationRhythmStage != nil else {
            return nil
        }
        return MutationVisualState(
            bodyStage: companion.mutationBodyStage ?? 0,
            ecologyStage: companion.mutationEcologyStage ?? 0,
            rhythmStage: companion.mutationRhythmStage ?? 0
        )
    }

    private var watchMutationForm: MutationFormSnapshot? {
        guard companion.selection.kind == .pet,
              let pet = companion.pet,
              let bodyBranchID = companion.mutationBodyBranchID,
              let ecologyBranchID = companion.mutationEcologyBranchID,
              let rhythmBranchID = companion.mutationRhythmBranchID else {
            return nil
        }

        let shortLabel = companion.petHeadline ?? companion.displayName
        return MutationFormSnapshot(
            speciesID: pet.species.rawValue,
            formID: [pet.species.rawValue, bodyBranchID, ecologyBranchID, rhythmBranchID].joined(separator: "."),
            shortLabel: shortLabel,
            bodyBranchID: bodyBranchID,
            ecologyBranchID: ecologyBranchID,
            rhythmBranchID: rhythmBranchID,
            confidence: 1
        )
    }

    private func roamingPosition(in size: CGSize, spriteSize: CGFloat, phase: TimeInterval) -> CGPoint {
        let rhythmBoost = CGFloat(Double(visualState?.rhythmStage ?? 0) * 0.018)
        let reactionRhythmBoost = reaction?.axis == .rhythm ? CGFloat(0.05) : 0
        let speedBoost = reaction?.axis == .rhythm ? 0.26 : 0
        let xAmplitude = max((size.width - spriteSize) * ((isRunning ? 0.26 : 0.2) + rhythmBoost + reactionRhythmBoost), 10)
        let yAmplitude = max((size.height - spriteSize) * ((isRunning ? 0.18 : 0.12) + rhythmBoost * 0.7 + reactionRhythmBoost * 0.8), 6)
        let x = size.width / 2
            + CGFloat(sin(phase * ((isRunning ? 1.15 : 0.84) + speedBoost))) * xAmplitude
            + CGFloat(sin(phase * 2.1)) * 5
        let y = size.height / 2
            + CGFloat(cos(phase * ((isRunning ? 1.42 : 1.08) + speedBoost * 0.8))) * yAmplitude
            + CGFloat(sin(phase * 2.6)) * 3
        return CGPoint(
            x: min(max(x, spriteSize / 2 + 8), size.width - spriteSize / 2 - 8),
            y: min(max(y, spriteSize / 2 + 8), size.height - spriteSize / 2 - 8)
        )
    }

    private func eggPosition(in size: CGSize, spriteSize: CGFloat, phase: TimeInterval) -> CGPoint {
        CGPoint(
            x: size.width / 2 + CGFloat(sin(phase * 3.1)) * 2.4,
            y: size.height / 2 + CGFloat(cos(phase * 2.4)) * 1.8
        )
    }

    private func roamingRotation(for phase: TimeInterval) -> Double {
        let reactionBoost = reaction?.axis == .body ? 2.2 : reaction?.axis == .rhythm ? 1.2 : 0
        return isRunning ? sin(phase * 2.2) * (5.0 + reactionBoost) : sin(phase * 1.8) * (2.8 + reactionBoost * 0.45)
    }

    private func eggRotation(for phase: TimeInterval) -> Double {
        sin(phase * 3.4) * 1.6
    }

    private func roamingBackdrop(size: CGSize, phase: TimeInterval) -> some View {
        let ecologyBoost = reaction?.axis == .ecology ? 0.18 : 0

        return ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(GameBoyPalette.lightest.opacity(0.7))
                .frame(width: size.width * 0.88, height: size.height * 0.72)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(GameBoyPalette.mediumDark.opacity(0.55), lineWidth: 1)
                )

            VStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 6) {
                        ForEach(0..<8, id: \.self) { column in
                            Capsule(style: .continuous)
                                .fill((row + column).isMultiple(of: 2) ? GameBoyPalette.mediumLight.opacity(0.36) : .clear)
                                .frame(width: 10, height: 3)
                        }
                    }
                }
            }
            .opacity(companion.selection.kind == .egg ? 0.45 : 0.8)

            HStack(spacing: 6) {
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(accent.opacity(0.18 + Double(index) * 0.08 + ecologyBoost))
                        .frame(width: 3.5, height: 3.5)
                        .offset(
                            x: CGFloat(index - 3) * 11,
                            y: CGFloat(sin(phase * (1.4 + ecologyBoost) + Double(index)) * (4 + ecologyBoost * 8))
                        )
                }
            }
        }
    }

    private func incubatorPulse(size: CGSize, phase: TimeInterval) -> some View {
        let glow = 0.45 + (sin(phase * 2.1) + 1) * 0.18

        return ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(accent.opacity(glow), lineWidth: 2)
                .frame(width: size.width * 0.68, height: 22)

            HStack(spacing: 5) {
                ForEach(0..<6, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(accent.opacity(index.isMultiple(of: 2) ? glow : glow * 0.58))
                        .frame(width: 10, height: 4)
                }
            }
            .offset(y: 17)
        }
    }

    private func standbyPulse(size: CGSize, phase: TimeInterval) -> some View {
        let bodyStage = Double(visualState?.bodyStage ?? 0)
        let ecologyStage = Double(visualState?.ecologyStage ?? 0)
        let reactionBodyBoost = reaction?.axis == .body ? 0.05 : 0
        let reactionEcologyBoost = reaction?.axis == .ecology ? 0.035 : 0
        let glow = 0.18 + (sin(phase * 2.4) + 1) * 0.08 + bodyStage * 0.015 + ecologyStage * 0.01 + reactionBodyBoost + reactionEcologyBoost
        let widthScale = 0.7 + bodyStage * 0.03 + reactionBodyBoost

        return RoundedRectangle(cornerRadius: 10, style: .continuous)
            .stroke(accent.opacity(glow), lineWidth: 2)
            .frame(width: size.width * widthScale, height: 24 + ecologyStage * 0.8)
    }

    private func roamingScale(for phase: TimeInterval) -> CGFloat {
        guard let reaction else { return 1.0 }
        let transitionBoost: CGFloat = reaction.transitionStageTitle == nil ? 0 : 0.012
        switch reaction.axis {
        case .body:
            return 1.02 + transitionBoost + CGFloat((sin(phase * 2.0) + 1) * 0.025)
        case .ecology:
            return 1.0 + transitionBoost + CGFloat((cos(phase * 1.6) + 1) * 0.018)
        case .rhythm:
            return 1.01 + transitionBoost + CGFloat((sin(phase * 3.2) + 1) * 0.022)
        }
    }
}
