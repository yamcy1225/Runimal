import RunimalCore
import SwiftUI

struct PhoneRecordDiffPanel: View {
    let choices: [RecordDiffChoice]
    let onUseLocal: (String, String) -> Void
    let onUseCloud: (String, String) -> Void

    var body: some View {
        GameSurface(title: "Record Diff Editor") {
            VStack(alignment: .leading, spacing: 10) {
                if choices.isEmpty {
                    Text("No duplicate record conflicts detected.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                } else {
                    ForEach(choices.prefix(4)) { choice in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(choice.title)
                                .foregroundStyle(.white)
                            HStack {
                                TraitChip(label: choice.localLabel, accent: .cyan.opacity(0.72))
                                TraitChip(label: choice.cloudLabel, accent: .blue.opacity(0.72))
                            }
                            HStack {
                                Button("Use Local") {
                                    onUseLocal(choice.id, choice.type)
                                }
                                .buttonStyle(.bordered)

                                Button("Use Cloud") {
                                    onUseCloud(choice.id, choice.type)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.blue.opacity(0.82))
                            }
                        }
                    }
                }
            }
        }
    }
}
