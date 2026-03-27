import RunimalCore
import SwiftUI

struct MacQAReplayPanel: View {
    @Binding var selectedScenarioID: String

    private var scenarios: [QAReplayScenario] {
        RunimalQAReplayEngine.scenarios
    }

    private var selectedScenario: QAReplayScenario {
        scenarios.first(where: { $0.id == selectedScenarioID }) ?? scenarios[0]
    }

    private var report: QAReplayReport {
        RunimalQAReplayEngine.report(for: selectedScenario)
    }

    var body: some View {
        GameSurface(title: "QA Replay") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ForEach(scenarios) { scenario in
                        Button(scenario.title) {
                            selectedScenarioID = scenario.id
                        }
                        .buttonStyle(.bordered)
                        .tint(scenario.id == selectedScenarioID ? .red.opacity(0.82) : .white.opacity(0.2))
                    }
                }

                Text(selectedScenario.trigger)
                    .foregroundStyle(.white)
                Text(selectedScenario.recoveryExpectation)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))

                TraitChip(label: report.severity.uppercased(), accent: .red.opacity(0.72))

                ForEach(report.checkpoints, id: \.self) { checkpoint in
                    Text("• \(checkpoint)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                }
            }
        }
    }
}
