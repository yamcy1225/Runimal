import Foundation

public enum RunimalRecordDiffEngine {
    public static func choices(
        local: RunimalProgressSnapshot?,
        cloud: RunimalProgressSnapshot?
    ) -> [RecordDiffChoice] {
        guard let local, let cloud else { return [] }

        let localRuns = Dictionary(uniqueKeysWithValues: local.completedRuns.map { ($0.id, $0) })
        let cloudRuns = Dictionary(uniqueKeysWithValues: cloud.completedRuns.map { ($0.id, $0) })
        let overlappingRunIDs = Set(localRuns.keys).intersection(cloudRuns.keys)

        let runChoices = overlappingRunIDs.compactMap { id -> RecordDiffChoice? in
            guard let lhs = localRuns[id], let rhs = cloudRuns[id], lhs != rhs else { return nil }
            return RecordDiffChoice(
                id: id,
                type: "run",
                title: lhs.reward.coreLabel,
                localLabel: "\(Int(lhs.distanceMeters))m local",
                cloudLabel: "\(Int(rhs.distanceMeters))m cloud"
            )
        }

        let localJournal = Dictionary(uniqueKeysWithValues: local.journal.map { ($0.id, $0) })
        let cloudJournal = Dictionary(uniqueKeysWithValues: cloud.journal.map { ($0.id, $0) })
        let overlappingJournalIDs = Set(localJournal.keys).intersection(cloudJournal.keys)

        let journalChoices = overlappingJournalIDs.compactMap { id -> RecordDiffChoice? in
            guard let lhs = localJournal[id], let rhs = cloudJournal[id], lhs != rhs else { return nil }
            return RecordDiffChoice(
                id: id,
                type: "journal",
                title: lhs.reward.coreLabel,
                localLabel: "\(lhs.distanceKm)km local",
                cloudLabel: "\(rhs.distanceKm)km cloud"
            )
        }

        return runChoices + journalChoices
    }
}
