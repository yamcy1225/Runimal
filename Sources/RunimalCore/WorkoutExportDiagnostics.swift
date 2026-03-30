import Foundation

public struct WorkoutExportFormatSummary: Sendable {
    public let format: WorkoutExportFormat
    public let pointCount: Int
    public let segmentDistanceMeters: Double
    public let includesPausedSamples: Bool
    public let containerCount: Int
    public let containerLabel: String

    public init(
        format: WorkoutExportFormat,
        pointCount: Int,
        segmentDistanceMeters: Double,
        includesPausedSamples: Bool,
        containerCount: Int,
        containerLabel: String
    ) {
        self.format = format
        self.pointCount = pointCount
        self.segmentDistanceMeters = segmentDistanceMeters
        self.includesPausedSamples = includesPausedSamples
        self.containerCount = containerCount
        self.containerLabel = containerLabel
    }
}

public func workoutExportFormatSummary(
    for archive: WorkoutSessionArchive,
    format: WorkoutExportFormat
) -> WorkoutExportFormatSummary {
    switch format {
    case .gpx:
        return WorkoutExportFormatSummary(
            format: format,
            pointCount: archive.trackPoints.filter { $0.gpsPoor == false }.count,
            segmentDistanceMeters: exportUsableSegmentDistanceMeters(from: archive.trackPoints),
            includesPausedSamples: true,
            containerCount: 1,
            containerLabel: "trkseg 1개"
        )
    case .tcx:
        let trackCount = exportTrackSegmentCount(from: archive.trackPoints)
        return WorkoutExportFormatSummary(
            format: format,
            pointCount: archive.trackPoints.filter { $0.paused == false && $0.gpsPoor == false }.count,
            segmentDistanceMeters: exportUsableSegmentDistanceMeters(from: archive.trackPoints),
            includesPausedSamples: false,
            containerCount: trackCount,
            containerLabel: "track \(trackCount)개"
        )
    case .fit:
        return WorkoutExportFormatSummary(
            format: format,
            pointCount: archive.trackPoints.count,
            segmentDistanceMeters: exportUsableSegmentDistanceMeters(from: archive.trackPoints),
            includesPausedSamples: true,
            containerCount: archive.events.count + 1,
            containerLabel: "event \(archive.events.count + 1)개"
        )
    }
}

public func exportAveragePaceSeconds(
    for archive: WorkoutSessionArchive,
    timeBasis: WorkoutExportTimeBasis
) -> Int? {
    let duration = exportDurationSeconds(for: archive, timeBasis: timeBasis)
    guard archive.distanceMeters > 0, duration > 0 else { return nil }
    return Int((Double(duration) / (archive.distanceMeters / 1000)).rounded())
}

public func exportUsableSegmentDistanceMeters(from points: [WorkoutTrackPoint]) -> Double {
    guard points.count > 1 else { return 0 }

    var totalDistance: Double = 0
    for index in 1..<points.count {
        let previous = points[index - 1]
        let current = points[index]
        let segmentDistance = workoutCoordinateDistance(from: previous, to: current)
        let delta = current.timestamp.timeIntervalSince(previous.timestamp)
        let speed = current.speedMetersPerSecond ?? (delta > 0 ? segmentDistance / delta : 0)

        if workoutExportUsableSegment(
            previous: previous,
            current: current,
            distance: segmentDistance,
            speed: speed
        ) {
            totalDistance += segmentDistance
        }
    }

    return totalDistance
}

public func exportTrackSegmentCount(from points: [WorkoutTrackPoint]) -> Int {
    guard !points.isEmpty else { return 0 }

    var segments = 0
    var isInsideTrack = false

    for point in points {
        if point.paused || point.gpsPoor {
            isInsideTrack = false
            continue
        }

        if isInsideTrack == false {
            segments += 1
            isInsideTrack = true
        }
    }

    return segments
}

public func workoutMovingTimeSeconds(from points: [WorkoutTrackPoint]) -> Int {
    guard points.count > 1 else { return 0 }

    var moving: TimeInterval = 0
    for index in 1..<points.count {
        let previous = points[index - 1]
        let current = points[index]
        let delta = current.timestamp.timeIntervalSince(previous.timestamp)
        guard delta > 0, current.paused == false else { continue }

        let distance = workoutCoordinateDistance(from: previous, to: current)
        let speed = current.speedMetersPerSecond ?? distance / delta
        if workoutExportUsableSegment(previous: previous, current: current, distance: distance, speed: speed),
           speed >= 0.5 {
            moving += delta
        }
    }

    return Int(moving.rounded())
}

public func workoutCoordinateDistance(from lhs: WorkoutTrackPoint, to rhs: WorkoutTrackPoint) -> Double {
    let earthRadius = 6_371_000.0
    let lat1 = lhs.latitude * .pi / 180
    let lon1 = lhs.longitude * .pi / 180
    let lat2 = rhs.latitude * .pi / 180
    let lon2 = rhs.longitude * .pi / 180
    let dLat = lat2 - lat1
    let dLon = lon2 - lon1
    let a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
    let c = 2 * atan2(sqrt(a), sqrt(1 - a))
    return earthRadius * c
}

public func workoutExportUsableSegment(
    previous: WorkoutTrackPoint,
    current: WorkoutTrackPoint,
    distance: Double,
    speed: Double
) -> Bool {
    guard previous.paused == false, current.paused == false else { return false }
    guard previous.gpsPoor == false, current.gpsPoor == false else { return false }
    guard distance >= 1, distance <= 120 else { return false }
    guard speed >= 0, speed <= 8.5 else { return false }
    return true
}
