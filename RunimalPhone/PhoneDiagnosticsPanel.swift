import RunimalCore
import SwiftUI

struct PhoneDiagnosticsPanel: View {
    let events: [SyncDiagnosticEvent]
    let reachabilityLabel: String
    let activationStateLabel: String
    let queuedTransferCount: Int

    var body: some View {
        GameSurface(title: "Sync Diagnostics") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    TraitChip(label: activationStateLabel, accent: .white.opacity(0.18))
                    TraitChip(label: reachabilityLabel, accent: .green.opacity(0.68))
                    TraitChip(label: "queue \(queuedTransferCount)", accent: .orange.opacity(0.72))
                }

                ForEach(events.prefix(4)) { event in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.title)
                            .foregroundStyle(.white)
                        Text(event.detail)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.68))
                    }
                }
            }
        }
    }
}
