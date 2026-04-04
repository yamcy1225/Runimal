import Foundation
import Observation

@MainActor
@Observable
final class PhoneTelemetryLogger {
    private struct Record: Codable {
        let timestamp: Date
        let event: String
        let detail: String
        let properties: [String: String]?
    }

    struct SectionSummary {
        let title: String
        let count: Int
        let lastDetail: String
    }

    var lastEventLabel = "No telemetry yet"
    var eventCount = 0

    func log(_ event: String, detail: String, properties: [String: String] = [:]) {
        let record = Record(
            timestamp: Date(),
            event: event,
            detail: detail,
            properties: properties.isEmpty ? nil : properties
        )
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

    func sectionSummary(title: String, events: Set<String>) -> SectionSummary {
        let records = readRecords().filter { events.contains($0.event) }
        return SectionSummary(
            title: title,
            count: records.count,
            lastDetail: records.first.map { "\($0.event) · \($0.detail)" } ?? "기록 없음"
        )
    }

    private func logURL() -> URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("RunimalVault", isDirectory: true)
            .appendingPathComponent("telemetry.jsonl", isDirectory: false)
    }

    private func readRecords() -> [Record] {
        guard let url = logURL(),
              let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .deferredToDate

        return content
            .split(separator: "\n")
            .compactMap { line in
                try? decoder.decode(Record.self, from: Data(line.utf8))
            }
            .reversed()
    }
}
