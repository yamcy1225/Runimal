import Foundation
import Observation

@MainActor
@Observable
final class PhoneTelemetryLogger {
    private struct Record: Codable {
        let timestamp: Date
        let event: String
        let detail: String
    }

    var lastEventLabel = "No telemetry yet"
    var eventCount = 0

    func log(_ event: String, detail: String) {
        let record = Record(timestamp: Date(), event: event, detail: detail)
        guard let url = logURL() else { return }

        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(record)
            let line = (String(data: data, encoding: .utf8) ?? "") + "\n"

            if FileManager.default.fileExists(atPath: url.path) {
                let handle = try FileHandle(forWritingTo: url)
                try handle.seekToEnd()
                handle.write(Data(line.utf8))
                try handle.close()
            } else {
                try Data(line.utf8).write(to: url, options: [.atomic])
            }

            eventCount += 1
            lastEventLabel = "\(event) · \(detail)"
        } catch {
            lastEventLabel = "Telemetry write failed"
        }
    }

    func logPath() -> String {
        logURL()?.path ?? "unavailable"
    }

    private func logURL() -> URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("RunimalVault", isDirectory: true)
            .appendingPathComponent("telemetry.jsonl", isDirectory: false)
    }
}
