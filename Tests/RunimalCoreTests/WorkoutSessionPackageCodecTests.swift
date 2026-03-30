import Foundation
import Testing
@testable import RunimalCore

struct WorkoutSessionPackageCodecTests {
    @Test
    func packageRoundTripsArchiveComponents() throws {
        let startedAt = Date(timeIntervalSince1970: 1_710_000_000)
        let archive = WorkoutSessionArchive(
            id: "archive-1",
            runID: "run-1",
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(900),
            elapsedTimeSeconds: 900,
            timerTimeSeconds: 894,
            movingTimeSeconds: 812,
            distanceMeters: 5_240,
            averageHeartRate: 154,
            averageCadence: 171,
            averagePaceSeconds: 298,
            elevationGainM: 42,
            source: "watch-package-test",
            trackPoints: [
                WorkoutTrackPoint(
                    timestamp: startedAt,
                    latitude: 37.0,
                    longitude: 127.0,
                    altitude: 18,
                    horizontalAccuracy: 5,
                    speedMetersPerSecond: 2.8,
                    heartRate: 148,
                    cadence: 170,
                    gpsPoor: false,
                    paused: false
                ),
                WorkoutTrackPoint(
                    timestamp: startedAt.addingTimeInterval(5),
                    latitude: 37.0003,
                    longitude: 127.0002,
                    altitude: 19,
                    horizontalAccuracy: 7,
                    speedMetersPerSecond: nil,
                    heartRate: nil,
                    cadence: nil,
                    gpsPoor: true,
                    paused: true
                )
            ],
            laps: [
                WorkoutLap(
                    index: 1,
                    startTime: startedAt,
                    endTime: startedAt.addingTimeInterval(900),
                    distanceMeters: 5_240,
                    timerTimeSeconds: 894,
                    averageHeartRate: 154,
                    averageCadence: 171,
                    averagePaceSeconds: 298,
                    elevationGainM: 42
                )
            ],
            events: [
                WorkoutSessionEvent(kind: .start, timestamp: startedAt),
                WorkoutSessionEvent(kind: .pause, timestamp: startedAt.addingTimeInterval(300), detail: "auto"),
                WorkoutSessionEvent(kind: .resume, timestamp: startedAt.addingTimeInterval(320), detail: "auto"),
                WorkoutSessionEvent(kind: .end, timestamp: startedAt.addingTimeInterval(900))
            ]
        )

        let rebuilt = try WorkoutSessionPackageCodec.archive(
            summaryData: WorkoutSessionPackageCodec.summaryData(for: archive),
            rawTrackData: WorkoutSessionPackageCodec.rawTrackData(for: archive),
            eventsData: WorkoutSessionPackageCodec.eventsData(for: archive),
            lapsData: WorkoutSessionPackageCodec.lapsData(for: archive)
        )

        #expect(rebuilt.id == archive.id)
        #expect(rebuilt.runID == archive.runID)
        #expect(rebuilt.effectiveRawTrackPoints == archive.effectiveRawTrackPoints)
        #expect(rebuilt.events == archive.events)
        #expect(rebuilt.laps == archive.laps)
    }
}
