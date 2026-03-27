import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class MacContentAuthoringStore {
    enum Target: String, CaseIterable, Identifiable {
        case rotation
        case raids

        var id: String { rawValue }
        var title: String { rawValue.capitalized }
        var url: URL {
            switch self {
            case .rotation:
                return RunimalPaths.rotationCatalog
            case .raids:
                return RunimalPaths.raidCatalog
            }
        }
    }

    var selectedTarget: Target = .rotation
    var draft = ""
    var status = "Editor idle"
    var validationStatus = "Schema unchecked"

    init() {
        load()
    }

    func load() {
        do {
            draft = try String(contentsOf: selectedTarget.url, encoding: .utf8)
            status = "Loaded \(selectedTarget.title)"
            validationStatus = "Schema unchecked"
        } catch {
            draft = ""
            status = "Load failed"
        }
    }

    func save() {
        do {
            _ = try JSONSerialization.jsonObject(with: Data(draft.utf8))
            try draft.write(to: selectedTarget.url, atomically: true, encoding: .utf8)
            status = "Saved \(selectedTarget.title)"
        } catch {
            status = "Save failed"
        }
    }

    func validate() {
        do {
            _ = try JSONSerialization.jsonObject(with: Data(draft.utf8))
            validationStatus = "Schema ok"
        } catch {
            validationStatus = "Schema invalid"
        }
    }

    func insertPreset() {
        switch selectedTarget {
        case .rotation:
            draft = """
            [
              {
                "id": "season-hunt",
                "title": "Season Hunt",
                "detail": "이번 시즌 포커스 종족과 희귀 변이를 추적합니다.",
                "reward": "Season cache progress"
              }
            ]
            """
        case .raids:
            draft = """
            [
              {
                "id": "trial-warden",
                "title": "Trial Warden",
                "detail": "시즌 기믹을 확인하는 편집용 프리셋 보스입니다.",
                "recommendedReward": "Edit shard",
                "claimThreshold": 148
              }
            ]
            """
        }
        status = "Inserted \(selectedTarget.title) preset"
        validationStatus = "Schema unchecked"
    }
}

struct MacContentAuthoringPanel: View {
    @State private var store = MacContentAuthoringStore()

    var body: some View {
        GameSurface(title: "Content Authoring") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ForEach(MacContentAuthoringStore.Target.allCases) { target in
                        Button(target.title) {
                            store.selectedTarget = target
                            store.load()
                        }
                        .buttonStyle(.bordered)
                        .tint(store.selectedTarget == target ? .mint.opacity(0.82) : .white.opacity(0.2))
                    }

                    Spacer()
                    TraitChip(label: store.status, accent: .mint.opacity(0.72))
                    TraitChip(label: store.validationStatus, accent: .white.opacity(0.18))
                }

                TextEditor(text: $store.draft)
                    .font(.caption.monospaced())
                    .frame(minHeight: 220)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                HStack {
                    Button("Reload") {
                        store.load()
                    }
                    .buttonStyle(.bordered)

                    Button("Save JSON") {
                        store.save()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.mint.opacity(0.82))

                    Button("Validate") {
                        store.validate()
                    }
                    .buttonStyle(.bordered)

                    Button("Insert Preset") {
                        store.insertPreset()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}
