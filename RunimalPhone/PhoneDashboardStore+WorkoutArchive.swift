import Foundation
import RunimalCore
import RunimalPhoneAdapterV2

extension PhoneDashboardStore {
    var latestWorkoutArchive: WorkoutSessionArchive? {
        progress.workoutArchives.first
    }

    func workoutArchive(for runID: String) -> WorkoutSessionArchive? {
        progress.workoutArchive(for: runID)
    }

    func mutationForm(for run: CompletedRunRecord) -> MutationFormSnapshot? {
        run.mutationForm
    }

    func ingestLatestWorkoutArchive() {
        guard let archive = connectivity.lastWorkoutArchive else { return }
        let worldPack = contentCatalog.worldContentPack()
        let canonicalArchive = WorkoutArchiveCanonicalizer.canonicalize(archive)
        let ingestPlan = RunimalPhoneAdapterV2.ingestPlan(
            forExistingCoreArchive: canonicalArchive,
            options: .init(
                existingArchiveRunIDs: Set(progress.workoutArchives.map(\.runID)),
                receiverDeviceID: progress.deviceID
            )
        )
        let appliedIngest = RunimalPhoneAdapterV2.IngestApplication.apply(
            ingestPlan,
            to: .init(
                workoutArchives: progress.workoutArchives,
                resourceLedger: progress.runResourceLedger
            )
        )
        progress.workoutArchives = appliedIngest.state.workoutArchives
        progress.runResourceLedger = appliedIngest.state.resourceLedger
        connectivity.lastWorkoutArchive = canonicalArchive

        let preferredRun = connectivity.lastCompletedRun?.id == canonicalArchive.runID
            ? connectivity.lastCompletedRun
            : progress.completedRuns.first(where: { $0.id == canonicalArchive.runID })
        if let preferredRun {
            let canonicalRun = WorkoutArchiveCanonicalizer.update(preferredRun, with: canonicalArchive)
            progress.append(completedRun: canonicalRun, pack: worldPack)
            connectivity.lastCompletedRun = canonicalRun
        }

        let snapshot = progress.snapshot()
        vault.save(snapshot: snapshot)
        cloudMirror.mirror(snapshot: snapshot)
        telemetry.log(
            "workout_archive_ingested",
            detail: "\(canonicalArchive.runID):\(appliedIngest.resourceDisposition.rawValue)"
        )
    }

    func canDeleteRunRecord(_ run: CompletedRunRecord) -> Bool {
        progress.canDeleteRun(id: run.id)
    }

    @discardableResult
    func deleteRunRecord(id: String) -> Bool {
        guard progress.removeRun(id: id, pack: contentCatalog.worldContentPack()) else { return false }

        if connectivity.lastCompletedRun?.id == id {
            connectivity.lastCompletedRun = nil
        }
        if connectivity.lastWorkoutArchive?.runID == id {
            connectivity.lastWorkoutArchive = nil
        }

        let snapshot = progress.snapshot()
        vault.save(snapshot: snapshot)
        cloudMirror.mirror(snapshot: snapshot)
        telemetry.log("run_deleted", detail: id)
        return true
    }

    func exportFileURL(
        for run: CompletedRunRecord,
        format: WorkoutExportFormat = .fit,
        timeBasis: WorkoutExportTimeBasis = .timer
    ) throws -> URL {
        guard let archive = workoutArchive(for: run.id) else {
            throw CocoaError(.fileNoSuchFile)
        }

        return try PhoneWorkoutExportManager().exportFileURL(
            for: archive,
            title: "\(run.reward.coreLabel)-\(run.id)",
            format: format,
            timeBasis: timeBasis
        )
    }
}
