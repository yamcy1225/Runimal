import Foundation

public enum RunimalSnapshotConflictDiffEngine {
    public static func entries(
        local: RunimalProgressSnapshot?,
        cloud: RunimalProgressSnapshot?
    ) -> [SnapshotConflictDiffEntry] {
        [
            SnapshotConflictDiffEntry(
                id: "saved-at",
                label: "Saved At",
                localValue: local.map { shortDate($0.savedAt) } ?? "--",
                cloudValue: cloud.map { shortDate($0.savedAt) } ?? "--"
            ),
            SnapshotConflictDiffEntry(
                id: "origin",
                label: "Origin Device",
                localValue: local?.originDeviceID ?? "--",
                cloudValue: cloud?.originDeviceID ?? "--"
            ),
            SnapshotConflictDiffEntry(
                id: "runs",
                label: "Completed Runs",
                localValue: "\(local?.completedRuns.count ?? 0)",
                cloudValue: "\(cloud?.completedRuns.count ?? 0)"
            ),
            SnapshotConflictDiffEntry(
                id: "journal",
                label: "Journal Entries",
                localValue: "\(local?.journal.count ?? 0)",
                cloudValue: "\(cloud?.journal.count ?? 0)"
            ),
        ]
    }

    private static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
