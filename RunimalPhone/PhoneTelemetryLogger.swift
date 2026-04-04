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

    struct LaunchFunnelStep: Identifiable {
        let id: String
        let title: String
        let count: Int
        let lastDetail: String

        var reached: Bool {
            count > 0
        }
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

    func exportURL() -> URL? {
        let url = logURL()
        guard let url, FileManager.default.fileExists(atPath: url.path) else { return nil }
        return url
    }

    func sectionSummary(title: String, events: Set<String>) -> SectionSummary {
        let records = readRecords().filter { events.contains($0.event) }
        return SectionSummary(
            title: title,
            count: records.count,
            lastDetail: records.first.map { "\($0.event) · \($0.detail)" } ?? "기록 없음"
        )
    }

    func launchFunnel() -> [LaunchFunnelStep] {
        let records = readRecords()
        let orderedSteps = [
            ("first_run_completed", "첫 러닝"),
            ("egg_created", "첫 알 생성"),
            ("egg_hatched", "첫 부화"),
            ("first_stage_up", "첫 단계 상승"),
            ("rare_variant_obtained", "희귀 변이"),
            ("weekly_reward_claimed", "주간 보상")
        ]

        return orderedSteps.map { event, title in
            let matches = records.filter { $0.event == event }
            return LaunchFunnelStep(
                id: event,
                title: title,
                count: matches.count,
                lastDetail: matches.first.map { $0.detail } ?? "아직 없음"
            )
        }
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
