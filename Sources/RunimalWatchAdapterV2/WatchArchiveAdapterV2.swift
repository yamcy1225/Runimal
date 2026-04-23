import Foundation
import RunimalCore
import RunimalDomainV2
import RunimalSyncV2

/// Converts existing watch archive assets into v2 domain/sync payloads.
///
/// The existing Watch app already owns HealthKit session capture, GPS sampling,
/// local archive creation, and WatchConnectivity transfer. This adapter keeps
/// those proven assets intact while giving v2 a testable boundary.
public enum RunimalWatchAdapterV2 {
    public struct ConversionOptions: Equatable, Sendable {
        public let sourceDeviceID: String
        public let liveCompanionID: String?

        public init(sourceDeviceID: String, liveCompanionID: String? = nil) {
            self.sourceDeviceID = sourceDeviceID
            self.liveCompanionID = liveCompanionID
        }
    }

    public static func completedArchive(
        from archive: WorkoutSessionArchive,
        options: ConversionOptions
    ) -> RunimalDomainV2.CompletedRunArchive {
        let rawPoints = archive.effectiveRawTrackPoints.map(runSamplePoint(from:))
        let displayPoints = archive.effectiveDisplayTrackPoints.map(runSamplePoint(from:))
        let metrics = RunimalDomainV2.RunMetricSummary(
            distanceMeters: archive.distanceMeters,
            elapsedSeconds: archive.elapsedTimeSeconds,
            movingSeconds: archive.movingTimeSeconds,
            averagePaceSecondsPerKM: archive.averagePaceSeconds,
            averageHeartRateBPM: archive.averageHeartRate,
            averageCadenceSPM: archive.averageCadence,
            elevationGainMeters: archive.elevationGainM
        )

        return RunimalDomainV2.CompletedRunArchive(
            id: StableArchiveID.uuid(from: archive.id, salt: "archive"),
            runID: StableArchiveID.uuid(from: archive.runID, salt: "run"),
            startedAt: archive.startedAt,
            endedAt: archive.endedAt,
            source: archive.source,
            metrics: metrics,
            routePath: RunimalDomainV2.RoutePath(
                rawPoints: rawPoints,
                displayPoints: displayPoints.isEmpty ? nil : displayPoints,
                sourceSampleCount: archive.effectiveRawTrackPoints.count
            ),
            createdOnDevice: options.sourceDeviceID,
            liveCompanionID: options.liveCompanionID,
            previousCoreArchiveID: archive.id
        )
    }

    public static func syncEnvelope(
        for archive: WorkoutSessionArchive,
        options: ConversionOptions
    ) -> RunimalSyncV2.SyncEnvelope {
        let completedArchive = completedArchive(from: archive, options: options)
        return RunimalSyncV2.SyncEnvelope(
            archive: completedArchive,
            sourceDeviceID: options.sourceDeviceID
        )
    }

    private static func runSamplePoint(from point: WorkoutTrackPoint) -> RunimalDomainV2.RunSamplePoint {
        RunimalDomainV2.RunSamplePoint(
            timestamp: point.timestamp,
            latitude: point.latitude,
            longitude: point.longitude,
            altitudeMeters: point.altitude,
            horizontalAccuracyMeters: point.horizontalAccuracy,
            speedMetersPerSecond: point.speedMetersPerSecond,
            heartRateBPM: point.heartRate,
            cadenceSPM: point.cadence,
            isPaused: point.paused
        )
    }

    private static func runSamplePoint(from point: RoutePoint) -> RunimalDomainV2.RunSamplePoint {
        RunimalDomainV2.RunSamplePoint(
            timestamp: point.timestamp,
            latitude: point.latitude,
            longitude: point.longitude,
            altitudeMeters: point.altitude,
            horizontalAccuracyMeters: nil,
            speedMetersPerSecond: nil,
            heartRateBPM: nil,
            cadenceSPM: nil,
            isPaused: false
        )
    }
}

private enum StableArchiveID {
    static func uuid(from value: String, salt: String) -> UUID {
        if let uuid = UUID(uuidString: value) {
            return uuid
        }

        let digest = fnv128Bytes(for: "runimal-v2:\(salt):\(value)")
        let bytes = digest.enumerated().map { index, byte -> UInt8 in
            switch index {
            case 6:
                return (byte & 0x0F) | 0x50 // deterministic name-derived UUID, version-like marker
            case 8:
                return (byte & 0x3F) | 0x80
            default:
                return byte
            }
        }
        let uuidString = String(
            format: "%02X%02X%02X%02X-%02X%02X-%02X%02X-%02X%02X-%02X%02X%02X%02X%02X%02X",
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5],
            bytes[6], bytes[7],
            bytes[8], bytes[9],
            bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
        )
        return UUID(uuidString: uuidString) ?? UUID()
    }

    private static func fnv128Bytes(for string: String) -> [UInt8] {
        var high: UInt64 = 0xcbf29ce484222325
        var low: UInt64 = 0x84222325cbf29ce4

        for byte in string.utf8 {
            high ^= UInt64(byte)
            high &*= 0x100000001b3
            low ^= high.rotatedLeft(13) ^ UInt64(byte)
            low &*= 0x100000001b3
        }

        return high.bigEndianBytes + low.bigEndianBytes
    }
}

private extension UInt64 {
    var bigEndianBytes: [UInt8] {
        var value = bigEndian
        return withUnsafeBytes(of: &value) { Array($0) }
    }

    func rotatedLeft(_ amount: Int) -> UInt64 {
        (self << UInt64(amount)) | (self >> UInt64(64 - amount))
    }
}
