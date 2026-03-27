import Foundation
import Observation
import RunimalCore
import SwiftUI

@MainActor
@Observable
final class MacDeviceQAStore {
    var status = "QA export idle"

    func exportChecklist(_ checklist: [DeviceQACheckItem]) {
        let runbook = [
            "Signed iCloud Roundtrip Runbook",
            "1. 같은 Apple ID로 iPhone과 Apple Watch를 로그인합니다.",
            "2. iPhone에서 vault mirror를 만든 뒤 앱을 재실행합니다.",
            "3. Watch에서 러닝 종료 후 reward sync가 iPhone에 반영되는지 확인합니다.",
            "4. conflict panel에서 local/cloud 우선순위와 record diff 편집을 검수합니다.",
            "5. Watch에서 Rare Window / Surge / Recover 전환 시 햅틱이 달라지는지 기록합니다.",
            "6. iPhone Collection에서 Feed Active 실행 후 XP fill과 stage cut-in이 재생되는지 기록합니다.",
            "7. 각 항목을 PASS / FAIL / NOTE 형식으로 별도 메모합니다.",
        ].joined(separator: "\n")
        let lines = runbook + "\n\n" + checklist.map { "\($0.title)\n\($0.detail)" }.joined(separator: "\n\n")

        do {
            try lines.write(to: RunimalPaths.repoRoot.appendingPathComponent("docs/device-qa-export.txt"), atomically: true, encoding: .utf8)
            status = "Checklist exported"
        } catch {
            status = "Export failed"
        }
    }
}

struct MacDeviceQAPanel: View {
    let checklist: [DeviceQACheckItem]
    @State private var store = MacDeviceQAStore()

    var body: some View {
        GameSurface(title: "Device QA Checklist") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    TraitChip(label: store.status, accent: .white.opacity(0.18))
                    Spacer()
                    Button("Export QA Report") {
                        store.exportChecklist(checklist)
                    }
                    .buttonStyle(.bordered)
                }

                ForEach(checklist) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .foregroundStyle(.white)
                        Text(item.detail)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }
            }
        }
    }
}
