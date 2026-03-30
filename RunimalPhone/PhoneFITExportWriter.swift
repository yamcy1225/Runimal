import FitDataProtocol
import Foundation
import RunimalCore

enum PhoneFITExportWriter {
    static func data(
        for archive: WorkoutSessionArchive,
        title: String,
        timeBasis: WorkoutExportTimeBasis = .timer
    ) throws -> Data {
        let fileID = FileIdMessage(
            deviceSerialNumber: nil,
            fileCreationDate: FitTime(date: archive.endedAt),
            manufacturer: nil,
            product: 1,
            fileNumber: fileNumber(for: archive),
            fileType: .activity,
            productName: title
        )

        let messages = buildMessages(for: archive, timeBasis: timeBasis)
        let encoder = FitFileEncoder(dataValidityStrategy: .none)

        switch encoder.encode(fildIdMessage: fileID, messages: messages) {
        case .success(let data):
            return data
        case .failure(let error):
            throw error
        }
    }
}

private extension PhoneFITExportWriter {
    static func buildMessages(for archive: WorkoutSessionArchive, timeBasis: WorkoutExportTimeBasis) -> [FitMessage] {
        var messages: [FitMessage] = []
        messages.append(EventMessage(timeStamp: FitTime(date: archive.startedAt), event: .timer, eventType: .start, eventGroup: 0))
        messages.append(contentsOf: fitEvents(from: archive.events))
        messages.append(contentsOf: fitRecords(from: archive))
        messages.append(contentsOf: fitLaps(from: archive, timeBasis: timeBasis))
        messages.append(fitSession(from: archive, timeBasis: timeBasis))
        messages.append(fitActivity(from: archive))
        return messages
    }

    static func fitEvents(from events: [WorkoutSessionEvent]) -> [FitMessage] {
        events.compactMap { event in
            switch event.kind {
            case .start:
                return nil
            case .pause:
                return EventMessage(timeStamp: FitTime(date: event.timestamp), event: .timer, eventType: .stop, eventGroup: 0)
            case .resume:
                return EventMessage(timeStamp: FitTime(date: event.timestamp), event: .timer, eventType: .start, eventGroup: 0)
            case .lap:
                return EventMessage(timeStamp: FitTime(date: event.timestamp), event: .lap, eventType: .stop, eventGroup: 0)
            case .end:
                return EventMessage(timeStamp: FitTime(date: event.timestamp), event: .timer, eventType: .stopAll, eventGroup: 0)
            }
        }
    }

    static func fitRecords(from archive: WorkoutSessionArchive) -> [FitMessage] {
        var totalDistance: Double = 0
        var records: [FitMessage] = []

        for index in archive.trackPoints.indices {
            let point = archive.trackPoints[index]
            if index > 0 {
                let previous = archive.trackPoints[index - 1]
                let segmentDistance = workoutCoordinateDistance(from: previous, to: point)
                let delta = point.timestamp.timeIntervalSince(previous.timestamp)
                let speed = point.speedMetersPerSecond ?? (delta > 0 ? segmentDistance / delta : 0)
                if workoutExportUsableSegment(previous: previous, current: point, distance: segmentDistance, speed: speed) {
                    totalDistance += segmentDistance
                }
            }

            records.append(
                RecordMessage(
                    timeStamp: FitTime(date: point.timestamp),
                    position: position(for: point),
                    distance: Measurement(value: totalDistance, unit: UnitLength.meters),
                    altitude: Measurement(value: point.altitude, unit: UnitLength.meters),
                    speed: point.speedMetersPerSecond.map { Measurement(value: $0, unit: UnitSpeed.metersPerSecond) },
                    gpsAccuracy: Measurement(value: point.horizontalAccuracy, unit: UnitLength.meters),
                    heartRate: point.heartRate.map { UInt8(clamping: Int($0.rounded())) },
                    cadence: point.cadence.map { UInt8(clamping: $0) }
                )
            )
        }

        return records
    }

    static func fitLaps(from archive: WorkoutSessionArchive, timeBasis: WorkoutExportTimeBasis) -> [FitMessage] {
        archive.laps.map { lap in
            let lapPoints = archive.trackPoints.filter { $0.timestamp >= lap.startTime && $0.timestamp <= lap.endTime }
            let lapDurationSeconds = exportDurationSeconds(for: lap, points: lapPoints, timeBasis: timeBasis)
            return LapMessage(
                timeStamp: FitTime(date: lap.endTime),
                event: .lap,
                eventType: .stop,
                startTime: FitTime(date: lap.startTime),
                startPosition: lapPoints.first.map(position(for:)),
                endPosition: lapPoints.last.map(position(for:)),
                totalElapsedTime: Measurement(value: lap.endTime.timeIntervalSince(lap.startTime), unit: UnitDuration.seconds),
                totalTimerTime: Measurement(value: Double(lap.timerTimeSeconds), unit: UnitDuration.seconds),
                totalDistance: Measurement(value: lap.distanceMeters, unit: UnitLength.meters),
                averageSpeed: averageSpeed(distanceMeters: lap.distanceMeters, durationSeconds: lapDurationSeconds),
                averageHeartRate: lap.averageHeartRate.map { UInt8(clamping: Int($0.rounded())) },
                averageCadence: lap.averageCadence.map { UInt8(clamping: $0) },
                totalAscent: Measurement(value: Double(lap.elevationGainM), unit: UnitLength.meters),
                lapTrigger: lap.index == archive.laps.count ? .sessionEnd : .distance
            )
        }
    }

    static func fitSession(from archive: WorkoutSessionArchive, timeBasis: WorkoutExportTimeBasis) -> FitMessage {
        let maxHeartRate = archive.trackPoints.compactMap(\.heartRate).max().map { UInt8(clamping: Int($0.rounded())) }
        let maxCadence = archive.trackPoints.compactMap(\.cadence).max().map { UInt8(clamping: $0) }
        let maxSpeed = archive.trackPoints.compactMap(\.speedMetersPerSecond).max().map { Measurement(value: $0, unit: UnitSpeed.metersPerSecond) }
        let exportDuration = exportDurationSeconds(for: archive, timeBasis: timeBasis)

        return SessionMessage(
            timeStamp: FitTime(date: archive.endedAt),
            event: .session,
            eventType: .stop,
            startTime: FitTime(date: archive.startedAt),
            startPosition: archive.trackPoints.first.map(position(for:)),
            totalElapsedTime: Measurement(value: Double(archive.elapsedTimeSeconds), unit: UnitDuration.seconds),
            totalTimerTime: Measurement(value: Double(archive.timerTimeSeconds), unit: UnitDuration.seconds),
            totalDistance: Measurement(value: archive.distanceMeters, unit: UnitLength.meters),
            averageSpeed: averageSpeed(distanceMeters: archive.distanceMeters, durationSeconds: exportDuration),
            maximumSpeed: maxSpeed,
            averageHeartRate: archive.averageHeartRate.map { UInt8(clamping: Int($0.rounded())) },
            maximumHeartRate: maxHeartRate,
            averageCadence: archive.averageCadence.map { UInt8(clamping: $0) },
            maximumCadence: maxCadence,
            totalAscent: Measurement(value: Double(archive.elevationGainM), unit: UnitLength.meters),
            firstLapIndex: archive.laps.isEmpty ? nil : 0,
            numberOfLaps: UInt16(clamping: archive.laps.count),
            totalMovingTime: Measurement(value: Double(archive.movingTimeSeconds), unit: UnitDuration.seconds)
        )
    }

    static func fitActivity(from archive: WorkoutSessionArchive) -> FitMessage {
        ActivityMessage(
            timeStamp: FitTime(date: archive.endedAt),
            totalTimerTime: Measurement(value: Double(archive.timerTimeSeconds), unit: UnitDuration.seconds),
            localTimeStamp: FitTime(date: archive.endedAt, isLocal: true),
            numberOfSessions: 1,
            activity: .manual,
            event: .activity,
            eventType: .stop,
            eventGroup: 0
        )
    }

    static func position(for point: WorkoutTrackPoint) -> Position {
        Position(
            latitude: Measurement(value: point.latitude, unit: UnitAngle.degrees),
            longitude: Measurement(value: point.longitude, unit: UnitAngle.degrees)
        )
    }

    static func averageSpeed(distanceMeters: Double, durationSeconds: Int) -> Measurement<UnitSpeed>? {
        guard distanceMeters > 0, durationSeconds > 0 else { return nil }
        return Measurement(value: distanceMeters / Double(durationSeconds), unit: UnitSpeed.metersPerSecond)
    }

    static func fileNumber(for archive: WorkoutSessionArchive) -> UInt16 {
        UInt16(abs(archive.runID.hashValue) % Int(UInt16.max))
    }
}
