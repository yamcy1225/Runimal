import RunimalCore
import SwiftUI

struct PhoneVaultPanel: View {
    let statusLabel: String
    let lastSyncedAt: Date?

    var body: some View {
        GameSurface(title: "Vault Sync") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TraitChip(label: statusLabel, accent: .blue.opacity(0.78))
                    if let lastSyncedAt {
                        TraitChip(
                            label: lastSyncedAt.formatted(date: .omitted, time: .shortened),
                            accent: .white.opacity(0.18)
                        )
                    }
                }

                Text("현재 진행 상황을 복구 가능한 JSON 스냅샷으로 저장합니다. 이후 클라우드 동기화 교체 지점으로 바로 쓸 수 있습니다.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
    }
}
