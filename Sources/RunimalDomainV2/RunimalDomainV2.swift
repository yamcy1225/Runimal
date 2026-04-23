import Foundation

/// V2 domain namespace for the minimum reliable recording loop.
///
/// This module is intentionally UI- and transport-neutral. Watch/Phone adapters may
/// translate HealthKit, CoreLocation, WatchConnectivity, and RunimalCore records into
/// these types, but the domain models do not import those frameworks.
public enum RunimalDomainV2 {
    public static let schemaVersion = 1

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

    /// Stable identity for a single workout recording.
    public struct RunIdentity: Codable, Equatable, Hashable, Sendable {
        public let id: UUID
        public let sourceDeviceID: String
        public let source: String

        public init(id: UUID = UUID(), sourceDeviceID: String, source: String) {
            self.id = id
            self.sourceDeviceID = sourceDeviceID
            self.source = source
        }
    }

    /// GPS + sensor sample captured during a run.
    public struct RunSamplePoint: Codable, Equatable, Identifiable, Sendable {
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

        public var coordinate: Coordinate? {
            guard let latitude, let longitude else { return nil }
            return Coordinate(latitude: latitude, longitude: longitude)
        }

        public var isUsableGPS: Bool {
            guard let coordinate, coordinate.isValid else { return false }
            guard let horizontalAccuracyMeters else { return true }
            return horizontalAccuracyMeters <= RouteQualityPolicy.usableAccuracyMeters
        }
    }

    /// Backward-compatible name from the initial v2 skeleton.
    public typealias RunSample = RunSamplePoint

    public struct Coordinate: Codable, Equatable, Sendable {
        public let latitude: Double
        public let longitude: Double

        public init(latitude: Double, longitude: Double) {
            self.latitude = latitude
            self.longitude = longitude
        }

        public var isValid: Bool {
            (-90...90).contains(latitude) && (-180...180).contains(longitude)
        }
    }

    /// Raw and display path payload for path drawing. It deliberately avoids map-tile assumptions.
    public struct RoutePath: Codable, Equatable, Sendable {
        public let rawPoints: [RunSamplePoint]
        public let displayPoints: [RunSamplePoint]
        public let sourceSampleCount: Int
        public let qualitySummary: RouteQualitySummary

        public init(
            rawPoints: [RunSamplePoint],
            displayPoints: [RunSamplePoint]? = nil,
            sourceSampleCount: Int? = nil,
            qualitySummary: RouteQualitySummary? = nil
        ) {
            self.rawPoints = rawPoints
            self.displayPoints = displayPoints ?? RouteRenderer.displayPath(from: rawPoints)
            self.sourceSampleCount = sourceSampleCount ?? rawPoints.count
            self.qualitySummary = qualitySummary ?? RouteQualityAnalyzer.summarize(rawPoints)
        }

        /// Compatibility accessor for the first skeleton's `points` name.
        public var points: [RunSamplePoint] { displayPoints }
        public var hasPoorGPS: Bool { qualitySummary.quality == .degraded || qualitySummary.quality == .unusable }
        public var bounds: RouteBounds? { RouteBounds(points: displayPoints) }
    }

    /// Summary metrics shown in watch and phone workout surfaces.
    public struct RunMetricSummary: Codable, Equatable, Sendable {
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
            self.distanceMeters = max(0, distanceMeters)
            self.elapsedSeconds = max(0, elapsedSeconds)
            self.movingSeconds = max(0, movingSeconds)
            self.currentPaceSecondsPerKM = currentPaceSecondsPerKM
            self.averagePaceSecondsPerKM = averagePaceSecondsPerKM
            self.averageHeartRateBPM = averageHeartRateBPM
            self.averageCadenceSPM = averageCadenceSPM
            self.elevationGainMeters = max(0, elevationGainMeters)
        }

        public static func derive(from samples: [RunSamplePoint], elapsedSeconds: Int) -> Self {
            let movingSamples = samples.filter { !$0.isPaused }
            let distance = RouteRenderer.distanceMeters(for: movingSamples)
            let movingSeconds = movingDurationSeconds(for: movingSamples)
            let averagePace: Int? = distance > 0 ? Int((Double(max(movingSeconds, 1)) / (distance / 1_000)).rounded()) : nil
            let heartRates = movingSamples.compactMap(\.heartRateBPM)
            let cadences = movingSamples.compactMap(\.cadenceSPM)
            let elevationGain = elevationGainMeters(for: movingSamples)

            return RunMetricSummary(
                distanceMeters: distance,
                elapsedSeconds: elapsedSeconds,
                movingSeconds: movingSeconds,
                averagePaceSecondsPerKM: averagePace,
                averageHeartRateBPM: heartRates.isEmpty ? nil : heartRates.reduce(0, +) / Double(heartRates.count),
                averageCadenceSPM: cadences.isEmpty ? nil : Int((Double(cadences.reduce(0, +)) / Double(cadences.count)).rounded()),
                elevationGainMeters: elevationGain
            )
        }

        private static func movingDurationSeconds(for samples: [RunSamplePoint]) -> Int {
            guard let first = samples.first?.timestamp, let last = samples.last?.timestamp else { return 0 }
            return max(0, Int(last.timeIntervalSince(first).rounded()))
        }

        private static func elevationGainMeters(for samples: [RunSamplePoint]) -> Int {
            var gain = 0.0
            var previous = samples.first?.altitudeMeters
            for sample in samples.dropFirst() {
                guard let altitude = sample.altitudeMeters else { continue }
                if let previousAltitude = previous, altitude > previousAltitude {
                    gain += altitude - previousAltitude
                }
                previous = altitude
            }
            return Int(gain.rounded())
        }
    }

    /// Backward-compatible name from the initial v2 skeleton.
    public typealias WorkoutMetrics = RunMetricSummary

    /// Mutable in-memory recording draft. Watch adapters should persist a completed archive before sync.
    public struct RunSessionDraft: Codable, Equatable, Identifiable, Sendable {
        public let id: UUID
        public var state: RecordingState
        public let identity: RunIdentity
        public let startedAt: Date
        public var endedAt: Date?
        public var samples: [RunSamplePoint]
        public var liveCompanionID: String?

        public init(
            id: UUID = UUID(),
            state: RecordingState = .preparing,
            identity: RunIdentity,
            startedAt: Date,
            endedAt: Date? = nil,
            samples: [RunSamplePoint] = [],
            liveCompanionID: String? = nil
        ) {
            self.id = id
            self.state = state
            self.identity = identity
            self.startedAt = startedAt
            self.endedAt = endedAt
            self.samples = samples.sorted { $0.timestamp < $1.timestamp }
            self.liveCompanionID = liveCompanionID
        }

        public mutating func start() {
            state = .recording
        }

        public mutating func record(_ sample: RunSamplePoint) {
            samples.append(sample)
            samples.sort { $0.timestamp < $1.timestamp }
        }

        public mutating func finish(at endDate: Date) {
            endedAt = endDate
            state = .finishing
        }

        public func completedArchive(createdOnDevice deviceID: String) -> CompletedRunArchive? {
            guard let endedAt else { return nil }
            let elapsedSeconds = max(0, Int(endedAt.timeIntervalSince(startedAt).rounded()))
            return CompletedRunArchive(
                runID: identity.id,
                startedAt: startedAt,
                endedAt: endedAt,
                source: identity.source,
                metrics: RunMetricSummary.derive(from: samples, elapsedSeconds: elapsedSeconds),
                routePath: RoutePath(rawPoints: samples),
                createdOnDevice: deviceID,
                liveCompanionID: liveCompanionID
            )
        }
    }

    /// Durable archive that must be written on watch before sync is attempted.
    public struct CompletedRunArchive: Codable, Equatable, Identifiable, Sendable {
        public let id: UUID
        public let schemaVersion: Int
        public let runID: UUID
        public let startedAt: Date
        public let endedAt: Date
        public let source: String
        public let metrics: RunMetricSummary
        public let routePath: RoutePath
        public let createdOnDevice: String
        public let liveCompanionID: String?
        public let previousCoreArchiveID: String?

        public init(
            id: UUID = UUID(),
            schemaVersion: Int = RunimalDomainV2.schemaVersion,
            runID: UUID,
            startedAt: Date,
            endedAt: Date,
            source: String,
            metrics: RunMetricSummary,
            routePath: RoutePath,
            createdOnDevice: String,
            liveCompanionID: String? = nil,
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
            self.liveCompanionID = liveCompanionID
            self.previousCoreArchiveID = previousCoreArchiveID
        }
    }

    /// Backward-compatible name from the initial v2 skeleton.
    public typealias WorkoutArchiveEnvelope = CompletedRunArchive

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

    public enum RouteQuality: String, Codable, Sendable {
        case excellent
        case usable
        case degraded
        case unusable
    }

    public struct RouteQualitySummary: Codable, Equatable, Sendable {
        public let quality: RouteQuality
        public let totalPointCount: Int
        public let usablePointCount: Int
        public let poorAccuracyPointCount: Int
        public let gapCount: Int

        public init(
            quality: RouteQuality,
            totalPointCount: Int,
            usablePointCount: Int,
            poorAccuracyPointCount: Int,
            gapCount: Int
        ) {
            self.quality = quality
            self.totalPointCount = totalPointCount
            self.usablePointCount = usablePointCount
            self.poorAccuracyPointCount = poorAccuracyPointCount
            self.gapCount = gapCount
        }
    }

    public enum RouteQualityPolicy {
        public static let usableAccuracyMeters = 50.0
        public static let excellentAccuracyMeters = 15.0
        public static let maxExpectedGapSeconds = 20.0
    }

    public enum RouteQualityAnalyzer {
        public static func summarize(_ points: [RunSamplePoint]) -> RouteQualitySummary {
            let usable = points.filter(\.isUsableGPS)
            let poorAccuracy = points.filter { sample in
                guard sample.coordinate?.isValid == true, let accuracy = sample.horizontalAccuracyMeters else { return false }
                return accuracy > RouteQualityPolicy.usableAccuracyMeters
            }
            let excellentAccuracyCount = usable.filter { ($0.horizontalAccuracyMeters ?? 0) <= RouteQualityPolicy.excellentAccuracyMeters }.count
            let gaps = zip(points, points.dropFirst()).filter { previous, next in
                next.timestamp.timeIntervalSince(previous.timestamp) > RouteQualityPolicy.maxExpectedGapSeconds
            }.count

            let quality: RouteQuality
            if usable.isEmpty {
                quality = .unusable
            } else if usable.count == points.count, gaps == 0, excellentAccuracyCount >= max(1, usable.count / 2) {
                quality = .excellent
            } else if Double(usable.count) / Double(max(points.count, 1)) >= 0.75, gaps <= 1 {
                quality = .usable
            } else {
                quality = .degraded
            }

            return RouteQualitySummary(
                quality: quality,
                totalPointCount: points.count,
                usablePointCount: usable.count,
                poorAccuracyPointCount: poorAccuracy.count,
                gapCount: gaps
            )
        }
    }

    public struct RouteBounds: Codable, Equatable, Sendable {
        public let minimumLatitude: Double
        public let maximumLatitude: Double
        public let minimumLongitude: Double
        public let maximumLongitude: Double

        public init?(points: [RunSamplePoint]) {
            let coordinates = points.compactMap(\.coordinate).filter(\.isValid)
            guard let first = coordinates.first else { return nil }
            var minimumLatitude = first.latitude
            var maximumLatitude = first.latitude
            var minimumLongitude = first.longitude
            var maximumLongitude = first.longitude

            for coordinate in coordinates.dropFirst() {
                minimumLatitude = min(minimumLatitude, coordinate.latitude)
                maximumLatitude = max(maximumLatitude, coordinate.latitude)
                minimumLongitude = min(minimumLongitude, coordinate.longitude)
                maximumLongitude = max(maximumLongitude, coordinate.longitude)
            }

            self.minimumLatitude = minimumLatitude
            self.maximumLatitude = maximumLatitude
            self.minimumLongitude = minimumLongitude
            self.maximumLongitude = maximumLongitude
        }
    }

    public enum RouteRenderer {
        /// Produces a UI-safe path by keeping valid GPS points and dropping paused/no-coordinate samples.
        /// More aggressive simplification can be added after real route-density tests exist.
        public static func displayPath(from rawPoints: [RunSamplePoint]) -> [RunSamplePoint] {
            rawPoints
                .filter { !$0.isPaused }
                .filter { $0.coordinate?.isValid == true }
                .sorted { $0.timestamp < $1.timestamp }
        }

        public static func distanceMeters(for points: [RunSamplePoint]) -> Double {
            let coordinates = displayPath(from: points).compactMap(\.coordinate)
            guard coordinates.count > 1 else { return 0 }
            return zip(coordinates, coordinates.dropFirst()).reduce(0) { partial, pair in
                partial + haversineMeters(from: pair.0, to: pair.1)
            }
        }

        private static func haversineMeters(from start: Coordinate, to end: Coordinate) -> Double {
            let earthRadiusMeters = 6_371_000.0
            let startLatitude = start.latitude * .pi / 180
            let endLatitude = end.latitude * .pi / 180
            let deltaLatitude = (end.latitude - start.latitude) * .pi / 180
            let deltaLongitude = (end.longitude - start.longitude) * .pi / 180
            let a = sin(deltaLatitude / 2) * sin(deltaLatitude / 2)
                + cos(startLatitude) * cos(endLatitude) * sin(deltaLongitude / 2) * sin(deltaLongitude / 2)
            let c = 2 * atan2(sqrt(a), sqrt(1 - a))
            return earthRadiusMeters * c
        }
    }
}
