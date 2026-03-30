import Foundation

public struct WorkoutCanonicalMetrics: Equatable, Sendable {
    public let distanceMeters: Double
    public let movingTimeSeconds: Int
    public let elevationGainM: Int
    public let averagePaceSeconds: Int?

    public init(
        distanceMeters: Double,
        movingTimeSeconds: Int,
        elevationGainM: Int,
        averagePaceSeconds: Int?
    ) {
        self.distanceMeters = distanceMeters
        self.movingTimeSeconds = movingTimeSeconds
        self.elevationGainM = elevationGainM
        self.averagePaceSeconds = averagePaceSeconds
    }
}

public enum WorkoutArchiveCanonicalizer {
    private static let maxDisplayPointCount = 72
    private static let maxHorizontalAccuracy = 30.0
    private static let maxSegmentDistanceMeters = 120.0
    private static let minSegmentDistanceMeters = 1.0
    private static let maxSegmentSpeedMetersPerSecond = 8.5
    private static let minMovingSpeedMetersPerSecond = 0.5

    public static func canonicalize(
        _ archive: WorkoutSessionArchive,
        configuration: WorkoutArchiveAnalyzer.Configuration = .init()
    ) -> WorkoutSessionArchive {
        let rawTrackPoints = normalizedRawTrack(from: archive.effectiveRawTrackPoints)
        let filteredTrackPoints = filteredTrack(from: rawTrackPoints)
        let metrics = metrics(from: filteredTrackPoints, elapsedTimeSeconds: archive.elapsedTimeSeconds)
        let displayTrackPoints = displayRoute(from: filteredTrackPoints)

        let seedArchive = WorkoutSessionArchive(
            id: archive.id,
            runID: archive.runID,
            startedAt: archive.startedAt,
            endedAt: archive.endedAt,
            elapsedTimeSeconds: archive.elapsedTimeSeconds,
            timerTimeSeconds: archive.timerTimeSeconds > 0 ? archive.timerTimeSeconds : archive.elapsedTimeSeconds,
            movingTimeSeconds: metrics.movingTimeSeconds > 0 ? metrics.movingTimeSeconds : archive.movingTimeSeconds,
            distanceMeters: metrics.distanceMeters > 0 ? metrics.distanceMeters : archive.distanceMeters,
            averageHeartRate: archive.averageHeartRate,
            averageCadence: archive.averageCadence,
            averagePaceSeconds: metrics.averagePaceSeconds ?? archive.averagePaceSeconds,
            elevationGainM: metrics.elevationGainM > 0 ? metrics.elevationGainM : archive.elevationGainM,
            source: archive.source,
            trackPoints: rawTrackPoints,
            rawTrackPoints: rawTrackPoints,
            displayTrackPoints: displayTrackPoints,
            laps: archive.laps,
            events: archive.events
        )

        return WorkoutArchiveAnalyzer.enrich(seedArchive, configuration: configuration)
    }

    public static func displayRoute(from points: [WorkoutTrackPoint]) -> [RoutePoint] {
        let filteredTrackPoints = filteredTrack(from: points)
        guard filteredTrackPoints.count > 2 else {
            return filteredTrackPoints.map(routePoint(from:))
        }

        let limit = min(maxDisplayPointCount, filteredTrackPoints.count)
        guard filteredTrackPoints.count > limit else {
            return filteredTrackPoints.map(routePoint(from:))
        }

        let lastIndex = filteredTrackPoints.count - 1
        let stride = Double(lastIndex) / Double(limit - 1)
        var sampledRoute: [RoutePoint] = []
        sampledRoute.reserveCapacity(limit)

        for index in 0..<limit {
            let pointIndex = min(Int((Double(index) * stride).rounded()), lastIndex)
            let routePoint = routePoint(from: filteredTrackPoints[pointIndex])
            if sampledRoute.last != routePoint {
                sampledRoute.append(routePoint)
            }
        }

        return sampledRoute
    }

    public static func update(
        _ record: CompletedRunRecord,
        with archive: WorkoutSessionArchive
    ) -> CompletedRunRecord {
        CompletedRunRecord(
            id: record.id,
            startedAt: archive.startedAt,
            endedAt: archive.endedAt,
            distanceMeters: archive.distanceMeters > 0 ? archive.distanceMeters : record.distanceMeters,
            durationSeconds: archive.timerTimeSeconds > 0 ? archive.timerTimeSeconds : record.durationSeconds,
            averageHeartRate: archive.averageHeartRate ?? record.averageHeartRate,
            averagePaceSeconds: archive.averagePaceSeconds ?? record.averagePaceSeconds,
            cadence: archive.averageCadence ?? record.cadence,
            elevationGainM: archive.elevationGainM > 0 ? archive.elevationGainM : record.elevationGainM,
            reward: record.reward,
            route: archive.effectiveDisplayTrackPoints.isEmpty ? record.route : archive.effectiveDisplayTrackPoints,
            source: record.source,
            sourceLabel: record.sourceLabel,
            raidContribution: record.raidContribution,
            environmentCondition: record.environmentCondition,
            rareEventCompleted: record.rareEventCompleted
        )
    }

    public static func normalizedRawTrack(from points: [WorkoutTrackPoint]) -> [WorkoutTrackPoint] {
        let sortedPoints = points.sorted { $0.timestamp < $1.timestamp }
        guard sortedPoints.count > 1 else { return sortedPoints }

        var normalizedTrack: [WorkoutTrackPoint] = []
        normalizedTrack.reserveCapacity(sortedPoints.count)

        for point in sortedPoints {
            guard point.latitude.isFinite, point.longitude.isFinite, point.altitude.isFinite else { continue }
            guard point.horizontalAccuracy.isFinite, point.horizontalAccuracy >= 0 else { continue }
            if let previous = normalizedTrack.last,
               point.timestamp <= previous.timestamp,
               point.latitude == previous.latitude,
               point.longitude == previous.longitude {
                continue
            }
            normalizedTrack.append(point)
        }

        return normalizedTrack
    }

    public static func metrics(
        from points: [WorkoutTrackPoint],
        elapsedTimeSeconds: Int
    ) -> WorkoutCanonicalMetrics {
        guard points.count > 1 else {
            return WorkoutCanonicalMetrics(
                distanceMeters: 0,
                movingTimeSeconds: 0,
                elevationGainM: 0,
                averagePaceSeconds: nil
            )
        }

        var distanceMeters: Double = 0
        var movingTime: TimeInterval = 0
        var elevationGainMeters: Double = 0

        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let delta = current.timestamp.timeIntervalSince(previous.timestamp)
            guard delta > 0 else { continue }

            let segmentDistance = workoutCoordinateDistance(from: previous, to: current)
            let segmentSpeed = current.speedMetersPerSecond ?? (segmentDistance / delta)

            guard workoutExportUsableSegment(
                previous: previous,
                current: current,
                distance: segmentDistance,
                speed: segmentSpeed
            ) else { continue }

            distanceMeters += segmentDistance
            if segmentSpeed >= minMovingSpeedMetersPerSecond {
                movingTime += delta
            }

            let climb = current.altitude - previous.altitude
            if climb > 0.5, climb <= 40 {
                elevationGainMeters += climb
            }
        }

        let averagePaceSeconds: Int?
        if distanceMeters > 0, elapsedTimeSeconds > 0 {
            averagePaceSeconds = Int((Double(elapsedTimeSeconds) / (distanceMeters / 1_000)).rounded())
        } else {
            averagePaceSeconds = nil
        }

        return WorkoutCanonicalMetrics(
            distanceMeters: distanceMeters,
            movingTimeSeconds: max(Int(movingTime.rounded()), 0),
            elevationGainM: max(Int(elevationGainMeters.rounded()), 0),
            averagePaceSeconds: averagePaceSeconds
        )
    }

    private static func filteredTrack(from points: [WorkoutTrackPoint]) -> [WorkoutTrackPoint] {
        let rawTrack = normalizedRawTrack(from: points)
        guard rawTrack.count > 1 else { return rawTrack }

        var filteredTrack: [WorkoutTrackPoint] = []
        filteredTrack.reserveCapacity(rawTrack.count)

        for point in rawTrack {
            guard point.horizontalAccuracy <= maxHorizontalAccuracy else { continue }
            guard let previous = filteredTrack.last else {
                filteredTrack.append(markGPSQuality(on: point))
                continue
            }

            let delta = point.timestamp.timeIntervalSince(previous.timestamp)
            guard delta > 0 else { continue }

            let segmentDistance = workoutCoordinateDistance(from: previous, to: point)
            let segmentSpeed = point.speedMetersPerSecond ?? (segmentDistance / delta)
            guard segmentDistance >= minSegmentDistanceMeters else { continue }
            guard segmentDistance <= maxSegmentDistanceMeters else { continue }
            guard segmentSpeed <= maxSegmentSpeedMetersPerSecond else { continue }
            filteredTrack.append(markGPSQuality(on: point))
        }

        return filteredTrack
    }

    private static func routePoint(from point: WorkoutTrackPoint) -> RoutePoint {
        RoutePoint(
            latitude: point.latitude,
            longitude: point.longitude,
            altitude: point.altitude,
            timestamp: point.timestamp
        )
    }

    private static func markGPSQuality(on point: WorkoutTrackPoint) -> WorkoutTrackPoint {
        WorkoutTrackPoint(
            timestamp: point.timestamp,
            latitude: point.latitude,
            longitude: point.longitude,
            altitude: point.altitude,
            horizontalAccuracy: point.horizontalAccuracy,
            speedMetersPerSecond: point.speedMetersPerSecond,
            heartRate: point.heartRate,
            cadence: point.cadence,
            gpsPoor: point.horizontalAccuracy > maxHorizontalAccuracy,
            paused: point.paused
        )
    }
}
