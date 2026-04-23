import Foundation
import RunimalCore
import RunimalDomainV2

/// Converts v2 completed run archives into phone-side persistence candidates.
///
/// This adapter intentionally does not import `RunimalPhone` and does not mutate
/// phone stores. It defines the seam where the app can later pass the returned
/// `WorkoutSessionArchive` to the existing phone archive persistence path and keep
/// the returned `RunResource` unspent until the player chooses a growth action.
public enum RunimalPhoneAdapterV2 {
    public struct IngestOptions: Equatable, Sendable {
        /// Existing phone archives keyed by `WorkoutSessionArchive.runID`.
        public let existingArchiveRunIDs: Set<String>
        /// A label that can be surfaced in audit/debug logs when the phone app wires this adapter.
        public let receiverDeviceID: String?

        public init(
            existingArchiveRunIDs: Set<String> = [],
            receiverDeviceID: String? = nil
        ) {
            self.existingArchiveRunIDs = existingArchiveRunIDs
            self.receiverDeviceID = receiverDeviceID
        }
    }

    public enum ArchiveDisposition: String, Codable, Equatable, Sendable {
        case insertNewArchive
        case replaceExistingArchive
    }

    public struct AuditEvent: Codable, Equatable, Sendable {
        public let code: String
        public let message: String

        public init(code: String, message: String) {
            self.code = code
            self.message = message
        }
    }

    public struct IngestPlan: Equatable, Sendable {
        public let archiveForPersistence: WorkoutSessionArchive
        public let runResource: RunimalDomainV2.RunResource
        public let disposition: ArchiveDisposition
        public let auditEvents: [AuditEvent]

        /// V2 keeps post-run growth separate from ingest. The phone app should not
        /// auto-create or auto-spend a reward during archive receipt.
        public var createsCompletedRunRecordImmediately: Bool { false }
        public var spendsRunResourceImmediately: Bool { false }

        public init(
            archiveForPersistence: WorkoutSessionArchive,
            runResource: RunimalDomainV2.RunResource,
            disposition: ArchiveDisposition,
            auditEvents: [AuditEvent]
        ) {
            self.archiveForPersistence = archiveForPersistence
            self.runResource = runResource
            self.disposition = disposition
            self.auditEvents = auditEvents
        }
    }

    public static func ingestPlan(
        for archive: RunimalDomainV2.CompletedRunArchive,
        options: IngestOptions = .init()
    ) -> IngestPlan {
        let archiveForPersistence = workoutArchive(from: archive)
        let disposition: ArchiveDisposition = options.existingArchiveRunIDs.contains(archiveForPersistence.runID)
            ? .replaceExistingArchive
            : .insertNewArchive
        let runResource = RunimalDomainV2.RunResource(
            archiveID: archive.id,
            liveCompanionID: archive.liveCompanionID,
            isSpent: false
        )
        let auditEvents = auditEvents(
            for: archive,
            archiveForPersistence: archiveForPersistence,
            disposition: disposition,
            receiverDeviceID: options.receiverDeviceID
        )

        return IngestPlan(
            archiveForPersistence: archiveForPersistence,
            runResource: runResource,
            disposition: disposition,
            auditEvents: auditEvents
        )
    }

    public static func workoutArchive(
        from archive: RunimalDomainV2.CompletedRunArchive
    ) -> WorkoutSessionArchive {
        let rawTrackPoints = archive.routePath.rawPoints.compactMap(workoutTrackPoint(from:))
        let displayTrackPoints = archive.routePath.displayPoints.compactMap(routePoint(from:))
        let elapsedSeconds = max(0, archive.metrics.elapsedSeconds)
        let movingSeconds = max(0, archive.metrics.movingSeconds)

        return WorkoutSessionArchive(
            id: archive.id.uuidString,
            runID: archive.runID.uuidString,
            startedAt: archive.startedAt,
            endedAt: archive.endedAt,
            elapsedTimeSeconds: elapsedSeconds,
            timerTimeSeconds: elapsedSeconds,
            movingTimeSeconds: movingSeconds,
            distanceMeters: archive.metrics.distanceMeters,
            averageHeartRate: archive.metrics.averageHeartRateBPM,
            averageCadence: archive.metrics.averageCadenceSPM,
            averagePaceSeconds: archive.metrics.averagePaceSecondsPerKM,
            elevationGainM: archive.metrics.elevationGainMeters,
            source: archive.source,
            trackPoints: rawTrackPoints,
            rawTrackPoints: rawTrackPoints,
            displayTrackPoints: displayTrackPoints,
            laps: [WorkoutLap(
                index: 1,
                startTime: archive.startedAt,
                endTime: archive.endedAt,
                distanceMeters: archive.metrics.distanceMeters,
                timerTimeSeconds: elapsedSeconds,
                averageHeartRate: archive.metrics.averageHeartRateBPM,
                averageCadence: archive.metrics.averageCadenceSPM,
                averagePaceSeconds: archive.metrics.averagePaceSecondsPerKM,
                elevationGainM: archive.metrics.elevationGainMeters
            )],
            events: [
                WorkoutSessionEvent(kind: .start, timestamp: archive.startedAt),
                WorkoutSessionEvent(kind: .end, timestamp: archive.endedAt),
            ]
        )
    }

    /// Returns the v2 resource archive ID for an existing `RunimalCore` archive ID.
    ///
    /// Existing phone/watch archives may use non-UUID string identifiers. The phone
    /// app needs the same stable mapping both when ingesting an archive and when
    /// pruning an unspent resource after the user deletes the source run.
    public static func resourceArchiveID(forExistingCoreArchiveID archiveID: String) -> UUID {
        stableArchiveID(from: archiveID)
    }

    /// Creates an ingest plan for an already-canonical `RunimalCore` archive.
    ///
    /// This is the safe first app-target wiring path because it keeps the existing
    /// phone archive payload byte-shape and `runID` intact. V2 still receives an
    /// unspent `RunResource`, keyed by a stable UUID derived from the core archive ID
    /// when the archive ID is not already a UUID.
    public static func ingestPlan(
        forExistingCoreArchive archive: WorkoutSessionArchive,
        options: IngestOptions = .init(),
        liveCompanionID: String? = nil
    ) -> IngestPlan {
        let disposition: ArchiveDisposition = options.existingArchiveRunIDs.contains(archive.runID)
            ? .replaceExistingArchive
            : .insertNewArchive
        let archiveID = resourceArchiveID(forExistingCoreArchiveID: archive.id)
        let runResource = RunimalDomainV2.RunResource(
            archiveID: archiveID,
            liveCompanionID: liveCompanionID,
            isSpent: false
        )
        var auditEvents = auditEvents(
            forCoreArchive: archive,
            stableArchiveID: archiveID,
            disposition: disposition,
            receiverDeviceID: options.receiverDeviceID
        )

        if archive.id != archiveID.uuidString {
            auditEvents.append(AuditEvent(
                code: "phone-ingest-v2.stable-core-archive-id",
                message: "Derived stable v2 archive UUID \(archiveID.uuidString) from core archive ID \(archive.id)."
            ))
        }

        return IngestPlan(
            archiveForPersistence: archive,
            runResource: runResource,
            disposition: disposition,
            auditEvents: auditEvents
        )
    }

    private static func workoutTrackPoint(
        from sample: RunimalDomainV2.RunSamplePoint
    ) -> WorkoutTrackPoint? {
        guard let coordinate = sample.coordinate, coordinate.isValid else { return nil }
        let horizontalAccuracy = max(0, sample.horizontalAccuracyMeters ?? 0)
        return WorkoutTrackPoint(
            timestamp: sample.timestamp,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            altitude: sample.altitudeMeters ?? 0,
            horizontalAccuracy: horizontalAccuracy,
            speedMetersPerSecond: sample.speedMetersPerSecond,
            heartRate: sample.heartRateBPM,
            cadence: sample.cadenceSPM,
            gpsPoor: horizontalAccuracy > RunimalDomainV2.RouteQualityPolicy.usableAccuracyMeters,
            paused: sample.isPaused
        )
    }

    private static func routePoint(
        from sample: RunimalDomainV2.RunSamplePoint
    ) -> RoutePoint? {
        guard let coordinate = sample.coordinate, coordinate.isValid else { return nil }
        return RoutePoint(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            altitude: sample.altitudeMeters ?? 0,
            timestamp: sample.timestamp
        )
    }

    private static func auditEvents(
        for archive: RunimalDomainV2.CompletedRunArchive,
        archiveForPersistence: WorkoutSessionArchive,
        disposition: ArchiveDisposition,
        receiverDeviceID: String?
    ) -> [AuditEvent] {
        var events: [AuditEvent] = [
            AuditEvent(
                code: "phone-ingest-v2.archive-candidate",
                message: "Prepared v2 archive \(archive.id.uuidString) for phone persistence as run \(archiveForPersistence.runID)."
            ),
            AuditEvent(
                code: "phone-ingest-v2.resource-unspent",
                message: "Created unspent RunResource candidate for archive \(archive.id.uuidString)."
            ),
        ]

        switch disposition {
        case .insertNewArchive:
            events.append(AuditEvent(
                code: "phone-ingest-v2.insert",
                message: "No existing phone archive matched run \(archiveForPersistence.runID)."
            ))
        case .replaceExistingArchive:
            events.append(AuditEvent(
                code: "phone-ingest-v2.replace",
                message: "Existing phone archive matched run \(archiveForPersistence.runID); replace rather than duplicate."
            ))
        }

        if let receiverDeviceID {
            events.append(AuditEvent(
                code: "phone-ingest-v2.receiver",
                message: "Plan prepared for receiver device \(receiverDeviceID)."
            ))
        }

        if archive.routePath.rawPoints.count != archiveForPersistence.rawTrackPoints.count {
            events.append(AuditEvent(
                code: "phone-ingest-v2.dropped-invalid-gps",
                message: "Dropped \(archive.routePath.rawPoints.count - archiveForPersistence.rawTrackPoints.count) raw samples without valid GPS coordinates."
            ))
        }

        return events
    }

    private static func auditEvents(
        forCoreArchive archive: WorkoutSessionArchive,
        stableArchiveID: UUID,
        disposition: ArchiveDisposition,
        receiverDeviceID: String?
    ) -> [AuditEvent] {
        var events: [AuditEvent] = [
            AuditEvent(
                code: "phone-ingest-v2.core-archive-candidate",
                message: "Prepared existing core archive \(archive.id) for phone persistence as run \(archive.runID)."
            ),
            AuditEvent(
                code: "phone-ingest-v2.resource-unspent",
                message: "Created unspent RunResource candidate for archive \(stableArchiveID.uuidString)."
            ),
        ]

        switch disposition {
        case .insertNewArchive:
            events.append(AuditEvent(
                code: "phone-ingest-v2.insert",
                message: "No existing phone archive matched run \(archive.runID)."
            ))
        case .replaceExistingArchive:
            events.append(AuditEvent(
                code: "phone-ingest-v2.replace",
                message: "Existing phone archive matched run \(archive.runID); replace rather than duplicate."
            ))
        }

        if let receiverDeviceID {
            events.append(AuditEvent(
                code: "phone-ingest-v2.receiver",
                message: "Plan prepared for receiver device \(receiverDeviceID)."
            ))
        }

        return events
    }

    private static func stableArchiveID(from value: String) -> UUID {
        if let uuid = UUID(uuidString: value) {
            return uuid
        }

        let digest = fnv128Bytes(for: "runimal-phone-v2:core-archive:\(value)")
        let bytes = digest.enumerated().map { index, byte -> UInt8 in
            switch index {
            case 6:
                return (byte & 0x0F) | 0x50
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
