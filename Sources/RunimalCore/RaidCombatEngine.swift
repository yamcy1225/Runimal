import Foundation

public enum RunimalRaidCombatEngine {
    public static func report(
        encounter: RaidEncounter,
        companion: PetCollectionEntry,
        progress: EvolutionProgress,
        selectedRole: CompanionRole
    ) -> RaidCombatReport {
        let leadStat: Int

        switch selectedRole {
        case .vanguard:
            leadStat = companion.pet.stats.defense
        case .relay:
            leadStat = companion.pet.stats.agility
        case .oracle:
            leadStat = companion.pet.stats.focus
        }

        let advantage = encounter.readinessScore - encounter.claimThreshold
        let verdict: String

        if advantage >= 35 {
            verdict = "OVERDRIVE"
        } else if advantage >= 10 {
            verdict = "PRESSURE"
        } else {
            verdict = "EDGE"
        }

        let clamped = max(0.22, min(1.0, Double(encounter.readinessScore) / Double(max(encounter.claimThreshold, 1))))

        return RaidCombatReport(
            title: encounter.title,
            verdict: verdict,
            headline: "\(selectedRole.rawValue.capitalized) role drives the raid with stat \(leadStat) and XP \(progress.totalExperience).",
            steps: [
                RaidCombatStep(
                    id: "entry",
                    label: "Entry Pulse",
                    detail: "Opening momentum from current build and bond.",
                    intensity: clamped
                ),
                RaidCombatStep(
                    id: "core",
                    label: "Core Clash",
                    detail: "Main exchange against \(encounter.title.lowercased()).",
                    intensity: max(0.18, min(1.0, clamped + 0.12))
                ),
                RaidCombatStep(
                    id: "finish",
                    label: "Finish Window",
                    detail: "End phase converts advantage \(advantage) into shard potential.",
                    intensity: max(0.18, min(1.0, clamped + Double(advantage) / 180))
                ),
            ]
        )
    }
}
