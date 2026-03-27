import RunimalCore
import SwiftUI

struct PhoneCloudMirrorPanel: View {
    let statusLabel: String
    let lastMirroredAt: Date?

    var body: some View {
        GameSurface(title: "Cloud Mirror") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TraitChip(label: statusLabel, accent: .cyan.opacity(0.78))
                    if let lastMirroredAt {
                        TraitChip(
                            label: lastMirroredAt.formatted(date: .omitted, time: .shortened),
                            accent: .white.opacity(0.18)
                        )
                    }
                }

                Text("iCloud key-value mirror 경로에 최신 스냅샷을 복제합니다. 실환경에서는 Apple 계정/entitlement가 있어야 기기간 반영됩니다.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
    }
}
