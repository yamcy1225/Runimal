import Foundation
import RunimalCore

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
        let canonicalArchive = WorkoutArchiveCanonicalizer.canonicalize(archive)
        progress.append(workoutArchive: canonicalArchive)
        connectivity.lastWorkoutArchive = canonicalArchive

        let preferredRun = connectivity.lastCompletedRun?.id == canonicalArchive.runID
            ? connectivity.lastCompletedRun
            : progress.completedRuns.first(where: { $0.id == canonicalArchive.runID })
        if let preferredRun {
            let canonicalRun = WorkoutArchiveCanonicalizer.update(preferredRun, with: canonicalArchive)
            progress.append(completedRun: canonicalRun)
            connectivity.lastCompletedRun = canonicalRun
        }

        let snapshot = progress.snapshot()
        vault.save(snapshot: snapshot)
        cloudMirror.mirror(snapshot: snapshot)
        telemetry.log("workout_archive_ingested", detail: canonicalArchive.runID)
    }

    func canDeleteRunRecord(_ run: CompletedRunRecord) -> Bool {
        progress.canDeleteRun(id: run.id)
    }

    @discardableResult
    func deleteRunRecord(id: String) -> Bool {
        guard progress.removeRun(id: id) else { return false }

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
