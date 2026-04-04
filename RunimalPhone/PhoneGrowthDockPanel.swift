import RunimalCore
import SwiftUI

struct PhoneGrowthDockPanel: View {
    let activeCompanion: PetCollectionEntry
    let availableRuns: [CompletedRunRecord]
    let feedPreview: (CompletedRunRecord) -> CompanionFeedProjection?
    let onFeed: (String) -> Void

    var body: some View {
        GameSurface(title: "운동 기록 보관함") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 12) {
                    PixelPetView(pet: activeCompanion.pet, pixelSize: 7)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("지금 선택한 동행 · \(activeCompanion.pet.displayName)")
                            .foregroundStyle(.white)
                        Text("아직 쓰지 않은 운동 기록을 이 동행 성장에 나눠 쓸 수 있습니다.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }

                if availableRuns.isEmpty {
                    Text("사용 가능한 운동 기록이 없습니다. 워치 세션을 더 동기화해야 합니다.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.68))
                } else {
                    ForEach(availableRuns.prefix(3)) { run in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .center, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(run.reward.coreLabel)
                                        .foregroundStyle(.white)
                                    Text("\(run.distanceMeters / 1000, format: .number.precision(.fractionLength(2))) km · +\(run.reward.experience) XP")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.72))
                                }

                                Spacer()

                                Button("기록 먹이기") {
                                    onFeed(run.id)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(activeCompanion.pet.accentColor)
                            }

                            if let preview = feedPreview(run) {
                                Text(
                                    preview.potentialExperienceSpent > 0
                                        ? "예상 +\(preview.projectedTotalExperience) XP · 저장 잠재 \(preview.storedPotentialExperience) 중 \(preview.potentialExperienceSpent) XP 사용"
                                        : "예상 +\(preview.projectedTotalExperience) XP · 기록 XP와 일반 보너스만 반영"
                                )
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.74))
                            }
                        }
                    }
                }
            }
        }
    }
}
