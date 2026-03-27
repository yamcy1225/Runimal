import RunimalCore
import SwiftUI

struct PhoneChallengeBoardPanel: View {
    let trials: [ChallengeTrial]

    var body: some View {
        GameSurface(title: "Trial Board") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(trials) { trial in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(trial.title)
                                .foregroundStyle(.white)
                            Spacer()
                            TraitChip(label: "\(trial.verdict) \(trial.score)", accent: .red.opacity(0.72))
                        }

                        Text(trial.detail)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }
            }
        }
    }
}
