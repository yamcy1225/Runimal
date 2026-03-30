import XCTest
@testable import RunimalCore

final class WorkoutArchiveCanonicalizerTests: XCTestCase {
    func testCanonicalizePopulatesRawAndDisplayTracksAndRecomputesDistance() {
        let startedAt = Date(timeIntervalSince1970: 10_000)
        let rawPoints = [
            makePoint(offset: 0, lat: 37.0, lon: 127.0, accuracy: 8),
            makePoint(offset: 5, lat: 37.00005, lon: 127.00005, accuracy: 45),
            makePoint(offset: 10, lat: 37.00010, lon: 127.00010, accuracy: 8),
            makePoint(offset: 15, lat: 37.00011, lon: 127.00011, accuracy: 8)
        ]
        let archive = WorkoutSessionArchive(
            runID: "run-1",
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(15),
            elapsedTimeSeconds: 15,
            timerTimeSeconds: 15,
            movingTimeSeconds: 0,
            distanceMeters: 0,
            averageHeartRate: 150,
            averageCadence: 172,
            averagePaceSeconds: nil,
            elevationGainM: 0,
            source: "watch-healthkit",
            trackPoints: rawPoints,
            laps: [],
            events: [.init(kind: .start, timestamp: startedAt), .init(kind: .end, timestamp: startedAt.addingTimeInterval(15))]
        )

        let canonicalArchive = WorkoutArchiveCanonicalizer.canonicalize(archive)

        XCTAssertEqual(canonicalArchive.effectiveRawTrackPoints.count, 4)
        XCTAssertFalse(canonicalArchive.effectiveDisplayTrackPoints.isEmpty)
        XCTAssertGreaterThan(canonicalArchive.distanceMeters, 0)
        XCTAssertEqual(canonicalArchive.displayTrackPoints, canonicalArchive.effectiveDisplayTrackPoints)
    }

    func testUpdateUsesDisplayTrackForCompletedRunPreview() {
        let startedAt = Date(timeIntervalSince1970: 20_000)
        let displayRoute = [
            RoutePoint(latitude: 37.1, longitude: 127.1, altitude: 12, timestamp: startedAt),
            RoutePoint(latitude: 37.1005, longitude: 127.1005, altitude: 14, timestamp: startedAt.addingTimeInterval(10))
        ]
        let archive = WorkoutSessionArchive(
            runID: "run-2",
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(600),
            elapsedTimeSeconds: 600,
            timerTimeSeconds: 590,
            movingTimeSeconds: 580,
            distanceMeters: 1_600,
            averageHeartRate: 148,
            averageCadence: 174,
            averagePaceSeconds: 369,
            elevationGainM: 24,
            source: "watch-healthkit",
            trackPoints: [makePoint(offset: 0, lat: 37.1, lon: 127.1, accuracy: 8)],
            rawTrackPoints: [makePoint(offset: 0, lat: 37.1, lon: 127.1, accuracy: 8)],
            displayTrackPoints: displayRoute,
            laps: [],
            events: []
        )
        let reward = RunRewardSummary(
            pet: GeneratedPet(
                species: .windrunner,
                element: .light,
                palette: "mist",
                rareVariant: nil,
                explanation: [],
                stats: PetStats(vitality: 1, agility: 2, dexterity: 3, focus: 4, defense: 5)
            ),
            coreLabel: "steady",
            experience: 120,
            completedQuestCount: 1,
            flavorText: "done"
        )
        let record = CompletedRunRecord(
            id: "run-2",
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(600),
            distanceMeters: 1_400,
            durationSeconds: 600,
            averageHeartRate: 145,
            averagePaceSeconds: 400,
            cadence: 170,
            elevationGainM: 12,
            reward: reward,
            route: [],
            source: "watch-healthkit"
        )

        let updatedRecord = WorkoutArchiveCanonicalizer.update(record, with: archive)

        XCTAssertEqual(updatedRecord.route, displayRoute)
        XCTAssertEqual(updatedRecord.distanceMeters, archive.distanceMeters)
        XCTAssertEqual(updatedRecord.durationSeconds, archive.timerTimeSeconds)
    }

    private func makePoint(offset: TimeInterval, lat: Double, lon: Double, accuracy: Double) -> WorkoutTrackPoint {
        WorkoutTrackPoint(
            timestamp: Date(timeIntervalSince1970: 10_000 + offset),
            latitude: lat,
            longitude: lon,
            altitude: 12,
            horizontalAccuracy: accuracy,
            speedMetersPerSecond: 3.2,
            heartRate: 150,
            cadence: 172,
            gpsPoor: accuracy > 30,
            paused: false
        )
    }
}
