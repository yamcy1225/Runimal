import RunimalCore
import SwiftUI

struct PhoneEssenceForgePanel: View {
    let essenceBalance: Int
    let inventory: ForgeInventory
    let options: [EssenceForgeOption]
    let onForge: (String) -> Void

    var body: some View {
        GameSurface(title: "Essence Forge") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    TraitChip(label: "Essence \(essenceBalance)", accent: .orange.opacity(0.82))
                    TraitChip(label: "Overdrive \(inventory.overdriveCharges)", accent: .white.opacity(0.18))
                    TraitChip(label: "Sigil \(inventory.seasonSigils)", accent: .mint.opacity(0.7))
                }

                ForEach(options) { option in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(option.title)
                                .foregroundStyle(.white)
                            Spacer()
                            TraitChip(label: "\(option.cost) essence", accent: .white.opacity(0.18))
                        }

                        Text(option.detail)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))

                        HStack {
                            TraitChip(label: option.rewardLabel, accent: .orange.opacity(0.7))
                            Spacer()
                            Button("Forge") {
                                onForge(option.id)
                            }
                            .buttonStyle(.bordered)
                            .tint(.orange)
                            .disabled(essenceBalance < option.cost)
                        }
                    }
                }
            }
        }
    }
}
