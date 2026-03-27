import Foundation

public enum RunimalSnapshotConflictEngine {
    public static func report(
        local: RunimalProgressSnapshot?,
        cloud: RunimalProgressSnapshot?
    ) -> SnapshotConflictReport {
        guard let local, let cloud else {
            return SnapshotConflictReport(
                title: "Conflict Monitor",
                detail: "One side is empty, so direct restore is safe.",
                localRunCount: local?.completedRuns.count ?? 0,
                cloudRunCount: cloud?.completedRuns.count ?? 0,
                localJournalCount: local?.journal.count ?? 0,
                cloudJournalCount: cloud?.journal.count ?? 0,
                recommendedPolicy: .merged,
                hasConflict: false
            )
        }

        let runGap = abs(local.completedRuns.count - cloud.completedRuns.count)
        let journalGap = abs(local.journal.count - cloud.journal.count)
        let sameDevice = local.originDeviceID == cloud.originDeviceID
        let recommendedPolicy: SnapshotConflictPolicy

        if sameDevice || (runGap == 0 && journalGap == 0) {
            recommendedPolicy = .merged
        } else if local.savedAt >= cloud.savedAt {
            recommendedPolicy = .localPreferred
        } else {
            recommendedPolicy = .cloudPreferred
        }

        return SnapshotConflictReport(
            title: sameDevice ? "Mirror Drift" : "Multi-Device Drift",
            detail: sameDevice
                ? "Same-device snapshots diverged. Merge is safest."
                : "Two devices saved different states. Choose the freshest source or merge.",
            localRunCount: local.completedRuns.count,
            cloudRunCount: cloud.completedRuns.count,
            localJournalCount: local.journal.count,
            cloudJournalCount: cloud.journal.count,
            recommendedPolicy: recommendedPolicy,
            hasConflict: runGap > 0 || journalGap > 0 || !sameDevice
        )
    }
}
