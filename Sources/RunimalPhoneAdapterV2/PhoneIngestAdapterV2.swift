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
}
