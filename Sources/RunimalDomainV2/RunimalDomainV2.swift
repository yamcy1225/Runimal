import Foundation

/// Draft v2 domain namespace. Not wired into Package.swift yet.
public enum RunimalDomainV2 {
    /// Watch/iPhone-neutral run lifecycle for the minimum reliable recording loop.
    public enum RecordingState: String, Codable, Sendable {
        case idle
        case preparing
        case recording
        case paused
        case finishing
        case locallyArchived
        case queuedForSync
        case synced
        case failed
    }

    /// Raw metric/path sample captured during a run.
    public struct RunSample: Codable, Equatable, Identifiable, Sendable {
        public let id: UUID
        public let timestamp: Date
        public let latitude: Double?
        public let longitude: Double?
        public let altitudeMeters: Double?
        public let horizontalAccuracyMeters: Double?
        public let speedMetersPerSecond: Double?
        public let heartRateBPM: Double?
        public let cadenceSPM: Int?
        public let isPaused: Bool

        public init(
            id: UUID = UUID(),
            timestamp: Date,
            latitude: Double? = nil,
            longitude: Double? = nil,
            altitudeMeters: Double? = nil,
            horizontalAccuracyMeters: Double? = nil,
            speedMetersPerSecond: Double? = nil,
            heartRateBPM: Double? = nil,
            cadenceSPM: Int? = nil,
            isPaused: Bool = false
        ) {
            self.id = id
            self.timestamp = timestamp
            self.latitude = latitude
            self.longitude = longitude
            self.altitudeMeters = altitudeMeters
            self.horizontalAccuracyMeters = horizontalAccuracyMeters
            self.speedMetersPerSecond = speedMetersPerSecond
            self.heartRateBPM = heartRateBPM
            self.cadenceSPM = cadenceSPM
            self.isPaused = isPaused
        }
    }

    /// Path drawing payload for phone/watch UI. This intentionally does not assume map tiles.
    public struct RoutePath: Codable, Equatable, Sendable {
        public let points: [RunSample]
        public let sourceSampleCount: Int
        public let hasPoorGPS: Bool

        public init(points: [RunSample], sourceSampleCount: Int? = nil, hasPoorGPS: Bool = false) {
            self.points = points
            self.sourceSampleCount = sourceSampleCount ?? points.count
            self.hasPoorGPS = hasPoorGPS
        }
    }

    /// Summary metrics shown in watch and phone-first workout surfaces.
    public struct WorkoutMetrics: Codable, Equatable, Sendable {
        public let distanceMeters: Double
        public let elapsedSeconds: Int
        public let movingSeconds: Int
        public let currentPaceSecondsPerKM: Int?
        public let averagePaceSecondsPerKM: Int?
        public let averageHeartRateBPM: Double?
        public let averageCadenceSPM: Int?
        public let elevationGainMeters: Int

        public init(
            distanceMeters: Double,
            elapsedSeconds: Int,
            movingSeconds: Int,
            currentPaceSecondsPerKM: Int? = nil,
            averagePaceSecondsPerKM: Int? = nil,
            averageHeartRateBPM: Double? = nil,
            averageCadenceSPM: Int? = nil,
            elevationGainMeters: Int = 0
        ) {
            self.distanceMeters = distanceMeters
            self.elapsedSeconds = elapsedSeconds
            self.movingSeconds = movingSeconds
            self.currentPaceSecondsPerKM = currentPaceSecondsPerKM
            self.averagePaceSecondsPerKM = averagePaceSecondsPerKM
            self.averageHeartRateBPM = averageHeartRateBPM
            self.averageCadenceSPM = averageCadenceSPM
            self.elevationGainMeters = elevationGainMeters
        }
    }

    /// Durable archive that must be written on watch before sync is attempted.
    public struct WorkoutArchiveEnvelope: Codable, Equatable, Identifiable, Sendable {
        public let id: UUID
        public let schemaVersion: Int
        public let runID: UUID
        public let startedAt: Date
        public let endedAt: Date
        public let source: String
        public let metrics: WorkoutMetrics
        public let routePath: RoutePath
        public let createdOnDevice: String
        public let previousCoreArchiveID: String?

        public init(
            id: UUID = UUID(),
            schemaVersion: Int = 1,
            runID: UUID,
            startedAt: Date,
            endedAt: Date,
            source: String,
            metrics: WorkoutMetrics,
            routePath: RoutePath,
            createdOnDevice: String,
            previousCoreArchiveID: String? = nil
        ) {
            self.id = id
            self.schemaVersion = schemaVersion
            self.runID = runID
            self.startedAt = startedAt
            self.endedAt = endedAt
            self.source = source
            self.metrics = metrics
            self.routePath = routePath
            self.createdOnDevice = createdOnDevice
            self.previousCoreArchiveID = previousCoreArchiveID
        }
    }

    /// Post-run resource remains unassigned until the user spends it.
    public struct RunResource: Codable, Equatable, Identifiable, Sendable {
        public let id: UUID
        public let archiveID: UUID
        public let liveCompanionID: String?
        public let isSpent: Bool

        public init(id: UUID = UUID(), archiveID: UUID, liveCompanionID: String? = nil, isSpent: Bool = false) {
            self.id = id
            self.archiveID = archiveID
            self.liveCompanionID = liveCompanionID
            self.isSpent = isSpent
        }
    }
}
