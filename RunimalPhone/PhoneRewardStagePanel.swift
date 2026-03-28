import RunimalCore
import SwiftUI

struct PhoneRewardStagePanel: View {
    let pet: GeneratedPet
    let progress: EvolutionProgress
    let activeEffects: [WeeklyRewardEffect]
    let season: WeeklySeason
    let claimableReward: WeeklyReward?
    let onClaim: (() -> Void)?

    @State private var energized = false
    @State private var burstScale: CGFloat = 0.92
    @State private var revealPet = false
    @State private var crackEgg = false

    private var mythicTitle: String {
        RunimalGameEngine.mythicTitle(for: pet, season: season)
    }

    private var stageTitle: String {
        if progress.stageLabel == "Mythic" {
            return "최종형 고정"
        }

        if claimableReward != nil {
            return "디코딩 보상"
        }

        if activeEffects.isEmpty == false {
            return "성장 공명"
        }

        if progress.progressRatio >= 0.8 {
            return "진화 임계"
        }

        return "디지털 챔버"
    }

    private var stageDetail: String {
        if progress.stageLabel == "Mythic" {
            return RunimalGameEngine.mythicSignalLine(for: pet, season: season)
        }

        if let claimableReward {
            return claimableReward.detail
        }

        if activeEffects.isEmpty == false {
            return activeEffects.map(\.title).joined(separator: " · ")
        }

        if progress.progressRatio >= 0.8 {
            return "다음 러닝 한 번이면 진화 임계점입니다."
        }

        return "디코딩 보상과 성장 효과가 다음 루프로 이어집니다."
    }

    private var primaryBadgeLabel: String {
        if progress.stageLabel == "Mythic" { return "최종형" }
        if claimableReward != nil { return "수령 가능" }
        if pet.rareVariant != nil { return "희귀 경로" }
        return progress.stageLabel
    }

    private var secondaryBadgeLabel: String {
        if activeEffects.isEmpty == false { return "\(activeEffects.count)개 효과" }
        return season.title
    }

    private var variantLabel: String {
        pet.rareVariant.map { RareVariantMeta.labels[$0] ?? $0.rawValue } ?? "기본 궤적"
    }

    private var stageAccent: Color {
        if claimableReward != nil {
            return .mint
        }

        if activeEffects.isEmpty == false {
            return pet.accentColor
        }

        return .orange
    }

    var body: some View {
        GameSurface(title: "디코딩 챔버", accent: stageAccent, eyebrow: "신호 고정") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 16) {
                    ZStack {
                        HatchBurstView(accent: stageAccent, pet: pet, scale: burstScale)

                        Circle()
                            .fill(stageAccent.opacity(energized ? 0.28 : 0.18))
                            .frame(width: 108, height: 108)
                            .blur(radius: 12)

                        Circle()
                            .stroke(stageAccent.opacity(0.72), style: StrokeStyle(lineWidth: 2, dash: [4, 5]))
                            .frame(width: 96, height: 96)
                            .rotationEffect(.degrees(energized ? 12 : -8))

                        if revealPet {
                            PixelPetView(pet: pet, pixelSize: 10)
                                .transition(.scale(scale: 0.86).combined(with: .opacity))
                        } else {
                            TraceEggView(accent: stageAccent, pixelSize: 10, cracked: crackEgg, resonance: energized ? 0.74 : 0.38)
                                .transition(.scale(scale: 1.04).combined(with: .opacity))
                        }
                    }
                    .frame(width: 124, height: 124)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(stageAccent.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(stageAccent.opacity(0.22), lineWidth: 1)
                            )
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text(stageTitle)
                            .font(.title2.weight(.black))
                            .foregroundStyle(.white)

                        Text(variantLabel)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(stageAccent.opacity(0.94))

                        if progress.stageLabel == "Mythic" {
                            Text(mythicTitle)
                                .font(.headline.weight(.black))
                                .foregroundStyle(.orange.opacity(0.96))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }

                        Text(stageDetail)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.74))
                            .lineLimit(2)

                        HStack(spacing: 8) {
                            RunimalSignalBadge(
                                icon: claimableReward != nil ? "gift.fill" : (pet.rareVariant != nil ? "sparkles" : "shield.lefthalf.filled"),
                                label: primaryBadgeLabel,
                                accent: claimableReward != nil ? .green : stageAccent
                            )
                            TraitChip(label: secondaryBadgeLabel, accent: .white.opacity(0.22))
                        }
                    }
                }

                RunimalProgressBar(progress: progress.progressRatio, accent: stageAccent, height: 10)

                HStack(spacing: 12) {
                    RunimalMetricTile(icon: "sparkles", title: "경로", value: variantLabel, accent: stageAccent)
                    RunimalMetricTile(icon: "arrow.up.forward.circle.fill", title: "진화", value: progress.stageLabel, accent: .orange)
                    if progress.stageLabel == "Mythic" {
                        RunimalMetricTile(icon: "crown.fill", title: "칭호", value: mythicTitle, accent: .orange)
                    }
                }

                if activeEffects.isEmpty == false {
                    badgeRail {
                        ForEach(activeEffects.prefix(2)) { effect in
                            RunimalSignalBadge(icon: "shield.lefthalf.filled", label: effect.title, accent: stageAccent.opacity(0.82))
                        }
                        if activeEffects.count > 2 {
                            TraitChip(label: "+\(activeEffects.count - 2)", accent: .white.opacity(0.18))
                        }
                    }
                }

                if let onClaim, claimableReward != nil {
                    Button("주간 보상 받기") {
                        onClaim()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(stageAccent)
                    .fontWeight(.black)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [stageAccent.opacity(0.18), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(alignment: .topTrailing) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(season.title.uppercased())
                    .font(.caption2.weight(.black))
                    .tracking(1.2)
                Text("READY")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.62))
            }
            .foregroundStyle(stageAccent.opacity(0.92))
            .padding(.top, 12)
            .padding(.trailing, 14)
        }
        .onAppear {
            energized = true
            animateBurst()
            startRevealSequence()
        }
        .onChange(of: claimableReward?.id) { _, _ in
            animateBurst()
            startRevealSequence()
            RunimalCuePlayer.playHatchCue(for: pet)
        }
        .onChange(of: progress.stageLabel) { _, _ in
            animateBurst()
            RunimalCuePlayer.playEvolutionCue(for: pet)
        }
        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: energized)
    }

    private func badgeRail<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                content()
            }
            .padding(.horizontal, 1)
        }
    }

    private func animateBurst() {
        burstScale = 0.84
        withAnimation(.spring(response: 0.62, dampingFraction: 0.68)) {
            burstScale = 1.08
        }
    }

    private func startRevealSequence() {
        revealPet = false
        crackEgg = false

        Task {
            try? await Task.sleep(for: .milliseconds(220))
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.24)) {
                    crackEgg = true
                }
            }
            try? await Task.sleep(for: .milliseconds(420))
            await MainActor.run {
                withAnimation(.spring(response: 0.62, dampingFraction: 0.72)) {
                    revealPet = true
                }
            }
        }
    }
}
