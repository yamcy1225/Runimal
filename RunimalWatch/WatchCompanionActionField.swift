import RunimalCore
import SwiftUI
import Foundation

struct WatchCompanionActionField: View {
    enum Presentation {
        case compact
        case hero

        var height: CGFloat {
            switch self {
            case .compact:
                68
            case .hero:
                112
            }
        }

        var spriteScaleBoost: CGFloat {
            switch self {
            case .compact:
                0
            case .hero:
                0.2
            }
        }
    }

    private enum InteractionStyle {
        case tap
        case bond
    }

    private struct TouchReaction: Equatable {
        let label: String
        let symbol: String
        let delighted: Bool
    }

    let companion: WatchMainCompanionContext
    let accent: Color
    let heartResonance: Double
    let isRunning: Bool
    var presentation: Presentation = .compact
    var reaction: MutationRuntimeReactionSnapshot? = nil

    @State private var lastTouchPoint: CGPoint?
    @State private var lastTouchDate: Date?
    @State private var activeTouchReaction: TouchReaction?
    @State private var touchBurstSeed = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 18.0)) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate
            let touchPull = touchPullStrength(at: timeline.date)
            let touchBurst = touchBurstStrength(at: timeline.date)
            let reactionOpacity = bubbleOpacity(at: timeline.date)

            GeometryReader { geometry in
                let size = geometry.size
                let spriteSize = min(
                    size.width * (presentation == .hero ? 0.42 : 0.36),
                    size.height * 0.74,
                    presentation == .hero ? 58 : 46
                )
                let basePosition = companion.selection.kind == .egg
                    ? eggPosition(in: size, spriteSize: spriteSize, phase: phase)
                    : roamingPosition(in: size, spriteSize: spriteSize, phase: phase)
                let spritePosition = interactivePosition(
                    from: basePosition,
                    size: size,
                    spriteSize: spriteSize,
                    phase: phase,
                    touchPull: touchPull,
                    at: timeline.date
                )
                let spriteRotation = companion.selection.kind == .egg
                    ? eggRotation(for: phase)
                    : roamingRotation(for: phase)
                let spriteScale: CGFloat = companion.selection.kind == .egg
                    ? 1.0
                    : roamingScale(for: phase) + presentation.spriteScaleBoost + touchPull * 0.08

                ZStack {
                    roamingBackdrop(size: size, phase: phase)

                    if companion.selection.kind == .egg {
                        incubatorPulse(size: size, phase: phase)
                    } else {
                        standbyPulse(size: size, phase: phase)
                    }

                    if let lastTouchPoint, touchBurst > 0.01 {
                        touchBurstOverlay(
                            around: lastTouchPoint,
                            burst: touchBurst,
                            seed: touchBurstSeed
                        )
                    }

                    spriteView
                        .frame(width: spriteSize, height: spriteSize)
                        .scaleEffect(spriteScale)
                        .rotationEffect(.degrees(spriteRotation))
                        .position(spritePosition)

                    if let activeTouchReaction, reactionOpacity > 0.01 {
                        reactionBubble(activeTouchReaction)
                            .opacity(reactionOpacity)
                            .position(x: size.width / 2, y: presentation == .hero ? 18 : 14)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    SpatialTapGesture()
                        .onEnded { value in
                            triggerTouchReaction(
                                at: value.location,
                                in: size,
                                style: .tap
                            )
                        }
                )
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.42)
                        .onEnded { _ in
                            triggerTouchReaction(
                                at: CGPoint(x: size.width / 2, y: size.height * 0.54),
                                in: size,
                                style: .bond
                            )
                        }
                )
            }
        }
        .frame(height: presentation.height)
        .clipped()
    }

    private var spriteView: some View {
        Group {
            if companion.selection.kind == .pet, let pet = companion.pet {
                PixelPetView(
                    pet: pet,
                    pixelSize: presentation == .hero ? 4.1 : 3.7,
                    growthStageIndex: companion.growthStageIndex,
                    mutationForm: watchMutationForm,
                    mutationVisualState: visualState,
                    showsAura: presentation != .hero
                )
            } else if let shell = companion.eggShell {
                TraceEggView(
                    accent: accent,
                    shell: shell,
                    pixelSize: presentation == .hero ? 3.4 : 3.1,
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
        let presenceBoost = presentation == .hero ? CGFloat(0.14) : 0
        let xAmplitude = max((size.width - spriteSize) * ((isRunning ? 0.26 : 0.2) + rhythmBoost + reactionRhythmBoost + presenceBoost), 10)
        let yAmplitude = max((size.height - spriteSize) * ((isRunning ? 0.18 : 0.12) + rhythmBoost * 0.7 + reactionRhythmBoost * 0.8 + presenceBoost * 0.66), 6)
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
            if presentation == .hero {
                Ellipse()
                    .fill(accent.opacity(0.10 + ecologyBoost * 0.4))
                    .frame(width: size.width * 0.78, height: size.height * 0.5)
                    .blur(radius: 10)

                WatchCountryOutlineShape(countryCode: currentCountryCode)
                    .trim(from: 0, to: 0.96)
                    .stroke(
                        accent.opacity(0.42 + CGFloat(ecologyBoost) * 0.3),
                        style: StrokeStyle(
                            lineWidth: 2.4,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .frame(width: size.width * 0.82, height: size.height * 0.58)
                    .offset(x: size.width * 0.02, y: -2)

                WatchCountryOutlineShape(countryCode: currentCountryCode)
                    .trim(from: 0.08, to: 0.82)
                    .stroke(
                        GameBoyPalette.lightest.opacity(0.34),
                        style: StrokeStyle(
                            lineWidth: 1.2,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .frame(width: size.width * 0.76, height: size.height * 0.52)
                    .offset(x: size.width * 0.015, y: -1)
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(GameBoyPalette.lightest.opacity(0.7))
                    .frame(width: size.width * 0.88, height: size.height * 0.72)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(GameBoyPalette.mediumDark.opacity(0.55), lineWidth: 1)
                    )
            }

            if presentation != .hero {
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
            }
        }
    }

    private var currentCountryCode: String {
        if #available(watchOS 10.0, *) {
            if let regionIdentifier = Locale.autoupdatingCurrent.region?.identifier, regionIdentifier.isEmpty == false {
                return regionIdentifier
            }
        }
        return Locale.autoupdatingCurrent.regionCode ?? Locale.current.regionCode ?? "KR"
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

        return ZStack {
            if presentation == .hero {
                Circle()
                    .fill(accent.opacity(glow * 0.3))
                    .frame(width: size.width * 0.18, height: size.width * 0.18)
                    .blur(radius: 8)

                Circle()
                    .fill(GameBoyPalette.lightest.opacity(0.16 + ecologyStage * 0.01))
                    .frame(width: size.width * 0.11, height: size.width * 0.11)
                    .blur(radius: 6)
                    .offset(x: size.width * 0.14, y: size.height * 0.08)
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(accent.opacity(glow), lineWidth: 2)
                    .frame(width: size.width * widthScale, height: 24 + ecologyStage * 0.8)
            }
        }
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

    private func interactivePosition(
        from basePosition: CGPoint,
        size: CGSize,
        spriteSize: CGFloat,
        phase: TimeInterval,
        touchPull: CGFloat,
        at date: Date
    ) -> CGPoint {
        guard let lastTouchPoint else { return basePosition }

        let elapsed = date.timeIntervalSince(lastTouchDate ?? date)
        let hop = CGFloat(sin(elapsed * 14)) * (presentation == .hero ? 7 : 4) * touchPull
        let x = basePosition.x + (lastTouchPoint.x - basePosition.x) * touchPull
        let y = basePosition.y + (lastTouchPoint.y - basePosition.y) * touchPull - hop - CGFloat(cos(phase * 3.4)) * touchPull

        return CGPoint(
            x: min(max(x, spriteSize / 2 + 8), size.width - spriteSize / 2 - 8),
            y: min(max(y, spriteSize / 2 + 8), size.height - spriteSize / 2 - 8)
        )
    }

    private func touchPullStrength(at date: Date) -> CGFloat {
        guard let lastTouchDate else { return 0 }
        let elapsed = date.timeIntervalSince(lastTouchDate)
        guard elapsed < 2.8 else { return 0 }
        let progress = elapsed / 2.8
        return CGFloat(pow(1 - progress, 1.6))
    }

    private func touchBurstStrength(at date: Date) -> CGFloat {
        guard let lastTouchDate else { return 0 }
        let elapsed = date.timeIntervalSince(lastTouchDate)
        guard elapsed < 1.1 else { return 0 }
        let progress = elapsed / 1.1
        return CGFloat(1 - progress)
    }

    private func bubbleOpacity(at date: Date) -> Double {
        guard let lastTouchDate, activeTouchReaction != nil else { return 0 }
        let elapsed = date.timeIntervalSince(lastTouchDate)
        guard elapsed < 1.9 else { return 0 }
        if elapsed < 0.18 {
            return elapsed / 0.18
        }
        return max(0, 1 - (elapsed - 0.18) / 1.72)
    }

    private func touchBurstOverlay(around point: CGPoint, burst: CGFloat, seed: Int) -> some View {
        let symbolColor = accent.opacity(0.2 + burst * 0.38)

        return ZStack {
            Circle()
                .stroke(symbolColor, lineWidth: 2)
                .frame(width: 22 + burst * 40, height: 22 + burst * 40)
                .position(point)

            ForEach(0..<5, id: \.self) { index in
                let angle = Double(index) * 72 + Double(seed * 9)
                let radius = 8 + Double(burst) * 22
                Text(index.isMultiple(of: 2) ? "*" : "o")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(GameBoyPalette.darkest.opacity(0.42 + burst * 0.38))
                    .position(
                        x: point.x + CGFloat(cos(angle * .pi / 180) * radius),
                        y: point.y + CGFloat(sin(angle * .pi / 180) * radius)
                    )
            }
        }
    }

    private func reactionBubble(_ reaction: TouchReaction) -> some View {
        HStack(spacing: 5) {
            Text(reaction.symbol)
            Text(reaction.label)
        }
        .font(.caption2.monospaced().weight(.black))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous)
                .fill(GameBoyPalette.lightest.opacity(0.92))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(GameBoyPalette.darkest.opacity(0.88), lineWidth: 1.5)
                )
        )
        .foregroundStyle(GameBoyPalette.darkest)
    }

    private func triggerTouchReaction(at point: CGPoint, in size: CGSize, style: InteractionStyle) {
        lastTouchPoint = CGPoint(
            x: min(max(point.x, 16), size.width - 16),
            y: min(max(point.y, 16), size.height - 16)
        )
        lastTouchDate = Date()
        touchBurstSeed += 1
        activeTouchReaction = nextReaction(style: style)
        RunimalCuePlayer.playCompanionTouchCue(isDelighted: activeTouchReaction?.delighted == true)
    }

    private func nextReaction(style: InteractionStyle) -> TouchReaction {
        if companion.selection.kind == .egg {
            let options = [
                TouchReaction(label: "꼬물", symbol: "~", delighted: false),
                TouchReaction(label: "두근", symbol: "o", delighted: true),
                TouchReaction(label: "꿈틀", symbol: "*", delighted: false),
            ]
            return options[touchBurstSeed % options.count]
        }

        let tapOptions = isRunning
            ? [
                TouchReaction(label: "좋아!", symbol: "*", delighted: true),
                TouchReaction(label: "계속 가자", symbol: ">", delighted: true),
                TouchReaction(label: "리듬 맞았어", symbol: "~", delighted: true),
            ]
            : [
                TouchReaction(label: "반가워", symbol: "o", delighted: true),
                TouchReaction(label: "토닥 좋다", symbol: "*", delighted: false),
                TouchReaction(label: "같이 놀자", symbol: "+", delighted: true),
            ]

        let bondOptions = [
            TouchReaction(label: "곁에 있을게", symbol: "o", delighted: true),
            TouchReaction(label: "오늘도 같이", symbol: "*", delighted: true),
            TouchReaction(label: "기다렸어", symbol: "+", delighted: true),
        ]

        let options = style == .bond ? bondOptions : tapOptions
        return options[touchBurstSeed % options.count]
    }
}

private struct WatchCountryOutlineShape: Shape {
    let countryCode: String

    func path(in rect: CGRect) -> Path {
        let points = normalizedPoints(for: countryCode)
        guard let first = points.first else { return Path() }

        func point(_ normalized: CGPoint) -> CGPoint {
            CGPoint(
                x: rect.minX + normalized.x * rect.width,
                y: rect.minY + normalized.y * rect.height
            )
        }

        var path = Path()
        path.move(to: point(first))

        for normalized in points.dropFirst() {
            path.addLine(to: point(normalized))
        }

        path.closeSubpath()
        return path
    }

    private func normalizedPoints(for code: String) -> [CGPoint] {
        switch code.uppercased() {
        case "KR":
            return [
                CGPoint(x: 0.42, y: 0.06), CGPoint(x: 0.53, y: 0.10), CGPoint(x: 0.60, y: 0.20),
                CGPoint(x: 0.57, y: 0.29), CGPoint(x: 0.63, y: 0.37), CGPoint(x: 0.59, y: 0.48),
                CGPoint(x: 0.66, y: 0.58), CGPoint(x: 0.60, y: 0.71), CGPoint(x: 0.53, y: 0.84),
                CGPoint(x: 0.45, y: 0.92), CGPoint(x: 0.38, y: 0.86), CGPoint(x: 0.35, y: 0.73),
                CGPoint(x: 0.30, y: 0.62), CGPoint(x: 0.34, y: 0.50), CGPoint(x: 0.29, y: 0.40),
                CGPoint(x: 0.33, y: 0.27), CGPoint(x: 0.37, y: 0.17)
            ]
        case "JP":
            return [
                CGPoint(x: 0.66, y: 0.06), CGPoint(x: 0.70, y: 0.14), CGPoint(x: 0.64, y: 0.24),
                CGPoint(x: 0.68, y: 0.35), CGPoint(x: 0.61, y: 0.47), CGPoint(x: 0.66, y: 0.57),
                CGPoint(x: 0.58, y: 0.66), CGPoint(x: 0.60, y: 0.79), CGPoint(x: 0.51, y: 0.92),
                CGPoint(x: 0.45, y: 0.84), CGPoint(x: 0.47, y: 0.69), CGPoint(x: 0.40, y: 0.58),
                CGPoint(x: 0.45, y: 0.46), CGPoint(x: 0.39, y: 0.33), CGPoint(x: 0.45, y: 0.20),
                CGPoint(x: 0.56, y: 0.12)
            ]
        case "US":
            return [
                CGPoint(x: 0.06, y: 0.37), CGPoint(x: 0.16, y: 0.25), CGPoint(x: 0.30, y: 0.20),
                CGPoint(x: 0.44, y: 0.17), CGPoint(x: 0.60, y: 0.18), CGPoint(x: 0.75, y: 0.23),
                CGPoint(x: 0.88, y: 0.29), CGPoint(x: 0.94, y: 0.40), CGPoint(x: 0.90, y: 0.54),
                CGPoint(x: 0.81, y: 0.58), CGPoint(x: 0.73, y: 0.69), CGPoint(x: 0.60, y: 0.73),
                CGPoint(x: 0.47, y: 0.77), CGPoint(x: 0.31, y: 0.74), CGPoint(x: 0.18, y: 0.66),
                CGPoint(x: 0.10, y: 0.56), CGPoint(x: 0.07, y: 0.46)
            ]
        case "GB":
            return [
                CGPoint(x: 0.46, y: 0.07), CGPoint(x: 0.56, y: 0.12), CGPoint(x: 0.60, y: 0.22),
                CGPoint(x: 0.55, y: 0.31), CGPoint(x: 0.59, y: 0.42), CGPoint(x: 0.54, y: 0.52),
                CGPoint(x: 0.58, y: 0.62), CGPoint(x: 0.53, y: 0.75), CGPoint(x: 0.44, y: 0.89),
                CGPoint(x: 0.36, y: 0.80), CGPoint(x: 0.33, y: 0.67), CGPoint(x: 0.27, y: 0.54),
                CGPoint(x: 0.31, y: 0.41), CGPoint(x: 0.27, y: 0.27), CGPoint(x: 0.35, y: 0.15)
            ]
        case "FR":
            return [
                CGPoint(x: 0.48, y: 0.09), CGPoint(x: 0.62, y: 0.22), CGPoint(x: 0.65, y: 0.40),
                CGPoint(x: 0.58, y: 0.63), CGPoint(x: 0.44, y: 0.78), CGPoint(x: 0.28, y: 0.61),
                CGPoint(x: 0.29, y: 0.38), CGPoint(x: 0.36, y: 0.18)
            ]
        default:
            return [
                CGPoint(x: 0.11, y: 0.44), CGPoint(x: 0.23, y: 0.27), CGPoint(x: 0.37, y: 0.19),
                CGPoint(x: 0.56, y: 0.16), CGPoint(x: 0.72, y: 0.22), CGPoint(x: 0.86, y: 0.35),
                CGPoint(x: 0.90, y: 0.53), CGPoint(x: 0.82, y: 0.69), CGPoint(x: 0.67, y: 0.79),
                CGPoint(x: 0.48, y: 0.84), CGPoint(x: 0.30, y: 0.78), CGPoint(x: 0.17, y: 0.65),
                CGPoint(x: 0.10, y: 0.53)
            ]
        }
    }
}
