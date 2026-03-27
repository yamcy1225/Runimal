import RunimalCore
import SwiftUI

struct PhoneSurplusLabPanel: View {
    let essenceBalance: Int
    let offers: [RetirableCompanionOffer]
    let onRetire: (String) -> Void

    var body: some View {
        GameSurface(title: "Surplus Lab") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Stored Essence")
                        .foregroundStyle(.white.opacity(0.76))
                    Spacer()
                    TraitChip(label: "\(essenceBalance) essence", accent: .green.opacity(0.72))
                }

                if offers.isEmpty {
                    Text("지금은 환원 가능한 중복 종족이 없습니다.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.68))
                } else {
                    ForEach(offers.prefix(3)) { offer in
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(offer.companion.pet.displayName)
                                    .foregroundStyle(.white)
                                Text(offer.reason)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.68))
                            }

                            Spacer()

                            Button("Retire +\(offer.essenceReward)") {
                                onRetire(offer.companion.id)
                            }
                            .buttonStyle(.bordered)
                            .tint(.green)
                        }
                    }
                }
            }
        }
    }
}
