import Foundation

public enum WorkoutExportFormat: String, CaseIterable, Sendable {
    case gpx = "gpx"
    case tcx = "tcx"
    case fit = "fit"

    public var fileExtension: String { rawValue }
    public var displayName: String { rawValue.uppercased() }
}

public enum WorkoutExportTimeBasis: String, CaseIterable, Identifiable, Sendable {
    case elapsed
    case timer
    case moving

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .elapsed: return "전체"
        case .timer: return "운동"
        case .moving: return "이동"
        }
    }
}

public enum GPXWriter {
    public static func data(for archive: WorkoutSessionArchive, title: String, timeBasis: WorkoutExportTimeBasis = .timer) -> Data {
        let points = archive.effectiveRawTrackPoints
        let formatter = ISO8601DateFormatter()
        var lines: [String] = []
        lines.append(#"<?xml version="1.0" encoding="UTF-8"?>"#)
        lines.append(#"<gpx version="1.1" creator="Runimal" xmlns="http://www.topografix.com/GPX/1/1" xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1">"#)
        lines.append("<metadata><name>\(escaped(title))</name><time>\(formatter.string(from: archive.startedAt))</time></metadata>")
        lines.append("<trk><name>\(escaped(title))</name><trkseg>")

        for point in points where point.gpsPoor == false {
            lines.append(#"<trkpt lat="\#(point.latitude)" lon="\#(point.longitude)">"#)
            lines.append("<ele>\(point.altitude)</ele>")
            lines.append("<time>\(formatter.string(from: point.timestamp))</time>")
            if point.heartRate != nil || point.cadence != nil {
                lines.append("<extensions><gpxtpx:TrackPointExtension>")
                if let heartRate = point.heartRate {
                    lines.append("<gpxtpx:hr>\(Int(heartRate.rounded()))</gpxtpx:hr>")
                }
                if let cadence = point.cadence {
                    lines.append("<gpxtpx:cad>\(cadence)</gpxtpx:cad>")
                }
                lines.append("</gpxtpx:TrackPointExtension></extensions>")
            }
            lines.append("</trkpt>")
        }

        lines.append("</trkseg></trk></gpx>")
        return Data(lines.joined().utf8)
    }
}

public enum TCXWriter {
    public static func data(for archive: WorkoutSessionArchive, title: String, timeBasis: WorkoutExportTimeBasis = .timer) -> Data {
        let points = archive.effectiveRawTrackPoints
        let formatter = ISO8601DateFormatter()
        let sport = "Running"
        let laps = archive.laps.isEmpty ? [
            WorkoutLap(
                index: 1,
                startTime: archive.startedAt,
                endTime: archive.endedAt,
                distanceMeters: archive.distanceMeters,
                timerTimeSeconds: archive.timerTimeSeconds,
                averageHeartRate: archive.averageHeartRate,
                averageCadence: archive.averageCadence,
                averagePaceSeconds: archive.averagePaceSeconds,
                elevationGainM: archive.elevationGainM
            )
        ] : archive.laps

        var lines: [String] = []
        lines.append(#"<?xml version="1.0" encoding="UTF-8"?>"#)
        lines.append(#"<TrainingCenterDatabase xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">"#)
        lines.append("<Activities>")
        lines.append(#"<Activity Sport="\#(sport)">"#)
        lines.append("<Id>\(formatter.string(from: archive.startedAt))</Id>")

        for lap in laps {
            let lapPoints = points.filter { $0.timestamp >= lap.startTime && $0.timestamp <= lap.endTime }
            let lapTimeSeconds = exportDurationSeconds(for: lap, points: lapPoints, timeBasis: timeBasis)
            lines.append(#"<Lap StartTime="\#(formatter.string(from: lap.startTime))">"#)
            lines.append("<TotalTimeSeconds>\(lapTimeSeconds)</TotalTimeSeconds>")
            lines.append("<DistanceMeters>\(lap.distanceMeters)</DistanceMeters>")
            if let heartRate = lap.averageHeartRate {
                lines.append("<AverageHeartRateBpm><Value>\(Int(heartRate.rounded()))</Value></AverageHeartRateBpm>")
            }
            if let cadence = lap.averageCadence {
                lines.append("<Cadence>\(cadence)</Cadence>")
            }
            lines.append(contentsOf: trackLines(for: lapPoints, formatter: formatter))
            lines.append("</Lap>")
        }

        lines.append("<Notes>\(escaped(title))</Notes>")
        lines.append("</Activity>")
        lines.append("</Activities>")
        lines.append("</TrainingCenterDatabase>")
        return Data(lines.joined().utf8)
    }
}

public func exportDurationSeconds(for archive: WorkoutSessionArchive, timeBasis: WorkoutExportTimeBasis) -> Int {
    switch timeBasis {
    case .elapsed:
        return archive.elapsedTimeSeconds
    case .timer:
        return archive.timerTimeSeconds
    case .moving:
        return archive.movingTimeSeconds
    }
}

public func exportDurationSeconds(
    for lap: WorkoutLap,
    points: [WorkoutTrackPoint],
    timeBasis: WorkoutExportTimeBasis
) -> Int {
    switch timeBasis {
    case .elapsed:
        return max(Int(lap.endTime.timeIntervalSince(lap.startTime).rounded()), 0)
    case .timer:
        return lap.timerTimeSeconds
    case .moving:
        return movingTimeSeconds(for: points)
    }
}

private func escaped(_ text: String) -> String {
    text
        .replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
        .replacingOccurrences(of: "\"", with: "&quot;")
        .replacingOccurrences(of: "'", with: "&apos;")
}

private func trackLines(for points: [WorkoutTrackPoint], formatter: ISO8601DateFormatter) -> [String] {
    guard !points.isEmpty else { return ["<Track></Track>"] }

    var lines: [String] = []
    var didOpenTrack = false

    for point in points {
        if point.paused || point.gpsPoor {
            if didOpenTrack {
                lines.append("</Track>")
                didOpenTrack = false
            }
            continue
        }

        if didOpenTrack == false {
            lines.append("<Track>")
            didOpenTrack = true
        }

        lines.append("<Trackpoint>")
        lines.append("<Time>\(formatter.string(from: point.timestamp))</Time>")
        lines.append("<Position><LatitudeDegrees>\(point.latitude)</LatitudeDegrees><LongitudeDegrees>\(point.longitude)</LongitudeDegrees></Position>")
        lines.append("<AltitudeMeters>\(point.altitude)</AltitudeMeters>")
        if let heartRate = point.heartRate {
            lines.append("<HeartRateBpm><Value>\(Int(heartRate.rounded()))</Value></HeartRateBpm>")
        }
        if let cadence = point.cadence {
            lines.append("<Cadence>\(cadence)</Cadence>")
        }
        lines.append("</Trackpoint>")
    }

    if didOpenTrack {
        lines.append("</Track>")
    }

    return lines
}

private func movingTimeSeconds(for points: [WorkoutTrackPoint]) -> Int {
    workoutMovingTimeSeconds(from: points)
}
