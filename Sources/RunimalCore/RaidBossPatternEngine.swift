import Foundation

public enum RunimalRaidBossPatternEngine {
    public static func patterns(for encounter: RaidEncounter, season: WeeklySeason) -> [RaidBossPattern] {
        let seasonalTag = season.title

        return [
            RaidBossPattern(
                id: "\(encounter.id)-entry",
                title: "Opening Pattern",
                detail: "\(seasonalTag) season starts \(encounter.title) with a front-loaded pulse.",
                emphasis: "entry"
            ),
            RaidBossPattern(
                id: "\(encounter.id)-shift",
                title: "Mid Shift",
                detail: "Role alignment decides whether the mid phase stabilizes or breaks.",
                emphasis: "role"
            ),
            RaidBossPattern(
                id: "\(encounter.id)-burst",
                title: "Burst Window",
                detail: "High readiness converts into shard pressure during the finish window.",
                emphasis: "burst"
            ),
        ]
    }

    public static func turnResults(for report: RaidCombatReport) -> [RaidTurnResult] {
        report.steps.enumerated().map { index, step in
            RaidTurnResult(
                id: step.id,
                title: "Turn \(index + 1) · \(step.label)",
                detail: step.detail,
                score: Int(step.intensity * 100)
            )
        }
    }
}
