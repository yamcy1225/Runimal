import RunimalCore
import SwiftUI

struct PhoneSeasonalUnlockPanel: View {
    let unlocks: [SeasonalUnlock]

    var body: some View {
        GameSurface(title: "Season Unlocks") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(unlocks) { unlock in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(unlock.title)
                                .foregroundStyle(.white)
                            Text(unlock.detail)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.72))
                        }
                        Spacer()
                        TraitChip(label: unlock.unlocked ? "UNLOCKED" : "LOCKED", accent: unlock.unlocked ? .green.opacity(0.72) : .white.opacity(0.18))
                    }
                }
            }
        }
    }
}
