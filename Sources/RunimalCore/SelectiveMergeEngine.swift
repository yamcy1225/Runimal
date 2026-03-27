import Foundation

public enum RunimalSelectiveMergeEngine {
    public static func candidates(
        local: RunimalProgressSnapshot?,
        cloud: RunimalProgressSnapshot?
    ) -> [MergeCandidate] {
        guard let local, let cloud else { return [] }

        let localRunIDs = Set(local.completedRuns.map(\.id))
        let localJournalIDs = Set(local.journal.map(\.id))
        let cloudOnlyRuns = cloud.completedRuns.filter { !localRunIDs.contains($0.id) }
        let cloudOnlyJournal = cloud.journal.filter { !localJournalIDs.contains($0.id) }

        return cloudOnlyRuns.map {
            MergeCandidate(
                id: $0.id,
                label: String(format: "%@ · %.1fkm", $0.reward.pet.species.rawValue, $0.distanceMeters / 1000),
                source: "cloud",
                type: "run"
            )
        } + cloudOnlyJournal.map {
            MergeCandidate(
                id: $0.id,
                label: String(format: "%@ · %.1fkm", $0.reward.coreLabel, $0.distanceKm),
                source: "cloud",
                type: "journal"
            )
        }
    }
}
