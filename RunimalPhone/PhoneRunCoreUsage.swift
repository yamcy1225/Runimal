import RunimalCore
import SwiftUI

struct PhoneRunCoreUsageSummary {
    let title: String
    let detail: String
    let accent: Color
}

struct PhoneRunCoreRoutingSummary {
    let title: String
    let headline: String
    let detail: String
    let accent: Color
    let badges: [String]
}

extension PhoneDashboardStore {
    func feedProjection(for run: CompletedRunRecord) -> CompanionFeedProjection? {
        progress.feedProjection(
            run: run,
            to: featuredCompanion,
            activeEffects: activeWeeklyEffects,
            season: weeklyBoard.season
        )
    }

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
                title: "지금 선택한 알 부화 준비",
                detail: "\(egg.title) 부화 준비에 사용됨",
                accent: egg.shell.accentColor
            )
        }

        if let growthRecord = progress.growthRecords.first(where: { $0.assignedRunIDs.contains(run.id) }),
           let companion = collection.first(where: { $0.id == growthRecord.companionID }) {
            return PhoneRunCoreUsageSummary(
                title: "동행 성장",
                detail: "\(companion.pet.displayName)에 연결됨",
                accent: companion.pet.accentColor
            )
        }

        return nil
    }

    func runCoreRoutingSummary(for run: CompletedRunRecord) -> PhoneRunCoreRoutingSummary? {
        let livePotential = run.livePotentialProfile?.storedPotentialExperience ?? 0

        if mainSelection?.kind == .egg {
            if let liveCompanionName = run.liveCompanionName {
                var badges = ["지금 선택한 알"]
                if livePotential > 0 {
                    badges.append("잠재 +\(livePotential)")
                }
                return PhoneRunCoreRoutingSummary(
                    title: "분배 흐름",
                    headline: "동행 잠재는 보관, 기록은 알에 사용",
                    detail: livePotential > 0
                        ? "\(liveCompanionName)의 잠재 +\(livePotential) XP는 그 동행에게 남고, 이 운동 기록은 지금 선택한 알 부화 준비에 따로 씁니다."
                        : "\(liveCompanionName)와 함께 달린 이력은 동행 쪽에 남고, 운동 기록은 지금 선택한 알 부화 준비에 따로 씁니다.",
                    accent: .orange,
                    badges: badges
                )
            }

            return PhoneRunCoreRoutingSummary(
                title: "분배 흐름",
                headline: "운동 기록만 사용",
                detail: "이 기록은 실시간 동행 없이 저장된 운동 기록입니다. 지금 선택한 알 부화 준비에 그대로 쓸 수 있습니다.",
                accent: .orange,
                badges: ["지금 선택한 알"]
            )
        }

        let selectedCompanion = featuredCompanion

        guard let liveCompanionID = run.liveCompanionID,
              let liveCompanionName = run.liveCompanionName else {
            return PhoneRunCoreRoutingSummary(
                title: "분배 흐름",
                headline: "운동 기록만 반영",
                detail: "이 기록은 실시간 동행 없이 저장됐습니다. 지금 선택한 \(selectedCompanion.pet.displayName)에게 기록 XP 중심으로 반영됩니다.",
                accent: .cyan,
                badges: ["지금 선택 \(selectedCompanion.pet.displayName)"]
            )
        }

        if liveCompanionID == selectedCompanion.id {
            var badges = ["함께 달림", "지금 선택과 일치"]
            if livePotential > 0 {
                badges.append("잠재 +\(livePotential)")
            }
            return PhoneRunCoreRoutingSummary(
                title: "분배 흐름",
                headline: "\(liveCompanionName)와 바로 연결",
                detail: livePotential > 0
                    ? "같이 달리며 쌓인 잠재 +\(livePotential) XP가 이 동행에게 남아 있습니다. 지금 이 기록을 주면 기록 XP와 저장 잠재가 같은 흐름으로 이어집니다."
                    : "함께 달린 동행과 지금 선택이 같습니다. 이 운동 기록은 같은 성장 흐름으로 바로 이어집니다.",
                accent: .green,
                badges: badges
            )
        }

        var badges = ["함께 달린 \(liveCompanionName)", "지금 선택 \(selectedCompanion.pet.displayName)"]
        if livePotential > 0 {
            badges.append("잠재 별도 저장 +\(livePotential)")
        }
        return PhoneRunCoreRoutingSummary(
            title: "분배 흐름",
            headline: "함께 달린 동행과 지금 선택이 다름",
            detail: livePotential > 0
                ? "\(liveCompanionName)의 잠재 +\(livePotential) XP는 그 동행에게 저장된 채 남고, 지금 선택한 \(selectedCompanion.pet.displayName)에게는 이 운동 기록 자체만 반영됩니다."
                : "함께 달린 이력은 \(liveCompanionName)에게 남고, 지금 선택한 \(selectedCompanion.pet.displayName)에게는 운동 기록 자체만 반영됩니다.",
            accent: .mint,
            badges: badges
        )
    }
}
