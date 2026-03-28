import RunimalCore
import SwiftUI

struct HatchCinematicView: View {
    let egg: EggInventoryEntry
    let pet: PetCollectionEntry
    let onDismiss: () -> Void

    @State private var phase: HatchPhase = .wait
    @State private var revealPet = false
    @State private var glitchShift = false
    @State private var revealFlash = false
    @State private var interferenceJolt = false
    @State private var hapticDriver = HatchCinematicHapticDriver()

    private var isRareReveal: Bool {
        pet.pet.rareVariant != nil
    }

    private var phaseAccent: Color {
        if phase == .complete && isRareReveal {
            return pet.pet.accentColor
        }
        return egg.shell.accentColor
    }

    private var variantLabel: String? {
        guard let rareVariant = pet.pet.rareVariant else { return nil }
        return RareVariantMeta.labels[rareVariant] ?? rareVariant.rawValue
    }

    var body: some View {
        ZStack {
            backgroundLayer
            completionFlashLayer

            VStack(spacing: 22) {
                topLog

                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.black.opacity(0.32))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(phaseAccent.opacity(0.42), lineWidth: 1)
                        )
                        .frame(width: 280, height: 320)

                    glitchGrid
                    HatchFragmentBurstView(
                        shell: egg.shell,
                        active: phase == .interference,
                        completed: phase == .complete,
                        pixelSize: 11
                    )

                    if revealPet {
                        PixelPetView(pet: pet.pet, pixelSize: 13)
                            .scaleEffect(revealFlash ? 1.08 : 1)
                            .transition(.scale(scale: 0.86).combined(with: .opacity))

                        if let variantLabel {
                            VStack {
                                RunimalSignalBadge(
                                    icon: "sparkles",
                                    label: variantLabel,
                                    accent: pet.pet.accentColor.opacity(0.92)
                                )
                                .offset(y: -116)
                                Spacer()
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    } else {
                        eggDecodeLayer
                            .transition(.scale(scale: 1.04).combined(with: .opacity))
                    }
                }
                .offset(x: phase == .interference ? (interferenceJolt ? 9 : -7) : 0)

                progressSection

                Button(phase == .complete ? "확인" : "건너뛰기") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .tint(.white.opacity(0.9))
            }
            .padding(24)
        }
        .task {
            await playSequence()
        }
        .animation(.linear(duration: 0.09).repeatForever(autoreverses: true), value: interferenceJolt)
    }

    private var backgroundLayer: some View {
        HatchInterferenceBackdropView(shell: egg.shell, phase: backdropPhase)
    }

    private var topLog: some View {
        VStack(spacing: 8) {
                Text(headerTitle)
                    .font(.caption.weight(.black))
                .tracking(2)
                .foregroundStyle(phaseAccent.opacity(0.92))

            Text(statusHeadline)
                .font(.title2.weight(.black))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(statusDetail)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.74))
                .multilineTextAlignment(.center)
        }
    }

    private var eggDecodeLayer: some View {
        ZStack {
            TraceEggView(
                accent: egg.shell.accentColor,
                shell: egg.shell,
                pixelSize: 13,
                cracked: phase == .interference || phase == .complete,
                resonance: phase == .wait ? 0.32 : 0.92
            )
            .opacity(phase == .interference ? 0.58 : 1)
            .scaleEffect(phase == .interference ? 0.92 : 1)
            .blur(radius: phase == .interference ? 1.4 : 0)

            if phase == .interference {
                TraceEggView(
                    accent: egg.shell.accentColor,
                    shell: egg.shell,
                    pixelSize: 13,
                    cracked: true,
                    resonance: 0.96
                )
                .opacity(0.28)
                .blendMode(.screen)
                .offset(x: 18, y: -10)

                TraceEggView(
                    accent: egg.shell.accentColor,
                    shell: egg.shell,
                    pixelSize: 13,
                    cracked: true,
                    resonance: 0.96
                )
                .opacity(0.22)
                .blendMode(.screen)
                .offset(x: -20, y: 14)
            }
        }
    }

    private var progressSection: some View {
        VStack(spacing: 12) {
            RunimalProgressBar(progress: phase.progress, accent: egg.shell.accentColor, height: 10)

            HStack(spacing: 10) {
                TraitChip(label: egg.shell.displayLabel, accent: egg.shell.accentColor)
                TraitChip(label: phase.badgeLabel, accent: .white.opacity(0.18))
                if let variantLabel, phase == .complete {
                    TraitChip(label: variantLabel, accent: pet.pet.accentColor.opacity(0.82))
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(egg.shell.scanLogLines, id: \.self) { line in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(egg.shell.particleColor.opacity(0.9))
                            .frame(width: 5, height: 5)
                        Text(line)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.white.opacity(0.64))
                        Spacer()
                    }
                }
            }
            .padding(.top, 2)
        }
    }

    private var glitchGrid: some View {
        GeometryReader { geometry in
            Path { path in
                let size = geometry.size
                stride(from: 0.0, through: size.width, by: 18).forEach { x in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                stride(from: 0.0, through: size.height, by: 18).forEach { y in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
            }
            .stroke(.white.opacity(phase == .interference ? 0.16 : 0.07), lineWidth: 0.6)
            .offset(x: glitchShift ? 3 : -2)
        }
        .frame(width: 280, height: 320)
        .clipped()
        .allowsHitTesting(false)
        .onAppear {
            glitchShift = true
        }
        .animation(.linear(duration: 0.18).repeatForever(autoreverses: true), value: glitchShift)
    }

    private var completionFlashLayer: some View {
        ZStack {
            Color.black
                .opacity(revealFlash ? 0.24 : 0)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(revealFlash ? 0.62 : 0),
                            egg.shell.particleColor.opacity(revealFlash ? 0.28 : 0),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Circle()
                .fill(egg.shell.particleColor.opacity(revealFlash ? 0.22 : 0))
                .frame(width: revealFlash ? 420 : 180, height: revealFlash ? 420 : 180)
                .blur(radius: 22)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var headerTitle: String {
        switch phase {
        case .wait: return "HATCH READY"
        case .decoding: return "DIGITAL DECODING"
        case .interference: return "INTERFERENCE ZONE"
        case .complete: return isRareReveal ? "RARE DECODING COMPLETE" : "DECODING COMPLETE"
        }
    }

    private var statusHeadline: String {
        switch phase {
        case .wait:
            return egg.shell.scanHeadline
        case .decoding:
            return "DIGITAL DECODING..."
        case .interference:
            return "SIGNAL STABILIZING..."
        case .complete:
            return isRareReveal ? "\(pet.pet.displayName) // RARE LOCKED" : "\(pet.pet.displayName) GENERATED"
        }
    }

    private var statusDetail: String {
        switch phase {
        case .wait:
            return egg.shell.hatchHint
        case .decoding:
            return "암호화된 데이터 블록을 실체화하는 중입니다."
        case .interference:
            return "데이터 타일이 분해되고 있습니다. 안정화 루틴으로 재구성 중입니다."
        case .complete:
            if isRareReveal {
                return "\(variantLabel ?? "희귀 변이") 신호가 고정되었습니다. 일반 개체보다 높은 가치의 생성 결과입니다."
            }
            return "디지털 틈새 세계에서 새로운 동행체가 생성되었습니다."
        }
    }

    private func playSequence() async {
        try? await Task.sleep(for: .milliseconds(180))
        phase = .decoding
        hapticDriver.playDecodingPulse()
        try? await Task.sleep(for: .milliseconds(620))
        phase = .interference
        interferenceJolt = true
        hapticDriver.playInterferenceRamp()
        try? await Task.sleep(for: .milliseconds(680))
        withAnimation(.easeOut(duration: 0.12)) {
            revealFlash = true
        }
        hapticDriver.playCompletionBurst()
        if isRareReveal {
            RunimalCuePlayer.playAlertCue(kind: .rare)
        } else {
            RunimalCuePlayer.playHatchCue(for: pet.pet)
        }
        try? await Task.sleep(for: .milliseconds(100))
        withAnimation(.spring(response: 0.7, dampingFraction: 0.78)) {
            revealPet = true
            phase = .complete
        }
        interferenceJolt = false
        try? await Task.sleep(for: .milliseconds(160))
        withAnimation(.easeOut(duration: 0.2)) {
            revealFlash = false
        }
    }

    private var backdropPhase: HatchBackdropPhase {
        switch phase {
        case .wait: return .idle
        case .decoding: return .decoding
        case .interference: return .interference
        case .complete: return .complete
        }
    }
}

private enum HatchPhase {
    case wait
    case decoding
    case interference
    case complete

    var progress: Double {
        switch self {
        case .wait: return 0.12
        case .decoding: return 0.48
        case .interference: return 0.78
        case .complete: return 1
        }
    }

    var badgeLabel: String {
        switch self {
        case .wait: return "READY"
        case .decoding: return "SCANNING"
        case .interference: return "LOCKING"
        case .complete: return "GENERATED"
        }
    }
}
