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

    private var doctrine: String {
        switch selectedRole {
        case .vanguard:
            return "장거리/고도/방어 축을 극대화하는 안정형 빌드입니다."
        case .relay:
            return "케이던스/페이스/연속 러닝을 먹여 속도 성장을 밀어붙이는 빌드입니다."
        case .oracle:
            return "희귀 변이, 퀘스트, 특수 조건 해석을 강화하는 연구형 빌드입니다."
        }
    }

    var body: some View {
        GameSurface(title: "Role Matrix") {
            VStack(alignment: .leading, spacing: 12) {
                Text("현재 펫 전용 역할을 고르고, Essence로 패시브 노드를 해금합니다.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))

                Text(doctrine)
                    .font(.caption)
                    .foregroundStyle(companion.pet.accentColor.opacity(0.9))

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
