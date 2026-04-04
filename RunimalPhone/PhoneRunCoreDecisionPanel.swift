import RunimalCore
import SwiftUI

struct PhoneRunCoreDecisionPanel: View {
    let mainSelection: MainCompanionSelection?
    let mainLabel: String
    let availableRuns: [CompletedRunRecord]
    let eggOpportunity: (CompletedRunRecord) -> EggCreationOpportunity
    let feedPreview: (CompletedRunRecord) -> CompanionFeedProjection?
    let routingSummary: (CompletedRunRecord) -> PhoneRunCoreRoutingSummary?
    let onFeedPet: (String) -> Void
    let onForgeEgg: (String) -> Void
    let onIncubateEgg: (String) -> Void

    private var canFeedPet: Bool {
        mainSelection?.kind == .pet
    }

    private var canIncubateEgg: Bool {
        mainSelection?.kind == .egg
    }

    private var selectedTargetLabel: String {
        switch mainSelection?.kind {
        case .pet:
            return "지금 선택한 동행"
        case .egg:
            return "지금 선택한 알"
        case .none:
            return "아직 선택하지 않은 대상"
        }
    }

    var body: some View {
        GameSurface(title: "운동 기록 선택") {
            VStack(alignment: .leading, spacing: 12) {
                Text("러닝이 끝나면 운동 데이터는 자동으로 쓰이지 않고 `운동 기록`으로 남습니다. 이 기록은 `새 알 만들기`, `지금 선택한 동행 성장`, 또는 `지금 선택한 알 부화 준비`에 직접 나눠 씁니다.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.72))

                Text("함께 달린 동행은 \(mainLabel)이며, 실시간 반응과 잠재치에만 직접 영향을 줍니다. 운동 기록은 따로 저장됩니다.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.56))

                if availableRuns.isEmpty {
                    Text("선택 가능한 운동 기록이 없습니다. 워치 러닝을 더 동기화해야 합니다.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.68))
                } else {
                    ForEach(availableRuns.prefix(4)) { run in
                        let opportunity = eggOpportunity(run)
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top, spacing: 10) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(run.reward.coreLabel)
                                        .foregroundStyle(.white)
                                    Text("\(run.distanceMeters / 1000, format: .number.precision(.fractionLength(2))) km · +\(run.reward.experience) XP")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                Spacer()
                                TraitChip(label: run.reward.pet.displayName, accent: run.reward.pet.accentColor)
                            }

                            HStack(spacing: 8) {
                                if opportunity.eligible {
                                    Button("알 만들기") {
                                        onForgeEgg(run.id)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(run.reward.pet.accentColor)
                                } else {
                                    RunimalSignalBadge(
                                        icon: "lock.fill",
                                        label: "알 조건 미달",
                                        accent: .white.opacity(0.16)
                                    )
                                }

                                if canFeedPet {
                                    Button("지금 선택한 동행 성장") {
                                        onFeedPet(run.id)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.green)
                                } else if canIncubateEgg {
                                    Button("지금 선택한 알 부화 준비") {
                                        onIncubateEgg(run.id)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.orange)
                                } else {
                                    Text("먼저 동행이나 알을 대표로 선택하세요.")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.62))
                                }
                            }

                            if canFeedPet, let preview = feedPreview(run) {
                                feedPreviewPanel(preview)
                            }

                            if let summary = routingSummary(run) {
                                routingSummaryPanel(summary)
                            }

                            Text(opportunity.eligible ? opportunity.summary : "\(selectedTargetLabel)과는 별개로, 새 업적을 달성했거나 슬롯이 모두 비어 있던 상태의 첫 성공 러닝만 새 알을 남깁니다.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.58))
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
    }

    private func feedPreviewPanel(_ preview: CompanionFeedProjection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(mainLabel) 예상 +\(preview.projectedTotalExperience) XP")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green.opacity(0.92))
                Spacer(minLength: 8)
                if preview.hasPotentialSpend {
                    Text("잠재 \(preview.storedPotentialExperience) 중 \(preview.potentialExperienceSpent)")
                        .font(.caption2.monospaced().weight(.black))
                    .foregroundStyle(.orange.opacity(0.9))
                }
            }

            HStack(spacing: 8) {
                feedBadge("Lv.\(preview.beforeSnapshot.level) -> Lv.\(preview.projectedSnapshot.level)", accent: .green.opacity(0.22))
                if preview.stageAdvanced {
                    feedBadge("\(preview.beforeProgress.stageLabel) -> \(preview.projectedProgress.stageLabel)", accent: .orange.opacity(0.24))
                } else {
                    feedBadge(preview.projectedProgress.stageLabel, accent: .white.opacity(0.14))
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    feedBadge("기본 +\(preview.baseExperience)", accent: .white.opacity(0.16))
                    if preview.supportBonusExperience > 0 {
                        feedBadge("추가 보너스 +\(preview.supportBonusExperience)", accent: .purple.opacity(0.22))
                    }
                    if preview.dataBonusExperience > 0 {
                        feedBadge("기록 밀도 +\(preview.dataBonusExperience)", accent: .cyan.opacity(0.22))
                    }
                    if preview.potentialExperienceSpent > 0 {
                        feedBadge("잠재 사용 +\(preview.potentialExperienceSpent)", accent: .orange.opacity(0.24))
                    }
                }
                .padding(.horizontal, 1)
            }

            if let nextMilestone = preview.projectedSnapshot.nextEvolutionMilestone {
                Text("다음 진화 기준은 Lv.\(nextMilestone.requiredLevel) · \(nextMilestone.requiredExperience) XP입니다.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.58))
            } else if let nextLateGrowth = preview.projectedSnapshot.lateGrowthWindow.last,
                      preview.projectedSnapshot.level < nextLateGrowth.requiredLevel {
                Text("다음 후반 해금은 Lv.\(nextLateGrowth.requiredLevel) \(nextLateGrowth.title)입니다.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.58))
            }

            Text(
                preview.potentialExperienceSpent > 0
                    ? "이번 반영 후 저장 잠재 \(preview.projectedRemainingStoredPotentialExperience) XP가 남습니다."
                    : "이번에는 저장 잠재를 쓰지 않고 기록 XP만 반영합니다."
            )
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.58))
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func routingSummaryPanel(_ summary: PhoneRunCoreRoutingSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(summary.title)
                    .font(.caption.monospaced().weight(.black))
                    .foregroundStyle(.white.opacity(0.88))
                Spacer()
                Rectangle()
                    .fill(summary.accent.opacity(0.84))
                    .frame(width: 14, height: 4)
            }

            Text(summary.headline)
                .font(.caption.monospaced().weight(.black))
                .foregroundStyle(.white)

            Text(summary.detail)
                .font(.caption2.monospaced())
                .foregroundStyle(.white.opacity(0.66))
                .lineSpacing(2)

            if summary.badges.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(summary.badges, id: \.self) { badge in
                            feedBadge(badge, accent: summary.accent.opacity(0.22))
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(summary.accent.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func feedBadge(_ label: String, accent: Color) -> some View {
        Text(label)
            .font(.caption2.monospaced().weight(.black))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(accent)
            )
    }
}
