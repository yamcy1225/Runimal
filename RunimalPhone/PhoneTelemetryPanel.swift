import SwiftUI

struct PhoneTelemetryPanel: View {
    let lastEventLabel: String
    let eventCount: Int
    let logPath: String

    var body: some View {
        GameSurface(title: "Telemetry") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TraitChip(label: "\(eventCount) events", accent: .blue.opacity(0.76))
                }

                Text(lastEventLabel)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))

                Text(logPath)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.white.opacity(0.52))
                    .lineLimit(2)
            }
        }
    }
}
