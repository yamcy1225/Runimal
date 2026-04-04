import SwiftUI

struct PhoneLaunchTelemetryPanel: View {
    let telemetry: PhoneTelemetryLogger
    @State private var shareURL: URL?

    private var isSharing: Binding<Bool> {
        Binding(
            get: { shareURL != nil },
            set: { newValue in
                if !newValue {
                    shareURL = nil
                }
            }
        )
    }

    private var funnel: [PhoneTelemetryLogger.LaunchFunnelStep] {
        telemetry.launchFunnel()
    }

    var body: some View {
        GameSurface(title: "런치 퍼널", accent: .cyan.opacity(0.78), eyebrow: "telemetry") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    TraitChip(label: "events \(telemetry.eventCount)", accent: .cyan.opacity(0.22))
                    TraitChip(
                        label: funnel.filter(\.reached).count >= 4 ? "core loop reached" : "core loop tracking",
                        accent: funnel.filter(\.reached).count >= 4 ? .green.opacity(0.7) : .orange.opacity(0.72)
                    )
                    Spacer()
                    if telemetry.exportURL() != nil {
                        Button("로그 공유") {
                            shareURL = telemetry.exportURL()
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Text(telemetry.lastEventLabel)
                    .font(.footnote.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.darkest)

                ForEach(funnel) { step in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(step.title)
                                .font(.footnote.monospaced().weight(.black))
                                .foregroundStyle(GameBoyPalette.darkest)
                            TraitChip(
                                label: step.reached ? "도달 \(step.count)" : "대기",
                                accent: step.reached ? .green.opacity(0.68) : .white.opacity(0.2)
                            )
                        }

                        Text(step.lastDetail)
                            .font(.caption2.monospaced())
                            .foregroundStyle(GameBoyPalette.mediumDark)
                            .lineLimit(2)
                    }
                }

                Text(telemetry.logPath())
                    .font(.caption2.monospaced())
                    .foregroundStyle(GameBoyPalette.mediumDark.opacity(0.88))
                    .lineLimit(2)
            }
        }
        .sheet(isPresented: isSharing) {
            if let shareURL {
                ShareSheet(items: [shareURL])
            }
        }
    }
}
