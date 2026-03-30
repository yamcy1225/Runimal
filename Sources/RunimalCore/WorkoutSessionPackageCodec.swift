import Foundation

public enum WorkoutSessionPackageFileKind: String, CaseIterable, Codable, Sendable {
    case summary
    case rawTrack
    case events
    case laps

    public var filename: String {
        switch self {
        case .summary:
            return "summary.json"
        case .rawTrack:
            return "rawTrack.bin"
        case .events:
            return "events.json"
        case .laps:
            return "laps.json"
        }
    }
}

public struct WorkoutSessionPackageSummary: Codable, Equatable, Sendable {
    public let archiveID: String
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
    public let rawTrackPointCount: Int
    public let eventCount: Int
    public let lapCount: Int

    public init(archive: WorkoutSessionArchive) {
        self.archiveID = archive.id
        self.runID = archive.runID
        self.startedAt = archive.startedAt
        self.endedAt = archive.endedAt
        self.elapsedTimeSeconds = archive.elapsedTimeSeconds
        self.timerTimeSeconds = archive.timerTimeSeconds
        self.movingTimeSeconds = archive.movingTimeSeconds
        self.distanceMeters = archive.distanceMeters
        self.averageHeartRate = archive.averageHeartRate
        self.averageCadence = archive.averageCadence
        self.averagePaceSeconds = archive.averagePaceSeconds
        self.elevationGainM = archive.elevationGainM
        self.source = archive.source
        self.rawTrackPointCount = archive.effectiveRawTrackPoints.count
        self.eventCount = archive.events.count
        self.lapCount = archive.laps.count
    }
}

public enum WorkoutSessionPackageCodec {
    public enum Error: Swift.Error {
        case invalidHeader
        case unsupportedVersion(UInt8)
        case truncatedPayload
        case invalidPointCount(Int)
        case pointCountMismatch(expected: Int, actual: Int)
        case eventCountMismatch(expected: Int, actual: Int)
        case lapCountMismatch(expected: Int, actual: Int)
    }

    private static let binaryMagic: UInt32 = 0x52544B31
    private static let binaryVersion: UInt8 = 1
    private static let pointByteWidth = 8 + 8 + 8 + 8 + 8 + 8 + 8 + 4 + 1

    public static func summaryData(for archive: WorkoutSessionArchive) throws -> Data {
        try makeJSONEncoder().encode(WorkoutSessionPackageSummary(archive: archive))
    }

    public static func eventsData(for archive: WorkoutSessionArchive) throws -> Data {
        try makeJSONEncoder().encode(archive.events)
    }

    public static func lapsData(for archive: WorkoutSessionArchive) throws -> Data {
        try makeJSONEncoder().encode(archive.laps)
    }

    public static func rawTrackData(for archive: WorkoutSessionArchive) throws -> Data {
        try encodeRawTrack(archive.effectiveRawTrackPoints)
    }

    public static func decodeSummary(from data: Data) throws -> WorkoutSessionPackageSummary {
        try makeJSONDecoder().decode(WorkoutSessionPackageSummary.self, from: data)
    }

    public static func decodeEvents(from data: Data) throws -> [WorkoutSessionEvent] {
        try makeJSONDecoder().decode([WorkoutSessionEvent].self, from: data)
    }

    public static func decodeLaps(from data: Data) throws -> [WorkoutLap] {
        try makeJSONDecoder().decode([WorkoutLap].self, from: data)
    }

    public static func decodeRawTrack(from data: Data) throws -> [WorkoutTrackPoint] {
        var cursor = DataCursor(data: data)
        let magic = try cursor.read(UInt32.self)
        guard magic == binaryMagic else {
            throw Error.invalidHeader
        }

        let version = try cursor.read(UInt8.self)
        guard version == binaryVersion else {
            throw Error.unsupportedVersion(version)
        }

        let pointCount = Int(try cursor.read(UInt32.self))
        guard pointCount >= 0 else {
            throw Error.invalidPointCount(pointCount)
        }

        let expectedBytes = pointCount * pointByteWidth
        guard cursor.remainingCount == expectedBytes else {
            throw Error.truncatedPayload
        }

        var points: [WorkoutTrackPoint] = []
        points.reserveCapacity(pointCount)

        for _ in 0..<pointCount {
            let timestamp = Date(timeIntervalSince1970: try cursor.read(Double.self))
            let latitude = try cursor.read(Double.self)
            let longitude = try cursor.read(Double.self)
            let altitude = try cursor.read(Double.self)
            let horizontalAccuracy = try cursor.read(Double.self)
            let rawSpeed = try cursor.read(Double.self)
            let rawHeartRate = try cursor.read(Double.self)
            let cadenceValue = Int(try cursor.read(Int32.self))
            let flags = try cursor.read(UInt8.self)
            points.append(
                WorkoutTrackPoint(
                    timestamp: timestamp,
                    latitude: latitude,
                    longitude: longitude,
                    altitude: altitude,
                    horizontalAccuracy: horizontalAccuracy,
                    speedMetersPerSecond: rawSpeed.isNaN ? nil : rawSpeed,
                    heartRate: rawHeartRate.isNaN ? nil : rawHeartRate,
                    cadence: cadenceValue < 0 ? nil : cadenceValue,
                    gpsPoor: (flags & 1) != 0,
                    paused: (flags & 2) != 0
                )
            )
        }

        return points
    }

    public static func archive(
        summaryData: Data,
        rawTrackData: Data,
        eventsData: Data,
        lapsData: Data
    ) throws -> WorkoutSessionArchive {
        let summary = try decodeSummary(from: summaryData)
        let rawTrack = try decodeRawTrack(from: rawTrackData)
        let events = try decodeEvents(from: eventsData)
        let laps = try decodeLaps(from: lapsData)

        guard rawTrack.count == summary.rawTrackPointCount else {
            throw Error.pointCountMismatch(expected: summary.rawTrackPointCount, actual: rawTrack.count)
        }
        guard events.count == summary.eventCount else {
            throw Error.eventCountMismatch(expected: summary.eventCount, actual: events.count)
        }
        guard laps.count == summary.lapCount else {
            throw Error.lapCountMismatch(expected: summary.lapCount, actual: laps.count)
        }

        return WorkoutSessionArchive(
            id: summary.archiveID,
            runID: summary.runID,
            startedAt: summary.startedAt,
            endedAt: summary.endedAt,
            elapsedTimeSeconds: summary.elapsedTimeSeconds,
            timerTimeSeconds: summary.timerTimeSeconds,
            movingTimeSeconds: summary.movingTimeSeconds,
            distanceMeters: summary.distanceMeters,
            averageHeartRate: summary.averageHeartRate,
            averageCadence: summary.averageCadence,
            averagePaceSeconds: summary.averagePaceSeconds,
            elevationGainM: summary.elevationGainM,
            source: summary.source,
            trackPoints: rawTrack,
            rawTrackPoints: rawTrack,
            displayTrackPoints: [],
            laps: laps,
            events: events
        )
    }

    private static func encodeRawTrack(_ points: [WorkoutTrackPoint]) throws -> Data {
        var data = Data()
        append(binaryMagic, to: &data)
        append(binaryVersion, to: &data)
        append(UInt32(points.count), to: &data)

        for point in points {
            append(point.timestamp.timeIntervalSince1970, to: &data)
            append(point.latitude, to: &data)
            append(point.longitude, to: &data)
            append(point.altitude, to: &data)
            append(point.horizontalAccuracy, to: &data)
            append(point.speedMetersPerSecond ?? .nan, to: &data)
            append(point.heartRate ?? .nan, to: &data)
            append(Int32(point.cadence ?? -1), to: &data)
            var flags: UInt8 = 0
            if point.gpsPoor { flags |= 1 }
            if point.paused { flags |= 2 }
            append(flags, to: &data)
        }

        return data
    }

    private static func makeJSONEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        return encoder
    }

    private static func makeJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return decoder
    }

    private static func append<T>(_ value: T, to data: inout Data) {
        var littleEndianValue = value
        withUnsafeBytes(of: &littleEndianValue) { buffer in
            data.append(buffer.bindMemory(to: UInt8.self))
        }
    }
}

private struct DataCursor {
    let data: Data
    var offset = 0

    var remainingCount: Int {
        data.count - offset
    }

    mutating func read<T>(_ type: T.Type) throws -> T {
        let size = MemoryLayout<T>.size
        guard offset + size <= data.count else {
            throw WorkoutSessionPackageCodec.Error.truncatedPayload
        }

        let value = data.withUnsafeBytes { rawBuffer in
            rawBuffer.loadUnaligned(fromByteOffset: offset, as: T.self)
        }
        offset += size
        return value
    }
}
