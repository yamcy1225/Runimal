import Foundation

public enum WorkoutArchiveAnalyzer {
    public struct Configuration: Sendable {
        public var lapDistanceMeters: Double
        public var pauseSpeedThreshold: Double
        public var pauseHoldSeconds: TimeInterval
        public var resumeSpeedThreshold: Double
        public var resumeHoldSeconds: TimeInterval
        public var movingSpeedThreshold: Double

        public init(
            lapDistanceMeters: Double = 1_000,
            pauseSpeedThreshold: Double = 0.5,
            pauseHoldSeconds: TimeInterval = 6,
            resumeSpeedThreshold: Double = 1.0,
            resumeHoldSeconds: TimeInterval = 3,
            movingSpeedThreshold: Double = 0.5
        ) {
            self.lapDistanceMeters = lapDistanceMeters
            self.pauseSpeedThreshold = pauseSpeedThreshold
            self.pauseHoldSeconds = pauseHoldSeconds
            self.resumeSpeedThreshold = resumeSpeedThreshold
            self.resumeHoldSeconds = resumeHoldSeconds
            self.movingSpeedThreshold = movingSpeedThreshold
        }
    }

    public static func enrich(
        _ archive: WorkoutSessionArchive,
        configuration: Configuration = .init()
    ) -> WorkoutSessionArchive {
        let sortedPoints = archive.trackPoints.sorted { $0.timestamp < $1.timestamp }
        guard sortedPoints.count > 1 else { return archive }

        let explicitPauseWindows = pauseWindows(from: archive.events, endedAt: archive.endedAt)
        let enrichedPoints = applyPauseDetection(
            to: sortedPoints,
            explicitPauseWindows: explicitPauseWindows,
            configuration: configuration
        )
        let metrics = buildMetrics(from: enrichedPoints, configuration: configuration)
        let laps = buildLaps(
            from: enrichedPoints,
            startedAt: archive.startedAt,
            endedAt: archive.endedAt,
            configuration: configuration
        )

        var events = archive.events
        events.append(contentsOf: metrics.inferredEvents)
        events.append(contentsOf: laps.map { WorkoutSessionEvent(kind: .lap, timestamp: $0.endTime, detail: "lap-\($0.index)") })
        events = deduplicated(events).sorted { $0.timestamp < $1.timestamp }

        return WorkoutSessionArchive(
            id: archive.id,
            runID: archive.runID,
            startedAt: archive.startedAt,
            endedAt: archive.endedAt,
            elapsedTimeSeconds: archive.elapsedTimeSeconds,
            timerTimeSeconds: metrics.timerTimeSeconds,
            movingTimeSeconds: metrics.movingTimeSeconds,
            distanceMeters: archive.distanceMeters > 0 ? archive.distanceMeters : metrics.distanceMeters,
            averageHeartRate: archive.averageHeartRate ?? averageDouble(from: enrichedPoints.compactMap(\.heartRate)),
            averageCadence: archive.averageCadence ?? averageInt(from: enrichedPoints.compactMap(\.cadence)),
            averagePaceSeconds: metrics.averagePaceSeconds ?? archive.averagePaceSeconds,
            elevationGainM: archive.elevationGainM > 0 ? archive.elevationGainM : Int(metrics.elevationGainMeters.rounded()),
            source: archive.source,
            trackPoints: enrichedPoints,
            laps: laps.isEmpty ? archive.laps : laps,
            events: events
        )
    }
}

private struct ArchiveMetrics {
    let timerTimeSeconds: Int
    let movingTimeSeconds: Int
    let distanceMeters: Double
    let elevationGainMeters: Double
    let averagePaceSeconds: Int?
    let inferredEvents: [WorkoutSessionEvent]
}

private extension WorkoutArchiveAnalyzer {
    static func pauseWindows(from events: [WorkoutSessionEvent], endedAt: Date) -> [ClosedRange<Date>] {
        let sorted = events.sorted { $0.timestamp < $1.timestamp }
        var windows: [ClosedRange<Date>] = []
        var pauseStartedAt: Date?

        for event in sorted {
            switch event.kind {
            case .pause:
                pauseStartedAt = event.timestamp
            case .resume, .end:
                if let pauseStartedAt, event.timestamp > pauseStartedAt {
                    windows.append(pauseStartedAt...event.timestamp)
                }
                pauseStartedAt = nil
            default:
                break
            }
        }

        if let pauseStartedAt, endedAt > pauseStartedAt {
            windows.append(pauseStartedAt...endedAt)
        }

        return windows
    }

    static func applyPauseDetection(
        to points: [WorkoutTrackPoint],
        explicitPauseWindows: [ClosedRange<Date>],
        configuration: Configuration
    ) -> [WorkoutTrackPoint] {
        var enriched: [WorkoutTrackPoint] = []
        enriched.reserveCapacity(points.count)

        var detectedPause = false
        var slowWindow: TimeInterval = 0
        var fastWindow: TimeInterval = 0
        var inferredEvents: [WorkoutSessionEvent] = []

        for index in points.indices {
            let point = points[index]
            let delta = index == 0 ? 0 : point.timestamp.timeIntervalSince(points[index - 1].timestamp)
            let segmentSpeed = resolvedSpeed(current: point, previous: index == 0 ? nil : points[index - 1], delta: delta)
            let explicitlyPaused = explicitPauseWindows.contains { $0.contains(point.timestamp) }

            if explicitlyPaused {
                detectedPause = true
            } else if point.gpsPoor == false, delta > 0 {
                if detectedPause {
                    if segmentSpeed >= configuration.resumeSpeedThreshold {
                        fastWindow += delta
                    } else {
                        fastWindow = 0
                    }
                    if fastWindow >= configuration.resumeHoldSeconds {
                        detectedPause = false
                        fastWindow = 0
                        slowWindow = 0
                        inferredEvents.append(WorkoutSessionEvent(kind: .resume, timestamp: point.timestamp, detail: "auto"))
                    }
                } else {
                    if segmentSpeed <= configuration.pauseSpeedThreshold {
                        slowWindow += delta
                    } else {
                        slowWindow = 0
                    }
                    if slowWindow >= configuration.pauseHoldSeconds {
                        detectedPause = true
                        slowWindow = 0
                        fastWindow = 0
                        inferredEvents.append(WorkoutSessionEvent(kind: .pause, timestamp: point.timestamp, detail: "auto"))
                    }
                }
            }

            let paused = explicitlyPaused || detectedPause || point.paused
            enriched.append(
                WorkoutTrackPoint(
                    timestamp: point.timestamp,
                    latitude: point.latitude,
                    longitude: point.longitude,
                    altitude: point.altitude,
                    horizontalAccuracy: point.horizontalAccuracy,
                    speedMetersPerSecond: point.speedMetersPerSecond ?? (segmentSpeed > 0 ? segmentSpeed : nil),
                    heartRate: point.heartRate,
                    cadence: point.cadence,
                    gpsPoor: point.gpsPoor,
                    paused: paused
                )
            )
        }

        _ = inferredEvents
        return enriched
    }

    static func buildMetrics(from points: [WorkoutTrackPoint], configuration: Configuration) -> ArchiveMetrics {
        guard points.count > 1 else {
            return ArchiveMetrics(
                timerTimeSeconds: 0,
                movingTimeSeconds: 0,
                distanceMeters: 0,
                elevationGainMeters: 0,
                averagePaceSeconds: nil,
                inferredEvents: []
            )
        }

        var timerTime: TimeInterval = 0
        var movingTime: TimeInterval = 0
        var distance: Double = 0
        var elevation: Double = 0
        var inferredEvents: [WorkoutSessionEvent] = []
        var previousPaused = points.first?.paused ?? false

        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let delta = current.timestamp.timeIntervalSince(previous.timestamp)
            guard delta > 0 else { continue }

            let segmentDistance = coordinateDistance(from: previous, to: current)
            let segmentSpeed = resolvedSpeed(current: current, previous: previous, delta: delta)

            if current.paused != previousPaused {
                inferredEvents.append(
                    WorkoutSessionEvent(
                        kind: current.paused ? .pause : .resume,
                        timestamp: current.timestamp,
                        detail: "derived"
                    )
                )
                previousPaused = current.paused
            }

            if current.paused == false {
                timerTime += delta
                if isUsableSegment(
                    previous: previous,
                    current: current,
                    distance: segmentDistance,
                    speed: segmentSpeed
                ) {
                    distance += segmentDistance
                }
                if isUsableSegment(
                    previous: previous,
                    current: current,
                    distance: segmentDistance,
                    speed: segmentSpeed
                ), segmentSpeed >= configuration.movingSpeedThreshold {
                    movingTime += delta
                }
                let climb = current.altitude - previous.altitude
                if climb > 0.5, abs(climb) <= 40 {
                    elevation += climb
                }
            }
        }

        let averagePace = distance > 0 ? Int((timerTime / distance) * 1000.0) : nil
        return ArchiveMetrics(
            timerTimeSeconds: Int(timerTime.rounded()),
            movingTimeSeconds: Int(movingTime.rounded()),
            distanceMeters: distance,
            elevationGainMeters: elevation,
            averagePaceSeconds: averagePace,
            inferredEvents: deduplicated(inferredEvents)
        )
    }

    static func buildLaps(
        from points: [WorkoutTrackPoint],
        startedAt: Date,
        endedAt: Date,
        configuration: Configuration
    ) -> [WorkoutLap] {
        guard points.count > 1 else { return [] }

        var laps: [WorkoutLap] = []
        var lapStartIndex = 0
        var lapDistance: Double = 0
        var lapTimer: TimeInterval = 0
        var lapElevation: Double = 0
        var totalDistance: Double = 0
        var nextLapTarget = configuration.lapDistanceMeters

        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let delta = current.timestamp.timeIntervalSince(previous.timestamp)
            guard delta > 0 else { continue }

            let rawDistance = coordinateDistance(from: previous, to: current)
            let segmentSpeed = resolvedSpeed(current: current, previous: previous, delta: delta)
            let segmentDistance = current.paused ? 0 : (
                isUsableSegment(
                    previous: previous,
                    current: current,
                    distance: rawDistance,
                    speed: segmentSpeed
                ) ? rawDistance : 0
            )
            totalDistance += segmentDistance
            lapDistance += segmentDistance
            if current.paused == false {
                lapTimer += delta
            }
            let climb = current.altitude - previous.altitude
            if climb > 0.5, abs(climb) <= 40, current.paused == false {
                lapElevation += climb
            }

            if totalDistance >= nextLapTarget {
                laps.append(makeLap(points: points, startIndex: lapStartIndex, endIndex: index, index: laps.count + 1, distance: lapDistance, timer: lapTimer, elevation: lapElevation))
                lapStartIndex = index
                lapDistance = 0
                lapTimer = 0
                lapElevation = 0
                nextLapTarget += configuration.lapDistanceMeters
            }
        }

        if lapStartIndex < points.count - 1 {
            let endIndex = points.count - 1
            let remainingDistance = max(lapDistance, totalDistance == 0 ? 0 : 1)
            if remainingDistance > 0 {
                laps.append(makeLap(points: points, startIndex: lapStartIndex, endIndex: endIndex, index: laps.count + 1, distance: lapDistance, timer: lapTimer, elevation: lapElevation))
            }
        }

        if laps.isEmpty {
            laps.append(makeLap(points: points, startIndex: 0, endIndex: points.count - 1, index: 1, distance: totalDistance, timer: TimeInterval(points.last?.timestamp.timeIntervalSince(points.first?.timestamp ?? startedAt) ?? endedAt.timeIntervalSince(startedAt)), elevation: 0))
        }

        return laps
    }

    static func makeLap(
        points: [WorkoutTrackPoint],
        startIndex: Int,
        endIndex: Int,
        index: Int,
        distance: Double,
        timer: TimeInterval,
        elevation: Double
    ) -> WorkoutLap {
        let lapPoints = Array(points[startIndex...endIndex])
        let metricPoints = lapPoints.filter { $0.paused == false && $0.gpsPoor == false }
        let averageHeartRate = averageDouble(from: metricPoints.compactMap(\.heartRate))
        let averageCadence = averageInt(from: metricPoints.compactMap(\.cadence))
        let averagePaceSeconds = distance > 0 ? Int((timer / distance) * 1000.0) : nil

        return WorkoutLap(
            index: index,
            startTime: lapPoints.first?.timestamp ?? Date(),
            endTime: lapPoints.last?.timestamp ?? Date(),
            distanceMeters: distance,
            timerTimeSeconds: Int(timer.rounded()),
            averageHeartRate: averageHeartRate,
            averageCadence: averageCadence,
            averagePaceSeconds: averagePaceSeconds,
            elevationGainM: Int(elevation.rounded())
        )
    }
}

private func isUsableSegment(
    previous: WorkoutTrackPoint,
    current: WorkoutTrackPoint,
    distance: Double,
    speed: Double
) -> Bool {
    guard previous.gpsPoor == false, current.gpsPoor == false else { return false }
    guard distance >= 1, distance <= 120 else { return false }
    guard speed >= 0, speed <= 8.5 else { return false }
    return true
}

private func resolvedSpeed(current: WorkoutTrackPoint, previous: WorkoutTrackPoint?, delta: TimeInterval) -> Double {
    if let speed = current.speedMetersPerSecond, speed >= 0 {
        return speed
    }
    guard let previous, delta > 0 else { return 0 }
    return coordinateDistance(from: previous, to: current) / delta
}

private func coordinateDistance(from lhs: WorkoutTrackPoint, to rhs: WorkoutTrackPoint) -> Double {
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

private func averageDouble(from values: [Double]) -> Double? {
    guard !values.isEmpty else { return nil }
    return values.reduce(0, +) / Double(values.count)
}

private func averageInt(from values: [Int]) -> Int? {
    guard !values.isEmpty else { return nil }
    return Int((Double(values.reduce(0, +)) / Double(values.count)).rounded())
}

private func deduplicated(_ events: [WorkoutSessionEvent]) -> [WorkoutSessionEvent] {
    var seen: Set<String> = []
    var result: [WorkoutSessionEvent] = []
    for event in events {
        let key = "\(event.kind.rawValue)-\(Int(event.timestamp.timeIntervalSince1970))-\(event.detail ?? "")"
        if seen.insert(key).inserted {
            result.append(event)
        }
    }
    return result
}
