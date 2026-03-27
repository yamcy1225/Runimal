import RunimalCore
import SwiftUI

struct PhoneGrowthDockPanel: View {
    let activeCompanion: PetCollectionEntry
    let availableRuns: [CompletedRunRecord]
    let onFeed: (String) -> Void

    var body: some View {
        GameSurface(title: "Growth Core Dock") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 12) {
                    PixelPetView(pet: activeCompanion.pet, pixelSize: 7)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Active slot · \(activeCompanion.pet.displayName)")
                            .foregroundStyle(.white)
                        Text("이 펫에게 아직 소모되지 않은 러닝 코어를 먹일 수 있습니다.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }

                if availableRuns.isEmpty {
                    Text("사용 가능한 Run Core가 없습니다. 워치 세션을 더 동기화해야 합니다.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.68))
                } else {
                    ForEach(availableRuns.prefix(3)) { run in
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(run.reward.coreLabel)
                                    .foregroundStyle(.white)
                                Text("\(run.distanceMeters / 1000, format: .number.precision(.fractionLength(2))) km · +\(run.reward.experience) XP")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.72))
                            }

                            Spacer()

                            Button("Feed Active") {
                                onFeed(run.id)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(activeCompanion.pet.accentColor)
                        }
                    }
                }
            }
        }
    }
}
