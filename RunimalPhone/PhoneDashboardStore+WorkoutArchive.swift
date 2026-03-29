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
        progress.append(workoutArchive: archive)
        let snapshot = progress.snapshot()
        vault.save(snapshot: snapshot)
        cloudMirror.mirror(snapshot: snapshot)
        telemetry.log("workout_archive_ingested", detail: archive.runID)
    }
}
