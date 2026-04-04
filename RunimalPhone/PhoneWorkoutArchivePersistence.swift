import Foundation
import RunimalCore

struct PhoneWorkoutArchivePersistence {
    private let fileManager: FileManager
    private let directoryURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        fileManager: FileManager = .default,
        directoryName: String = "RunimalPhone"
    ) {
        self.fileManager = fileManager
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        self.directoryURL = baseURL.appendingPathComponent(directoryName, isDirectory: true)
    }

    func loadCompletedRuns(fallbackData: Data?) -> [CompletedRunRecord] {
        loadArray(
            filename: "completed-runs.json",
            type: [CompletedRunRecord].self,
            fallbackData: fallbackData
        )
    }

    func loadWorkoutArchives(fallbackData: Data?) -> [WorkoutSessionArchive] {
        loadArray(
            filename: "workout-archives.json",
            type: [WorkoutSessionArchive].self,
            fallbackData: fallbackData
        )
    }

    func saveCompletedRuns(_ runs: [CompletedRunRecord]) throws {
        try saveArray(runs, filename: "completed-runs.json")
    }

    func saveWorkoutArchives(_ archives: [WorkoutSessionArchive]) throws {
        try saveArray(archives, filename: "workout-archives.json")
    }

    func hasPersistedData() -> Bool {
        let completedRunsURL = directoryURL.appendingPathComponent("completed-runs.json")
        let workoutArchivesURL = directoryURL.appendingPathComponent("workout-archives.json")
        let packagesDirectoryURL = directoryURL.appendingPathComponent("WorkoutPackages", isDirectory: true)

        return fileManager.fileExists(atPath: completedRunsURL.path) ||
            fileManager.fileExists(atPath: workoutArchivesURL.path) ||
            fileManager.fileExists(atPath: packagesDirectoryURL.path)
    }

    func clearAll() throws {
        guard fileManager.fileExists(atPath: directoryURL.path) else { return }
        try fileManager.removeItem(at: directoryURL)
    }

    func removeWorkoutPackageFiles(forRunID runID: String) throws {
        let packagesDirectoryURL = directoryURL.appendingPathComponent("WorkoutPackages", isDirectory: true)
        guard fileManager.fileExists(atPath: packagesDirectoryURL.path) else { return }

        let packageURLs = try fileManager.contentsOfDirectory(
            at: packagesDirectoryURL,
            includingPropertiesForKeys: nil
        )

        for packageURL in packageURLs where packageURL.lastPathComponent.hasPrefix("\(runID)-") {
            try fileManager.removeItem(at: packageURL)
        }
    }

    func storeReceivedWorkoutPackageFile(
        at sourceURL: URL,
        runID: String,
        archiveID: String,
        kind: WorkoutSessionPackageFileKind
    ) throws -> WorkoutSessionArchive? {
        let packageDirectoryURL = directoryURL
            .appendingPathComponent("WorkoutPackages", isDirectory: true)
            .appendingPathComponent("\(runID)-\(archiveID)", isDirectory: true)
        try fileManager.createDirectory(at: packageDirectoryURL, withIntermediateDirectories: true)

        let destinationURL = packageDirectoryURL.appendingPathComponent(kind.filename)
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        return try decodeStoredWorkoutPackageIfComplete(runID: runID, archiveID: archiveID)
    }

    private func decodeStoredWorkoutPackageIfComplete(
        runID: String,
        archiveID: String
    ) throws -> WorkoutSessionArchive? {
        let packageDirectoryURL = directoryURL
            .appendingPathComponent("WorkoutPackages", isDirectory: true)
            .appendingPathComponent("\(runID)-\(archiveID)", isDirectory: true)
        let summaryURL = packageDirectoryURL.appendingPathComponent(WorkoutSessionPackageFileKind.summary.filename)
        let rawTrackURL = packageDirectoryURL.appendingPathComponent(WorkoutSessionPackageFileKind.rawTrack.filename)
        let eventsURL = packageDirectoryURL.appendingPathComponent(WorkoutSessionPackageFileKind.events.filename)
        let lapsURL = packageDirectoryURL.appendingPathComponent(WorkoutSessionPackageFileKind.laps.filename)

        let requiredURLs = [summaryURL, rawTrackURL, eventsURL, lapsURL]
        guard requiredURLs.allSatisfy({ fileManager.fileExists(atPath: $0.path) }) else {
            return nil
        }

        return try WorkoutSessionPackageCodec.archive(
            summaryData: Data(contentsOf: summaryURL),
            rawTrackData: Data(contentsOf: rawTrackURL),
            eventsData: Data(contentsOf: eventsURL),
            lapsData: Data(contentsOf: lapsURL)
        )
    }

    private func loadArray<T: Decodable>(
        filename: String,
        type: T.Type,
        fallbackData: Data?
    ) -> T {
        let fileURL = directoryURL.appendingPathComponent(filename)

        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? decoder.decode(T.self, from: data) {
            return decoded
        }

        if let fallbackData,
           let decoded = try? decoder.decode(T.self, from: fallbackData) {
            return decoded
        }

        if let emptyArray = [] as? T {
            return emptyArray
        }

        fatalError("PhoneWorkoutArchivePersistence expected array-backed type for \(filename)")
    }

    private func saveArray<T: Encodable>(_ value: T, filename: String) throws {
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let data = try encoder.encode(value)
        let fileURL = directoryURL.appendingPathComponent(filename)
        try data.write(to: fileURL, options: [.atomic])
    }
}
