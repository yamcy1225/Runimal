import Foundation
import RunimalCore

extension PhoneDashboardStore {
    var latestWorkoutArchive: WorkoutSessionArchive? {
        progress.workoutArchives.first
    }

    func workoutArchive(for runID: String) -> WorkoutSessionArchive? {
        progress.workoutArchive(for: runID)
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
}
