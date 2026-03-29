import RunimalCore
import SwiftUI

struct PhoneRunCoreUsageSummary {
    let title: String
    let detail: String
    let accent: Color
}

extension PhoneDashboardStore {
    func runCoreUsageSummary(for run: CompletedRunRecord) -> PhoneRunCoreUsageSummary? {
        if let egg = progress.eggInventory.first(where: { $0.sourceRunID == run.id }) {
            return PhoneRunCoreUsageSummary(
                title: "새 알 생성",
                detail: "\(egg.title) 생성에 사용됨",
                accent: egg.shell.accentColor
            )
        }

        if let egg = progress.eggInventory.first(where: { $0.incubationRunIDs.contains(run.id) }) {
            return PhoneRunCoreUsageSummary(
                title: "메인 알 주입",
                detail: "\(egg.title) 디코딩 진척에 사용됨",
                accent: egg.shell.accentColor
            )
        }

        if let growthRecord = progress.growthRecords.first(where: { $0.assignedRunIDs.contains(run.id) }),
           let companion = collection.first(where: { $0.id == growthRecord.companionID }) {
            return PhoneRunCoreUsageSummary(
                title: "동행체 성장",
                detail: "\(companion.pet.displayName)에 연결됨",
                accent: companion.pet.accentColor
            )
        }

        return nil
    }
}
