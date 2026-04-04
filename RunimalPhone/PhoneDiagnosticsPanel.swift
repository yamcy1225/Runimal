import RunimalCore
import SwiftUI

struct PhoneDiagnosticsPanel: View {
    let events: [SyncDiagnosticEvent]
    let reachabilityLabel: String
    let activationStateLabel: String
    let queuedTransferCount: Int
    let lastMessage: String
    let lastInboundRoute: String
    let lastInboundPayloadKeys: [String]

    var body: some View {
        GameSurface(title: "워치 동기화 로그") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    TraitChip(label: activationStateLabel, accent: .white.opacity(0.18))
                    TraitChip(label: reachabilityLabel, accent: .green.opacity(0.68))
                    TraitChip(label: "queue \(queuedTransferCount)", accent: .orange.opacity(0.72))
                    if lastInboundRoute != "none" {
                        TraitChip(label: lastInboundRoute, accent: .cyan.opacity(0.72))
                    }
                }

                Text(lastMessage)
                    .font(.footnote.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.darkest)

                if lastInboundPayloadKeys.isEmpty == false {
                    Text(lastInboundPayloadKeys.joined(separator: ", "))
                        .font(.caption2.monospaced())
                        .foregroundStyle(GameBoyPalette.mediumDark)
                        .lineLimit(2)
                }

                ForEach(events.prefix(5)) { event in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(event.timestamp.formatted(date: .omitted, time: .shortened))
                                .font(.caption2.monospaced().weight(.black))
                                .foregroundStyle(GameBoyPalette.mediumDark)
                            Text(event.title)
                                .font(.footnote.monospaced().weight(.black))
                                .foregroundStyle(GameBoyPalette.darkest)
                        }
                        Text(event.detail)
                            .font(.caption2.monospaced())
                            .foregroundStyle(GameBoyPalette.mediumDark)
                    }
                }
            }
        }
    }
}
