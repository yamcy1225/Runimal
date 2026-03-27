import RunimalCore
import SwiftUI

struct PhoneBuildTreePanel: View {
    let companion: PetCollectionEntry
    let selectedRole: CompanionRole
    let recommendedRoles: [CompanionRole]
    let nodes: [CompanionSkillNode]
    let essenceBalance: Int
    let onSelectRole: (CompanionRole) -> Void
    let onUnlockNode: (String) -> Void

    var body: some View {
        GameSurface(title: "Role Matrix") {
            VStack(alignment: .leading, spacing: 12) {
                Text("현재 펫 전용 역할을 고르고, Essence로 패시브 노드를 해금합니다.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))

                HStack(spacing: 8) {
                    ForEach(recommendedRoles, id: \.rawValue) { role in
                        Button(role.rawValue.capitalized) {
                            onSelectRole(role)
                        }
                        .buttonStyle(.bordered)
                        .tint(role == selectedRole ? companion.pet.accentColor : .white.opacity(0.2))
                    }
                }

                ForEach(nodes) { node in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(node.title)
                                .foregroundStyle(.white)
                            Spacer()
                            TraitChip(
                                label: node.unlocked ? "UNLOCKED" : "\(node.cost) essence",
                                accent: node.unlocked ? .green : .white.opacity(0.18)
                            )
                        }

                        Text(node.detail)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))

                        if !node.unlocked {
                            Button("Unlock Node") {
                                onUnlockNode(node.id)
                            }
                            .buttonStyle(.bordered)
                            .tint(companion.pet.accentColor)
                            .disabled(essenceBalance < node.cost)
                        }
                    }
                }
            }
        }
    }
}
