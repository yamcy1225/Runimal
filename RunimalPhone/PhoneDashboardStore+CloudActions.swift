import RunimalCore

@MainActor
extension PhoneDashboardStore {
    func selectConflictPolicy(_ policy: SnapshotConflictPolicy) {
        progress.setConflictPolicy(policy)
        telemetry.log("select_conflict_policy", detail: policy.rawValue)
    }

    func applyConflictPolicy() {
        let localSnapshot = vault.loadSnapshot()
        let cloudSnapshot = cloudMirror.restoreIfAvailable()

        let resolved: RunimalProgressSnapshot?

        switch progress.conflictPolicy {
        case .merged:
            if let localSnapshot, let cloudSnapshot {
                resolved = RunimalSnapshotMergeEngine.merge(localSnapshot, cloudSnapshot, priority: progress.duplicatePriority)
            } else {
                resolved = localSnapshot ?? cloudSnapshot
            }
        case .localPreferred:
            resolved = localSnapshot ?? cloudSnapshot
        case .cloudPreferred:
            resolved = cloudSnapshot ?? localSnapshot
        }

        guard let resolved else { return }
        progress.restore(from: resolved)
        persistVault()
        telemetry.log("apply_conflict_policy", detail: progress.conflictPolicy.rawValue)
    }

    func recordVerification(_ title: String, passed: Bool) {
        progress.recordVerification(title, passed: passed)
        persistVault()
        telemetry.log("verification_recorded", detail: "\(title):\(passed)")
    }

    func selectDuplicatePriority(_ priority: SnapshotDuplicatePriority) {
        progress.setDuplicatePriority(priority)
        telemetry.log("select_duplicate_priority", detail: priority.rawValue)
    }

    func importSelectiveCandidate(_ id: String, type: String) {
        let localSnapshot = vault.loadSnapshot()
        let cloudSnapshot = cloudMirror.restoreIfAvailable()
        progress.importSelectiveCandidate(id: id, type: type, local: localSnapshot, cloud: cloudSnapshot)
        persistVault()
        telemetry.log("selective_import", detail: "\(type):\(id)")
    }

    func importAllSelectiveCandidates(_ type: String) {
        let localSnapshot = vault.loadSnapshot()
        let cloudSnapshot = cloudMirror.restoreIfAvailable()
        progress.importAllSelectiveCandidates(type: type, local: localSnapshot, cloud: cloudSnapshot)
        persistVault()
        telemetry.log("selective_import_all", detail: type)
    }

    func resolveRecordDiff(_ id: String, type: String, useCloud: Bool) {
        let localSnapshot = vault.loadSnapshot()
        let cloudSnapshot = cloudMirror.restoreIfAvailable()
        progress.resolveRecordDiff(id: id, type: type, useCloud: useCloud, local: localSnapshot, cloud: cloudSnapshot)
        persistVault()
        telemetry.log("record_diff_resolved", detail: "\(type):\(id):\(useCloud)")
    }

    func resolveAllRecordDiffs(type: String, useCloud: Bool) {
        let localSnapshot = vault.loadSnapshot()
        let cloudSnapshot = cloudMirror.restoreIfAvailable()
        progress.resolveAllRecordDiffs(type: type, useCloud: useCloud, local: localSnapshot, cloud: cloudSnapshot)
        persistVault()
        telemetry.log("record_diff_batch_resolved", detail: "\(type):\(useCloud)")
    }
}
