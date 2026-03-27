import RunimalCore
import SwiftUI

struct PhoneConflictDiffPanel: View {
    let entries: [SnapshotConflictDiffEntry]

    var body: some View {
        GameSurface(title: "Conflict Diff") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(entries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.label)
                            .foregroundStyle(.white)
                        HStack {
                            TraitChip(label: "local \(entry.localValue)", accent: .cyan.opacity(0.72))
                            TraitChip(label: "cloud \(entry.cloudValue)", accent: .blue.opacity(0.72))
                        }
                    }
                }
            }
        }
    }
}
