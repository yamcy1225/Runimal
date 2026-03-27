import RunimalCore
import SwiftUI

struct PhoneSelectiveMergePanel: View {
    let candidates: [MergeCandidate]
    let onImport: (String, String) -> Void

    var body: some View {
        GameSurface(title: "Selective Merge") {
            VStack(alignment: .leading, spacing: 10) {
                if candidates.isEmpty {
                    Text("No cloud-only records found.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                } else {
                    ForEach(candidates.prefix(4)) { candidate in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(candidate.label)
                                    .foregroundStyle(.white)
                                Text("\(candidate.source) · \(candidate.type)")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.66))
                            }
                            Spacer()
                            Button("Import") {
                                onImport(candidate.id, candidate.type)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
        }
    }
}
