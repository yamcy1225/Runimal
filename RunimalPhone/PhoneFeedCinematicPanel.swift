import RunimalCore
import SwiftUI

struct PhoneFeedCinematicPanel: View {
    let pet: GeneratedPet
    let outcome: CompanionFeedOutcome
    let season: WeeklySeason
    let renderState: CompanionPixelRenderState
    let onDismiss: () -> Void

    @State private var shownProgress = 0.0
    @State private var xpScale: CGFloat = 0.86
    @State private var glow = false
    @State private var showEvolutionCut = false

    private var accent: Color {
        outcome.stageAdvanced ? .orange : pet.accentColor
    }

    private var mythicReached: Bool {
        outcome.stageAdvanced && outcome.afterProgress.stageLabel == RunimalBalanceConfig.finalStageLabel
    }

    private var mythicTitle: String {
        RunimalGameEngine.mythicTitle(for: pet)
    }

    private var stageHeadline: String {
        if mythicReached {
            return "성년기 도달"
        }

        return outcome.stageAdvanced
            ? "\(outcome.afterProgress.stageLabel) 단계 도달"
            : "성장 반영 완료"
    }

    private var momentNarrative: CompanionMomentNarrative {
        RunimalGameEngine.growthMomentNarrative(pet: pet, outcome: outcome)
    }

    private var followUpTarget: EvolutionTarget {
        RunimalGameEngine.postGrowthTarget(
            pet: pet,
            outcome: outcome,
            season: season
        )
    }

    var body: some View {
        GameSurface(title: "성장 연출", accent: accent, eyebrow: "기록 반영") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 16) {
                    ZStack {
                        HatchBurstView(accent: accent, pet: pet, scale: glow ? 1.08 : 0.9)

                        Circle()
                            .fill(accent.opacity(glow ? 0.28 : 0.16))
                            .frame(width: 110, height: 110)
                            .blur(radius: 14)

                        PixelPetView(
                            pet: pet,
                            pixelSize: 10,
                            growthStageIndex: renderState.growthStageIndex,
                            mutationForm: renderState.mutationForm,
                            mutationHistory: renderState.mutationHistory,
                            mutationVisualState: renderState.mutationVisualState
                        )

                        if showEvolutionCut {
                            Text(mythicReached ? "성년기" : "성장")
                                .font(.caption.weight(.black))
                                .tracking(1.8)
                                .foregroundStyle(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(.white.opacity(0.92)))
                                .offset(y: -56)
                                .transition(.scale.combined(with: .opacity))
                        }

                        Text("+\(outcome.gainedExperience) XP")
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(accent.opacity(0.88)))
                            .scaleEffect(xpScale)
                            .offset(y: 56)
                    }
                    .frame(width: 132, height: 132)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(stageHeadline)
                            .font(.title3.weight(.black))
                            .foregroundStyle(.white)

                        Text("\(outcome.coreLabel)을 반영해 Lv.\(outcome.beforeSnapshot.level)에서 Lv.\(outcome.afterSnapshot.level), \(outcome.beforeProgress.totalExperience) XP에서 \(outcome.afterProgress.totalExperience) XP로 올랐습니다.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.76))

                        HStack {
                            TraitChip(label: "Lv.\(outcome.beforeSnapshot.level)", accent: .white.opacity(0.14))
                            TraitChip(label: outcome.beforeProgress.stageLabel, accent: .white.opacity(0.2))
                            Image(systemName: "arrow.right")
                                .foregroundStyle(.white.opacity(0.45))
                            TraitChip(label: "Lv.\(outcome.afterSnapshot.level)", accent: accent.opacity(0.22))
                            TraitChip(label: outcome.afterProgress.stageLabel, accent: accent)
                            if outcome.stageAdvanced {
                                TraitChip(label: mythicReached ? mythicTitle : "연출 발동", accent: .orange.opacity(0.82))
                            }
                        }

                        if mythicReached {
                            Text(RunimalGameEngine.mythicSignalLine(for: pet))
                                .font(.caption)
                                .foregroundStyle(.orange.opacity(0.86))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(momentNarrative.title)
                                .font(.caption.weight(.black))
                                .foregroundStyle(.white.opacity(0.9))

                            Text(momentNarrative.detail)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.72))
                                .lineSpacing(2)

                            HStack(spacing: 8) {
                                Text(momentNarrative.emphasis)
                                    .font(.caption2.monospaced().weight(.black))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(.white.opacity(0.92)))

                                ForEach(Array(momentNarrative.badges.prefix(2)), id: \.self) { badge in
                                    breakdownChip(badge, accent: .white.opacity(0.14))
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("진화 게이지")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.72))

                    RunimalProgressBar(progress: shownProgress, accent: accent, height: 12)

                    Text(outcome.afterProgress.headline)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.72))

                    if outcome.potentialExperienceSpent > 0 {
                        Text(
                            outcome.remainingStoredPotentialExperience > 0
                                ? "저장 잠재 \(outcome.potentialExperienceSpent) XP 사용 · \(outcome.remainingStoredPotentialExperience) XP 남음"
                                : "저장 잠재 \(outcome.potentialExperienceSpent) XP 모두 사용"
                        )
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange.opacity(0.92))
                    }

                    if !outcome.bonusLabels.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(outcome.bonusLabels, id: \.self) { bonus in
                                    RunimalSignalBadge(icon: "bolt.fill", label: bonus, accent: accent.opacity(0.84))
                                }
                            }
                            .padding(.horizontal, 1)
                        }
                    }

                    growthBreakdownCard
                    followUpCard
                }
            }
        }
        .onAppear {
            startSequence()
        }
        .onChange(of: outcome.runID) { _, _ in
            startSequence()
        }
    }

    private func startSequence() {
        shownProgress = outcome.beforeProgress.progressRatio
        xpScale = 0.72
        glow = false
        showEvolutionCut = false

        Task {
            await MainActor.run {
                RunimalCuePlayer.playHatchCue(for: pet)
                withAnimation(.spring(response: 0.42, dampingFraction: 0.62)) {
                    xpScale = 1.04
                    glow = true
                }
            }

            try? await Task.sleep(for: .milliseconds(180))

            await MainActor.run {
                withAnimation(.easeInOut(duration: 1.0)) {
                    shownProgress = outcome.afterProgress.progressRatio
                }
            }

            if outcome.stageAdvanced {
                try? await Task.sleep(for: .milliseconds(520))
                await MainActor.run {
                    RunimalCuePlayer.playEvolutionCue(for: pet)
                    withAnimation(.spring(response: 0.48, dampingFraction: 0.68)) {
                        showEvolutionCut = true
                    }
                }
            }

            try? await Task.sleep(for: .seconds(outcome.stageAdvanced ? 3.6 : 2.8))
            await MainActor.run {
                onDismiss()
            }
        }
    }

    private var growthBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("이번 반영")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.72))

            HStack(spacing: 8) {
                breakdownChip("기본 +\(outcome.baseExperience)", accent: .white.opacity(0.16))
                if outcome.supportBonusExperience > 0 {
                    breakdownChip("추가 보너스 +\(outcome.supportBonusExperience)", accent: .purple.opacity(0.24))
                }
                if outcome.dataBonusExperience > 0 {
                    breakdownChip("기록 밀도 +\(outcome.dataBonusExperience)", accent: .cyan.opacity(0.24))
                }
                if outcome.potentialExperienceSpent > 0 {
                    breakdownChip("잠재 +\(outcome.potentialExperienceSpent)", accent: .orange.opacity(0.26))
                }
            }

            Text(
                outcome.potentialExperienceSpent > 0
                    ? "저장 잠재 \(outcome.storedPotentialExperienceBefore) XP 중 \(outcome.potentialExperienceSpent) XP를 이번에 사용했습니다."
                    : "이번 반영은 기록 XP와 일반 보너스만으로 진행됐습니다."
            )
            .font(.caption)
            .foregroundStyle(.white.opacity(0.72))

            if let nextMilestone = outcome.afterSnapshot.nextEvolutionMilestone {
                Text("다음 진화 기준은 Lv.\(nextMilestone.requiredLevel) · \(nextMilestone.requiredExperience) XP입니다.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.58))
            } else if let nextLateGrowth = outcome.afterSnapshot.lateGrowthWindow.last,
                      outcome.afterSnapshot.level < nextLateGrowth.requiredLevel {
                Text("다음 후반 해금은 Lv.\(nextLateGrowth.requiredLevel) \(nextLateGrowth.title)입니다.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.58))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private var followUpCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("다음 진행")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.72))

            Text(followUpTarget.title)
                .font(.headline.weight(.black))
                .foregroundStyle(.white)

            Text(followUpTarget.detail)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
                .lineSpacing(2)

            guidanceRow(title: followUpTarget.focusTitle, detail: followUpTarget.focusDetail)
            guidanceRow(title: followUpTarget.actionTitle, detail: followUpTarget.actionDetail)
            guidanceRow(title: followUpTarget.checkpointTitle, detail: followUpTarget.checkpointDetail)

            if followUpTarget.badges.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(followUpTarget.badges, id: \.self) { badge in
                            breakdownChip(badge, accent: accent.opacity(0.22))
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func guidanceRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.black))
                .foregroundStyle(accent.opacity(0.94))
            Text(detail)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.74))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func breakdownChip(_ title: String, accent: Color) -> some View {
        Text(title)
            .font(.caption2.monospaced().weight(.black))
            .foregroundStyle(.white.opacity(0.92))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(accent)
            )
    }
}
