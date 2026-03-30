import Foundation
import RunimalCore

@MainActor
final class PhoneWorkoutExportManager {
    func exportFileURL(
        for archive: WorkoutSessionArchive,
        title: String,
        format: WorkoutExportFormat,
        timeBasis: WorkoutExportTimeBasis = .timer
    ) throws -> URL {
        let safeTitle = title
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "/", with: "-")
            .lowercased()
        let filename = "\(safeTitle)-\(timeBasis.rawValue)-\(archive.startedAt.timeIntervalSince1970.rounded()).\(format.fileExtension)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        let data: Data

        switch format {
        case .gpx:
            data = GPXWriter.data(for: archive, title: title, timeBasis: timeBasis)
        case .tcx:
            data = TCXWriter.data(for: archive, title: title, timeBasis: timeBasis)
        case .fit:
            data = try PhoneFITExportWriter.data(for: archive, title: title, timeBasis: timeBasis)
        }

        try data.write(to: url, options: .atomic)
        return url
    }
}
