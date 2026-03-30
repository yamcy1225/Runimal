import Foundation

public struct WorkoutTrackPoint: Codable, Equatable, Identifiable, Sendable {
    public let timestamp: Date
    public let latitude: Double
    public let longitude: Double
    public let altitude: Double
    public let horizontalAccuracy: Double
    public let speedMetersPerSecond: Double?
    public let heartRate: Double?
    public let cadence: Int?
    public let gpsPoor: Bool
    public let paused: Bool

    public var id: String {
        "\(timestamp.timeIntervalSince1970)-\(latitude)-\(longitude)"
    }

    public init(
        timestamp: Date,
        latitude: Double,
        longitude: Double,
        altitude: Double,
        horizontalAccuracy: Double,
        speedMetersPerSecond: Double?,
        heartRate: Double?,
        cadence: Int?,
        gpsPoor: Bool,
        paused: Bool
    ) {
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.speedMetersPerSecond = speedMetersPerSecond
        self.heartRate = heartRate
        self.cadence = cadence
        self.gpsPoor = gpsPoor
        self.paused = paused
    }
}

public struct WorkoutLap: Codable, Equatable, Identifiable, Sendable {
    public let index: Int
    public let startTime: Date
    public let endTime: Date
    public let distanceMeters: Double
    public let timerTimeSeconds: Int
    public let averageHeartRate: Double?
    public let averageCadence: Int?
    public let averagePaceSeconds: Int?
    public let elevationGainM: Int

    public var id: String {
        "lap-\(index)"
    }

    public init(
        index: Int,
        startTime: Date,
        endTime: Date,
        distanceMeters: Double,
        timerTimeSeconds: Int,
        averageHeartRate: Double?,
        averageCadence: Int?,
        averagePaceSeconds: Int?,
        elevationGainM: Int
    ) {
        self.index = index
        self.startTime = startTime
        self.endTime = endTime
        self.distanceMeters = distanceMeters
        self.timerTimeSeconds = timerTimeSeconds
        self.averageHeartRate = averageHeartRate
        self.averageCadence = averageCadence
        self.averagePaceSeconds = averagePaceSeconds
        self.elevationGainM = elevationGainM
    }
}

public enum WorkoutEventKind: String, Codable, CaseIterable, Sendable {
    case start
    case pause
    case resume
    case lap
    case end
}

public struct WorkoutSessionEvent: Codable, Equatable, Identifiable, Sendable {
    public let kind: WorkoutEventKind
    public let timestamp: Date
    public let detail: String?

    public var id: String {
        "\(kind.rawValue)-\(timestamp.timeIntervalSince1970)"
    }

    public init(kind: WorkoutEventKind, timestamp: Date, detail: String? = nil) {
        self.kind = kind
        self.timestamp = timestamp
        self.detail = detail
    }
}

public struct WorkoutSessionArchive: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let runID: String
    public let startedAt: Date
    public let endedAt: Date
    public let elapsedTimeSeconds: Int
    public let timerTimeSeconds: Int
    public let movingTimeSeconds: Int
    public let distanceMeters: Double
    public let averageHeartRate: Double?
    public let averageCadence: Int?
    public let averagePaceSeconds: Int?
    public let elevationGainM: Int
    public let source: String
    public let trackPoints: [WorkoutTrackPoint]
    public let rawTrackPoints: [WorkoutTrackPoint]
    public let displayTrackPoints: [RoutePoint]
    public let laps: [WorkoutLap]
    public let events: [WorkoutSessionEvent]

    public init(
        id: String = UUID().uuidString,
        runID: String,
        startedAt: Date,
        endedAt: Date,
        elapsedTimeSeconds: Int,
        timerTimeSeconds: Int,
        movingTimeSeconds: Int,
        distanceMeters: Double,
        averageHeartRate: Double?,
        averageCadence: Int?,
        averagePaceSeconds: Int?,
        elevationGainM: Int,
        source: String,
        trackPoints: [WorkoutTrackPoint],
        rawTrackPoints: [WorkoutTrackPoint]? = nil,
        displayTrackPoints: [RoutePoint] = [],
        laps: [WorkoutLap],
        events: [WorkoutSessionEvent]
    ) {
        let resolvedRawTrackPoints = rawTrackPoints ?? trackPoints
        self.id = id
        self.runID = runID
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.elapsedTimeSeconds = elapsedTimeSeconds
        self.timerTimeSeconds = timerTimeSeconds
        self.movingTimeSeconds = movingTimeSeconds
        self.distanceMeters = distanceMeters
        self.averageHeartRate = averageHeartRate
        self.averageCadence = averageCadence
        self.averagePaceSeconds = averagePaceSeconds
        self.elevationGainM = elevationGainM
        self.source = source
        self.trackPoints = trackPoints.isEmpty ? resolvedRawTrackPoints : trackPoints
        self.rawTrackPoints = resolvedRawTrackPoints
        self.displayTrackPoints = displayTrackPoints
        self.laps = laps
        self.events = events
    }

    public var effectiveRawTrackPoints: [WorkoutTrackPoint] {
        rawTrackPoints.isEmpty ? trackPoints : rawTrackPoints
    }

    public var effectiveDisplayTrackPoints: [RoutePoint] {
        displayTrackPoints.isEmpty
            ? WorkoutArchiveCanonicalizer.displayRoute(from: effectiveRawTrackPoints)
            : displayTrackPoints
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case runID
        case startedAt
        case endedAt
        case elapsedTimeSeconds
        case timerTimeSeconds
        case movingTimeSeconds
        case distanceMeters
        case averageHeartRate
        case averageCadence
        case averagePaceSeconds
        case elevationGainM
        case source
        case trackPoints
        case rawTrackPoints
        case displayTrackPoints
        case laps
        case events
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        runID = try container.decode(String.self, forKey: .runID)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        endedAt = try container.decode(Date.self, forKey: .endedAt)
        elapsedTimeSeconds = try container.decode(Int.self, forKey: .elapsedTimeSeconds)
        timerTimeSeconds = try container.decode(Int.self, forKey: .timerTimeSeconds)
        movingTimeSeconds = try container.decode(Int.self, forKey: .movingTimeSeconds)
        distanceMeters = try container.decode(Double.self, forKey: .distanceMeters)
        averageHeartRate = try container.decodeIfPresent(Double.self, forKey: .averageHeartRate)
        averageCadence = try container.decodeIfPresent(Int.self, forKey: .averageCadence)
        averagePaceSeconds = try container.decodeIfPresent(Int.self, forKey: .averagePaceSeconds)
        elevationGainM = try container.decode(Int.self, forKey: .elevationGainM)
        source = try container.decode(String.self, forKey: .source)
        let decodedTrackPoints = try container.decodeIfPresent([WorkoutTrackPoint].self, forKey: .trackPoints) ?? []
        let decodedRawTrackPoints = try container.decodeIfPresent([WorkoutTrackPoint].self, forKey: .rawTrackPoints) ?? []
        trackPoints = decodedTrackPoints.isEmpty ? decodedRawTrackPoints : decodedTrackPoints
        rawTrackPoints = decodedRawTrackPoints.isEmpty ? trackPoints : decodedRawTrackPoints
        displayTrackPoints = try container.decodeIfPresent([RoutePoint].self, forKey: .displayTrackPoints) ?? []
        laps = try container.decodeIfPresent([WorkoutLap].self, forKey: .laps) ?? []
        events = try container.decodeIfPresent([WorkoutSessionEvent].self, forKey: .events) ?? []
    }
}
