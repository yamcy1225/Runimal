import RunimalCore
import SwiftUI

struct PhoneRunCoreDecisionPanel: View {
    let mainSelection: MainCompanionSelection?
    let mainLabel: String
    let availableRuns: [CompletedRunRecord]
    let eggOpportunity: (CompletedRunRecord) -> EggCreationOpportunity
    let onFeedPet: (String) -> Void
    let onForgeEgg: (String) -> Void
    let onIncubateEgg: (String) -> Void

    private var canFeedPet: Bool {
        mainSelection?.kind == .pet
    }

    private var canIncubateEgg: Bool {
        mainSelection?.kind == .egg
    }

    var body: some View {
        GameSurface(title: "러닝 코어 선택") {
            VStack(alignment: .leading, spacing: 12) {
                Text("러닝 코어를 `새 알`로 만들지, 현재 메인 대상을 성장시킬지 선택합니다. 메인 대상은 \(mainLabel)입니다.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.72))

                if availableRuns.isEmpty {
                    Text("선택 가능한 러닝 코어가 없습니다. 워치 러닝을 더 동기화해야 합니다.")
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
                                    Button("메인 펫 성장") {
                                        onFeedPet(run.id)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.green)
                                } else if canIncubateEgg {
                                    Button("메인 알 키우기") {
                                        onIncubateEgg(run.id)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.orange)
                                } else {
                                    Text("먼저 메인 펫이나 알을 선택하세요.")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.62))
                                }
                            }

                            Text(opportunity.eligible ? opportunity.summary : "새 업적을 달성했거나, 슬롯이 모두 비어 있던 상태의 첫 성공 러닝만 알을 남깁니다.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.58))
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
    }
}
