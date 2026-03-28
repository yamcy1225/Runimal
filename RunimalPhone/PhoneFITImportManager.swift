import CryptoKit
import FitDataProtocol
import Foundation
import Observation
import RunimalCore
import UniformTypeIdentifiers

struct FITRunImport: Identifiable {
    let id: String
    let sourceName: String
    let reward: RunRewardSummary
    let record: CompletedRunRecord
    let snapshot: LiveRunSnapshot
}

extension UTType {
    static let fitFile = UTType(filenameExtension: "fit") ?? .data
}

@MainActor
@Observable
final class PhoneFITImportManager {
    var importStatusLabel = "FIT 파일 가져오기 대기"
    var lastErrorMessage: String?

    func importFile(
        from url: URL,
        claimedRewardIDs: Set<String>
    ) async throws -> FITRunImport {
        let accessedSecurityScope = url.startAccessingSecurityScopedResource()
        defer {
            if accessedSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        let parsed = try parse(data: data, fallbackName: url.deletingPathExtension().lastPathComponent)
        let reward = RunimalGameEngine.evaluateImportedWorkoutReward(
            for: parsed.snapshot,
            claimedRewardIDs: claimedRewardIDs
        )
        let sourceName = parsed.displayName
        let record = RunimalGameEngine.makeCompletedRunRecord(
            reward: reward,
            snapshot: parsed.snapshot,
            startedAt: parsed.startedAt,
            endedAt: parsed.endedAt,
            averageHeartRate: parsed.averageHeartRate,
            route: parsed.routePreview,
            source: "fit:\(sourceName.lowercased())",
            sourceLabel: sourceName,
            environmentCondition: .unknown,
            rareEventCompleted: false,
            id: fitImportID(for: data)
        )

        importStatusLabel = "\(url.lastPathComponent) 가져옴"
        lastErrorMessage = nil
        return FITRunImport(
            id: record.id,
            sourceName: sourceName,
            reward: reward,
            record: record,
            snapshot: parsed.snapshot
        )
    }

    func markImportCancelled() {
        importStatusLabel = "FIT 선택 취소"
    }

    func markImportFailed(_ message: String) {
        importStatusLabel = "FIT 가져오기 실패"
        lastErrorMessage = message
    }

    func resetImportedStatus() {
        importStatusLabel = "FIT 가져오기 대기"
        lastErrorMessage = nil
    }

    private func fitImportID(for data: Data) -> String {
        let digest = SHA256.hash(data: data)
        let hash = digest.compactMap { String(format: "%02x", $0) }.joined()
        return "fit-\(hash)"
    }

    private func parse(data: Data, fallbackName: String) throws -> ParsedFITRun {
        var decoder = FitFileDecoder(crcCheckingStrategy: .throws)
        var sessionMessages: [SessionMessage] = []
        var recordMessages: [RecordMessage] = []

        try decoder.decode(
            data: data,
            messages: FitFileDecoder.defaultMessages,
            decoded: { message in
                if let session = message as? SessionMessage {
                    sessionMessages.append(session)
                }
                if let record = message as? RecordMessage {
                    recordMessages.append(record)
                }
            }
        )

        let session = preferredSession(from: sessionMessages)
        let route = sampledRoutePreview(from: recordMessages)
        let recordTimestamps = timestamps(from: recordMessages)
        let startedAt = sessionStartDate(session) ?? recordTimestamps.min() ?? Date()
        let endedAt = sessionEndDate(session) ?? recordTimestamps.max() ?? startedAt

        let durationSeconds = sessionDurationSeconds(session, startedAt: startedAt, endedAt: endedAt)
        let distanceMeters = sessionDistanceMeters(session, records: recordMessages)
        let averageHeartRate = importedAverageHeartRate(session, records: recordMessages)
        let cadence = importedAverageCadence(session, records: recordMessages)
        let elevationGainM = routeElevationGain(from: route)
        let averagePaceSeconds = distanceMeters > 0
            ? Int((Double(durationSeconds) / (distanceMeters / 1000)).rounded())
            : nil

        return ParsedFITRun(
            displayName: fallbackName,
            startedAt: startedAt,
            endedAt: endedAt,
            averageHeartRate: averageHeartRate,
            routePreview: route,
            snapshot: LiveRunSnapshot(
                elapsedSeconds: durationSeconds,
                distanceMeters: distanceMeters,
                currentHeartRate: averageHeartRate,
                cadence: cadence,
                elevationGainM: elevationGainM,
                averagePaceSeconds: averagePaceSeconds
            )
        )
    }

    private func average(_ values: [Double]) -> Double? {
        guard values.isEmpty == false else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func preferredSession(from sessions: [SessionMessage]) -> SessionMessage? {
        var selected: SessionMessage?
        var selectedDistance = 0.0

        for session in sessions {
            let distance = session.totalDistance?.converted(to: .meters).value ?? 0
            if selected == nil || distance > selectedDistance {
                selected = session
                selectedDistance = distance
            }
        }

        return selected
    }

    private func timestamps(from records: [RecordMessage]) -> [Date] {
        records.compactMap { record in
            record.timeStamp?.recordDate
        }
    }

    private func sessionStartDate(_ session: SessionMessage?) -> Date? {
        session?.startTime?.recordDate
    }

    private func sessionEndDate(_ session: SessionMessage?) -> Date? {
        session?.timeStamp?.recordDate
    }

    private func sessionDurationSeconds(_ session: SessionMessage?, startedAt: Date, endedAt: Date) -> Int {
        let timerSeconds = session?.totalTimerTime?.converted(to: .seconds).value
        let elapsedSeconds = session?.totalElapsedTime?.converted(to: .seconds).value
        let fallbackSeconds = endedAt.timeIntervalSince(startedAt)
        let seconds = timerSeconds ?? elapsedSeconds ?? fallbackSeconds
        return max(Int(seconds.rounded()), 1)
    }

    private func sessionDistanceMeters(_ session: SessionMessage?, records: [RecordMessage]) -> Double {
        let sessionDistance = session?.totalDistance?.converted(to: .meters).value ?? 0
        let recordDistance = records.compactMap { recordDistanceMeters($0) }.max() ?? 0
        return max(sessionDistance, recordDistance)
    }

    private func importedAverageHeartRate(_ session: SessionMessage?, records: [RecordMessage]) -> Double? {
        if let sessionAverage = session?.averageHeartRate?.value {
            return sessionAverage
        }
        let recordedValues = records.compactMap { recordHeartRate($0) }
        return average(recordedValues)
    }

    private func importedAverageCadence(_ session: SessionMessage?, records: [RecordMessage]) -> Int? {
        if let sessionAverage = session?.averageCadence?.value {
            return roundedInt(sessionAverage)
        }
        let recordedValues = records.compactMap { recordCadence($0) }
        return roundedInt(average(recordedValues))
    }

    private func roundedInt(_ value: Double?) -> Int? {
        guard let value else { return nil }
        return Int(value.rounded())
    }

    private func recordDistanceMeters(_ record: RecordMessage) -> Double? {
        record.distance?.converted(to: .meters).value
    }

    private func recordHeartRate(_ record: RecordMessage) -> Double? {
        record.heartRate?.value
    }

    private func recordCadence(_ record: RecordMessage) -> Double? {
        record.cadence?.value
    }

    private func sampledRoutePreview(from records: [RecordMessage]) -> [RoutePoint] {
        let points = records.compactMap { record -> RoutePoint? in
            guard
                let latitude = record.position?.latitude?.converted(to: .degrees).value,
                let longitude = record.position?.longitude?.converted(to: .degrees).value,
                let timestamp = record.timeStamp?.recordDate
            else {
                return nil
            }

            let altitude = record.altitude?.converted(to: .meters).value ?? 0
            return RoutePoint(
                latitude: latitude,
                longitude: longitude,
                altitude: altitude,
                timestamp: timestamp
            )
        }

        guard points.count > 20 else { return points }
        let step = max(points.count / 20, 1)
        return stride(from: 0, to: points.count, by: step).map { points[$0] }
    }

    private func routeElevationGain(from route: [RoutePoint]) -> Int {
        guard route.count > 1 else { return 0 }

        var gain = 0.0
        for index in 1..<route.count {
            let delta = route[index].altitude - route[index - 1].altitude
            if delta > 0 {
                gain += delta
            }
        }
        return Int(gain.rounded())
    }
}

private struct ParsedFITRun {
    let displayName: String
    let startedAt: Date
    let endedAt: Date
    let averageHeartRate: Double?
    let routePreview: [RoutePoint]
    let snapshot: LiveRunSnapshot
}
