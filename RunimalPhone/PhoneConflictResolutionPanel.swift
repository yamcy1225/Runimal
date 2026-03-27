import RunimalCore
import SwiftUI

struct PhoneConflictResolutionPanel: View {
    let report: SnapshotConflictReport
    let selectedPolicy: SnapshotConflictPolicy
    let onSelect: (SnapshotConflictPolicy) -> Void
    let onApply: () -> Void

    var body: some View {
        GameSurface(title: "Conflict Resolution") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    TraitChip(label: report.title, accent: report.hasConflict ? .red.opacity(0.72) : .green.opacity(0.72))
                    TraitChip(label: "rec \(report.recommendedPolicy.rawValue)", accent: .white.opacity(0.18))
                }

                Text(report.detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))

                HStack {
                    TraitChip(label: "local runs \(report.localRunCount)", accent: .cyan.opacity(0.72))
                    TraitChip(label: "cloud runs \(report.cloudRunCount)", accent: .blue.opacity(0.72))
                }

                HStack {
                    ForEach(SnapshotConflictPolicy.allCases, id: \.self) { policy in
                        Button(policy.rawValue) {
                            onSelect(policy)
                        }
                        .buttonStyle(.bordered)
                        .tint(policy == selectedPolicy ? .orange.opacity(0.82) : .white.opacity(0.2))
                    }
                }

                Button("Apply Conflict Policy") {
                    onApply()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange.opacity(0.82))
            }
        }
    }
}
