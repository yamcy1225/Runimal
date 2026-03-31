import RunimalCore
import SwiftUI

struct PhonePetDetailPanel: View {
    let companion: PetCollectionEntry
    let mutationForm: MutationFormSnapshot?
    let mutationHistory: MutationHistorySnapshot?
    let progress: EvolutionProgress
    let activeEffects: [WeeklyRewardEffect]
    let season: WeeklySeason
    @State private var showMutationDetails = false

    private var tree: [EvolutionTreeNode] {
        RunimalGameEngine.evolutionTree(for: companion.pet, progress: progress, season: season)
    }

    private var tuningNotes: [String] {
        RunimalGameEngine.balanceTuningNotes(for: companion.pet)
    }

    private var effectResonance: [CompanionEffectResonance] {
        RunimalEffectResonanceEngine.effectResonance(
            for: companion,
            progress: progress,
            activeEffects: activeEffects
        )
    }

    var body: some View {
        GameSurface(title: "동행체 정보") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 16) {
                    PixelPetView(
                        pet: companion.pet,
                        pixelSize: 10,
                        mutationForm: mutationForm,
                        mutationHistory: mutationHistory
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text(companion.pet.displayName)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(companion.pet.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.72))
                        if let mutationForm {
                            Text(mutationForm.displayTitle)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(companion.pet.accentColor.opacity(0.92))
                        }
                        HStack {
                            TraitChip(label: "Lv.\(companion.level)", accent: companion.pet.accentColor)
                            TraitChip(label: "유대 \(companion.bond)", accent: .white.opacity(0.22))
                            if RunimalGameEngine.seasonAffinity(for: companion.pet, season: season) {
                                TraitChip(label: season.title, accent: .mint.opacity(0.7))
                            }
                        }
                    }
                }

                if let mutationHistory {
                    DisclosureGroup(isExpanded: $showMutationDetails) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(mutationHistory.latestUnlockedDisplayTitle)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(companion.pet.accentColor.opacity(0.92))

                            ForEach(mutationHistory.axes) { axis in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Text(axisTitle(axis.axis))
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.white.opacity(0.74))
                                        TraitChip(label: axis.currentTitle, accent: companion.pet.accentColor.opacity(0.82))
                                        Spacer()
                                        Text(progressLabel(axis.currentProgress))
                                            .font(.caption2.monospacedDigit().weight(.semibold))
                                            .foregroundStyle(.white.opacity(0.54))
                                    }

                                    ProgressView(value: axis.currentProgress)
                                        .tint(companion.pet.accentColor.opacity(0.82))
                                        .background(.white.opacity(0.08))

                                    HStack(spacing: 8) {
                                        Text("누적")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(.white.opacity(0.45))
                                        Text("\(axis.currentScore)pt")
                                            .font(.caption2.monospacedDigit())
                                            .foregroundStyle(.white.opacity(0.54))
                                    }

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 6) {
                                            ForEach(axis.branches) { branch in
                                                TraitChip(
                                                    label: branch.title,
                                                    accent: branchAccent(
                                                        branch: branch
                                                    )
                                                )
                                            }
                                        }
                                    }

                                    if let lockedBranch = nextLockedBranch(
                                        for: axis.axis,
                                        speciesID: mutationHistory.speciesID,
                                        unlockedBranchIDs: axis.unlockedBranchIDs
                                    ) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "lock.fill")
                                                .font(.caption2)
                                                .foregroundStyle(.white.opacity(0.45))
                                            Text(lockedBranch.unlockCue)
                                                .font(.caption2)
                                                .foregroundStyle(.white.opacity(0.52))
                                                .lineLimit(1)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)
                    } label: {
                        HStack {
                            Text("변이 계보")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Spacer()
                            Text(showMutationDetails ? "접기" : "보기")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .tint(.white)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("진화 경로")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)

                    ForEach(tree) { node in
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(node.current ? companion.pet.accentColor : (node.unlocked ? .green : .white.opacity(0.16)))
                                .frame(width: 10, height: 10)
                                .padding(.top, 5)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(node.title)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    TraitChip(label: node.status.uppercased(), accent: node.current ? companion.pet.accentColor : .white.opacity(0.18))
                                }

                                Text(node.detail)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.72))
                            }
                        }
                    }
                }

                if activeEffects.isEmpty == false {
                    Divider()
                        .overlay(.white.opacity(0.12))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("효과 연결")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)

                        ForEach(effectResonance) { effect in
                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text(effect.title)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    TraitChip(label: effect.intensityLabel, accent: companion.pet.accentColor.opacity(0.82))
                                }

                                Text(effect.detail)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.72))
                            }
                        }
                    }
                }

                Divider()
                    .overlay(.white.opacity(0.12))

                VStack(alignment: .leading, spacing: 8) {
                    Text("성장 힌트")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)

                    ForEach(tuningNotes, id: \.self) { note in
                        Text(note)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                    }

                    if RunimalGameEngine.seasonAffinity(for: companion.pet, season: season) {
                        Text("시즌 전용 진화명 \(season.evolutionTitle)과 보상 \(season.rewardTitle)이 이 펫에게 연결됩니다.")
                            .font(.caption)
                            .foregroundStyle(.mint.opacity(0.84))
                    }
                }
            }
        }
    }

    private func axisTitle(_ axis: SpeciesLineageAxis) -> String {
        switch axis {
        case .body:
            return "체형"
        case .ecology:
            return "생태"
        case .rhythm:
            return "리듬"
        }
    }

    private func branchAccent(
        branch: MutationBranchProgressSnapshot
    ) -> Color {
        if branch.isCurrent {
            return companion.pet.accentColor.opacity(0.82)
        }
        if branch.isUnlocked {
            return .white.opacity(0.18)
        }
        return .white.opacity(0.08)
    }

    private func nextLockedBranch(
        for axis: SpeciesLineageAxis,
        speciesID: String,
        unlockedBranchIDs: [String]
    ) -> SpeciesLineageBranchBlueprint? {
        guard let blueprint = DefaultSpeciesExpansionBlueprints.baseSpeciesBlueprints.first(where: { $0.speciesID == speciesID }) else {
            return nil
        }

        let branches: [SpeciesLineageBranchBlueprint]
        switch axis {
        case .body:
            branches = blueprint.bodyBranches
        case .ecology:
            branches = blueprint.ecologyBranches
        case .rhythm:
            branches = blueprint.rhythmBranches
        }

        return branches.first(where: { unlockedBranchIDs.contains($0.id) == false })
    }

    private func progressLabel(_ progress: Double) -> String {
        "\(Int((progress * 100).rounded()))%"
    }
}
