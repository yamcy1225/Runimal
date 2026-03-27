import Foundation
import Observation
import RunimalCore
import SwiftUI

@MainActor
@Observable
final class MacDeviceQAStore {
    var status = "QA export idle"

    func exportChecklist(_ checklist: [DeviceQACheckItem]) {
        let lines = checklist.map { "\($0.title)\n\($0.detail)" }.joined(separator: "\n\n")

        do {
            try lines.write(to: RunimalPaths.repoRoot.appendingPathComponent("docs/device-qa-export.txt"), atomically: true, encoding: .utf8)
            status = "Checklist exported"
        } catch {
            status = "Export failed"
        }
    }
}

struct MacDeviceQAPanel: View {
    let checklist: [DeviceQACheckItem]
    @State private var store = MacDeviceQAStore()

    var body: some View {
        GameSurface(title: "Device QA Checklist") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    TraitChip(label: store.status, accent: .white.opacity(0.18))
                    Spacer()
                    Button("Export QA Report") {
                        store.exportChecklist(checklist)
                    }
                    .buttonStyle(.bordered)
                }

                ForEach(checklist) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .foregroundStyle(.white)
                        Text(item.detail)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }
            }
        }
    }
}
