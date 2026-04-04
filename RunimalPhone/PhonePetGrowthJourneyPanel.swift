import RunimalCore
import SwiftUI

struct PhonePetGrowthJourneyPanel: View {
    let companion: PetCollectionEntry
    let mutationForm: MutationFormSnapshot?
    let mutationHistory: MutationHistorySnapshot?
    let progress: EvolutionProgress
    let season: WeeklySeason
    let toneLines: [String]
    @State private var showGrowthJourney = false

    private var tree: [EvolutionTreeNode] {
        RunimalGameEngine.evolutionTree(for: companion.pet, progress: progress, season: season)
    }

    private var progressionSnapshot: CompanionProgressionSnapshot {
        let growthRecord = CompanionGrowthRecord(
            companionID: companion.id,
            totalExperience: progress.totalExperience,
            feedCount: 0,
            assignedRunIDs: [],
            lastFedAt: nil
        )
        return RunimalCompanionGrowthEngine.progressionSnapshot(for: growthRecord, species: companion.pet.species)
    }

    private var currentStageIndex: Int {
        progressionSnapshot.stageIndex
    }

    private var stageUnlockWindow: [CompanionStageUnlock] {
        progressionSnapshot.stageUnlockWindow
    }

    private var evolutionMilestones: [CompanionEvolutionMilestone] {
        progressionSnapshot.evolutionMilestones
    }

    private var nextMilestone: CompanionEvolutionMilestone? {
        progressionSnapshot.nextEvolutionMilestone
    }

    private var lateGrowthWindow: [CompanionLateGrowthMilestone] {
        progressionSnapshot.lateGrowthWindow
    }

    var body: some View {
        DisclosureGroup(isExpanded: $showGrowthJourney) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    TraitChip(label: playerFacingStageLabel(currentStageIndex), accent: companion.pet.accentColor.opacity(0.86))
                    TraitChip(label: "XP \(progress.totalExperience)", accent: .white.opacity(0.16))
                    if let nextMilestone {
                        TraitChip(label: "다음 Lv.\(nextMilestone.requiredLevel)", accent: .mint.opacity(0.26))
                    }
                }

                if toneLines.isEmpty == false {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(toneLines, id: \.self) { line in
                            Text(line)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.72))
                                .lineLimit(2)
                        }
                    }
                }

                if let summary = progressionSnapshot.evolutionSummary {
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.68))
                        .lineLimit(2)
                }

                if stageUnlockWindow.isEmpty == false {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(stageUnlockWindow.enumerated()), id: \.element.id) { offset, unlock in
                            stageUnlockCard(
                                unlock: unlock,
                                isCurrent: offset == 0
                            )
                        }
                    }
                }

                if currentStageIndex == RunimalBalanceConfig.evolutionStageLabels.count - 1,
                   lateGrowthWindow.isEmpty == false {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("성년기 이후")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.6))

                        ForEach(Array(lateGrowthWindow.enumerated()), id: \.element.id) { offset, milestone in
                            lateGrowthCard(
                                milestone: milestone,
                                isUnlocked: companion.level >= milestone.requiredLevel,
                                isCurrent: offset == 0 && companion.level >= milestone.requiredLevel
                            )
                        }
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .center, spacing: 0) {
                        ForEach(Array(tree.enumerated()), id: \.element.id) { index, node in
                            growthStageCard(node: node, index: index)
                            if index < tree.count - 1 {
                                growthConnector(current: node, next: tree[index + 1])
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(.top, 8)
        } label: {
            HStack {
                Text("성장 과정")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text(showGrowthJourney ? "접기" : "보기")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .tint(.white)
    }

    private func growthStageCard(node: EvolutionTreeNode, index: Int) -> some View {
        let stageBlueprint = DefaultSpeciesVisualBlueprints.growthStage(for: companion.pet.species, stageIndex: index)
        let branchBridges = SpeciesGrowthMutationBridgeEngine.bridge(for: companion.pet.species, form: mutationForm)
            .filter { $0.startStageIndex == index }
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(String(format: "%02d", index + 1))
                    .font(.caption.monospacedDigit().weight(.black))
                    .foregroundStyle(.white.opacity(0.54))
                Spacer()
                TraitChip(label: growthStatusLabel(node), accent: growthAccent(node).opacity(node.current ? 0.92 : 0.28))
            }

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(node.current ? 0.14 : 0.07))

                if index == 0 {
                    TraceEggView(
                        accent: companion.pet.accentColor,
                        pixelSize: 6.8,
                        cracked: false,
                        resonance: node.current ? 0.82 : 0.34
                    )
                } else {
                    PixelPetView(
                        pet: companion.pet,
                        pixelSize: 7.2,
                        growthStageIndex: index,
                        mutationForm: node.unlocked ? mutationForm : nil,
                        mutationHistory: node.unlocked ? mutationHistory : nil
                    )
                    .opacity(node.unlocked ? 1 : 0.5)
                    .scaleEffect(node.current ? 1.02 : 0.94)
                }
            }
            .frame(height: 96)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(growthAccent(node).opacity(node.current ? 0.92 : 0.34), lineWidth: node.current ? 2.4 : 1.2)
            )

            VStack(alignment: .leading, spacing: 5) {
                Text(playerFacingStageLabel(index))
                    .font(.subheadline.monospaced().weight(.black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(stageNarrative(node: node, index: index))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                if let unlock = RunimalBalanceConfig.companionStageUnlock(at: index) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(unlock.unlockedFeatures.prefix(2), id: \.self) { feature in
                                TraitChip(label: feature, accent: companion.pet.accentColor.opacity(0.18))
                            }
                        }
                    }
                }

                if let stageBlueprint {
                    Text(stageBlueprint.growthLine)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.54))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(stageBlueprint.developedParts) { part in
                                TraitChip(label: part.title, accent: companion.pet.accentColor.opacity(0.2))
                            }
                        }
                    }
                }

                if branchBridges.isEmpty == false {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(branchBridges) { bridge in
                            HStack(spacing: 6) {
                                TraitChip(label: axisLabel(bridge.axis), accent: companion.pet.accentColor.opacity(0.22))
                                Text("여기서 갈래가 꺾여요")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(bridge.inheritedParts) { part in
                                        TraitChip(label: part.title, accent: .mint.opacity(0.2))
                                    }
                                    ForEach(bridge.redirectedParts) { part in
                                        TraitChip(label: part.title, accent: .cyan.opacity(0.18))
                                    }
                                }
                            }
                        }
                    }
                }

                Text(thresholdLabel(for: index))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(12)
        .frame(width: 188)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(node.current ? 0.08 : 0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(node.current ? 0.18 : 0.08), lineWidth: 1)
        )
    }

    private func growthConnector(current: EvolutionTreeNode, next: EvolutionTreeNode) -> some View {
        VStack(spacing: 8) {
            Capsule()
                .fill((current.unlocked && next.unlocked) ? companion.pet.accentColor.opacity(0.78) : .white.opacity(0.14))
                .frame(width: 34, height: 3)

            Image(systemName: "arrow.right")
                .font(.caption.weight(.black))
                .foregroundStyle((current.unlocked && next.unlocked) ? companion.pet.accentColor.opacity(0.88) : .white.opacity(0.32))
        }
        .frame(width: 34)
        .padding(.horizontal, 4)
    }

    private func growthAccent(_ node: EvolutionTreeNode) -> Color {
        if node.current { return companion.pet.accentColor }
        if node.unlocked { return .green }
        return .white
    }

    private func growthStatusLabel(_ node: EvolutionTreeNode) -> String {
        if node.current { return "현재" }
        if node.unlocked { return "완료" }
        return "잠김"
    }

    private func thresholdLabel(for index: Int) -> String {
        guard evolutionMilestones.indices.contains(index) else { return "완성된 형태" }
        if index == evolutionMilestones.count - 1 {
            let target = evolutionMilestones[index]
            return "도달 기준 Lv.\(target.requiredLevel) · \(target.requiredExperience) XP"
        }

        let next = evolutionMilestones[index + 1]
        return "\(next.stageLabel) Lv.\(next.requiredLevel) · \(next.requiredExperience) XP"
    }

    private func playerFacingStageLabel(_ index: Int) -> String {
        RunimalBalanceConfig.companionStageUnlock(at: index)?.stageLabel ?? RunimalBalanceConfig.finalStageLabel
    }

    private func axisLabel(_ axis: SpeciesLineageAxis) -> String {
        switch axis {
        case .body: return "체형"
        case .ecology: return "생태"
        case .rhythm: return "리듬"
        }
    }

    private func stageNarrative(node: EvolutionTreeNode, index: Int) -> String {
        if let summary = RunimalBalanceConfig.companionStageUnlock(at: index)?.summary {
            return summary
        }
        return node.detail.replacingOccurrences(of: "최종 형태", with: "고유한 완성")
    }

    private func stageUnlockCard(unlock: CompanionStageUnlock, isCurrent: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(isCurrent ? "지금 열리는 것" : "다음에 열리는 것")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                TraitChip(
                    label: unlock.stageLabel,
                    accent: isCurrent ? companion.pet.accentColor.opacity(0.84) : .white.opacity(0.16)
                )
            }

            Text(unlock.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            Text(unlock.summary)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(unlock.unlockedFeatures, id: \.self) { feature in
                        TraitChip(
                            label: feature,
                            accent: isCurrent ? companion.pet.accentColor.opacity(0.2) : .white.opacity(0.12)
                        )
                    }
                }
            }

            Text(unlock.nextFocus)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.52))
                .lineLimit(2)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(isCurrent ? 0.08 : 0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isCurrent ? companion.pet.accentColor.opacity(0.24) : .white.opacity(0.08),
                    lineWidth: 1
                )
        )
    }

    private func lateGrowthCard(
        milestone: CompanionLateGrowthMilestone,
        isUnlocked: Bool,
        isCurrent: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(isUnlocked ? "지금 열려 있는 후반 해금" : "다음 후반 해금")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                TraitChip(
                    label: "Lv.\(milestone.requiredLevel)",
                    accent: isUnlocked ? companion.pet.accentColor.opacity(0.84) : .white.opacity(0.16)
                )
            }

            Text(milestone.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            Text(milestone.summary)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(milestone.unlockedFeatures, id: \.self) { feature in
                        TraitChip(
                            label: feature,
                            accent: isUnlocked ? companion.pet.accentColor.opacity(0.2) : .white.opacity(0.12)
                        )
                    }
                }
            }

            Text(isUnlocked ? "현재 후반 보너스에 반영됩니다." : "도달하면 후반 성장 루프가 더 또렷해져요.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.52))
                .lineLimit(2)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(isCurrent ? 0.08 : 0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isUnlocked ? companion.pet.accentColor.opacity(0.24) : .white.opacity(0.08),
                    lineWidth: 1
                )
        )
    }
}
