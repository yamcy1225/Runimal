import Foundation
import Testing
@testable import RunimalCore
@testable import RunimalDomainV2
@testable import RunimalWatchAdapterV2

struct RunimalWatchAdapterV2Tests {
    @Test
    func convertsWatchWorkoutArchiveIntoDurableV2Archive() throws {
        let archiveID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let runID = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
        let coreArchive = makeCoreArchive(id: archiveID.uuidString, runID: runID.uuidString)

        let converted = RunimalWatchAdapterV2.completedArchive(
            from: coreArchive,
            options: .init(sourceDeviceID: "watch-001", liveCompanionID: "companion-windrunner")
        )

        #expect(converted.id == archiveID)
        #expect(converted.runID == runID)
        #expect(converted.startedAt == coreArchive.startedAt)
        #expect(converted.endedAt == coreArchive.endedAt)
        #expect(converted.source == "watch-healthkit")
        #expect(converted.createdOnDevice == "watch-001")
        #expect(converted.liveCompanionID == "companion-windrunner")
        #expect(converted.previousCoreArchiveID == archiveID.uuidString)
        #expect(converted.metrics.distanceMeters == coreArchive.distanceMeters)
        #expect(converted.metrics.averageHeartRateBPM == 151)
        #expect(converted.metrics.averageCadenceSPM == 174)
        #expect(converted.metrics.averagePaceSecondsPerKM == 360)
    }

    @Test
    func preservesRawEvidenceAndUsesCanonicalDisplayRoute() throws {
        let coreArchive = makeCoreArchive(
            rawPoints: [
                track(offset: 0, latitude: 37.0, longitude: 127.0, accuracy: 8, paused: false),
                track(offset: 5, latitude: 37.0005, longitude: 127.0005, accuracy: 8, paused: true),
                track(offset: 10, latitude: 37.001, longitude: 127.001, accuracy: 8, paused: false),
            ],
            displayRoute: [
                RoutePoint(latitude: 37.0, longitude: 127.0, altitude: 10, timestamp: baseDate),
                RoutePoint(latitude: 37.001, longitude: 127.001, altitude: 12, timestamp: baseDate.addingTimeInterval(10)),
            ]
        )

        let converted = RunimalWatchAdapterV2.completedArchive(
            from: coreArchive,
            options: .init(sourceDeviceID: "watch-001")
        )

        #expect(converted.routePath.rawPoints.count == 3)
        #expect(converted.routePath.displayPoints.count == 2)
        #expect(converted.routePath.sourceSampleCount == 3)
        #expect(converted.routePath.rawPoints[1].isPaused)
        #expect(converted.routePath.displayPoints.allSatisfy { !$0.isPaused })
        #expect(converted.routePath.bounds?.minimumLatitude == 37.0)
        #expect(converted.routePath.bounds?.maximumLatitude == 37.001)
    }

    @Test
    func createsSyncEnvelopeForPhoneTransferWithoutRebuildingAppTargets() throws {
        let archiveID = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!
        let runID = UUID(uuidString: "77777777-7777-7777-7777-777777777777")!
        let coreArchive = makeCoreArchive(id: archiveID.uuidString, runID: runID.uuidString)

        let envelope = RunimalWatchAdapterV2.syncEnvelope(
            for: coreArchive,
            options: .init(sourceDeviceID: "watch-standalone")
        )

        #expect(envelope.archiveID == archiveID)
        #expect(envelope.runID == runID)
        #expect(envelope.sourceDeviceID == "watch-standalone")
        #expect(envelope.state == .readyToTransfer)
        #expect(envelope.payloadKind == .completedRunArchive)
    }

    @Test
    func nonUUIDCoreArchiveIDsMapDeterministically() throws {
        let coreArchive = makeCoreArchive(id: "legacy-archive-id", runID: "legacy-run-id")

        let first = RunimalWatchAdapterV2.completedArchive(
            from: coreArchive,
            options: .init(sourceDeviceID: "watch-001")
        )
        let second = RunimalWatchAdapterV2.completedArchive(
            from: coreArchive,
            options: .init(sourceDeviceID: "watch-001")
        )

        #expect(first.id == second.id)
        #expect(first.runID == second.runID)
        #expect(first.previousCoreArchiveID == "legacy-archive-id")
    }

    private var baseDate: Date { Date(timeIntervalSince1970: 10_000) }

    private func makeCoreArchive(
        id: String = UUID().uuidString,
        runID: String = UUID().uuidString,
        rawPoints: [WorkoutTrackPoint]? = nil,
        displayRoute: [RoutePoint] = []
    ) -> WorkoutSessionArchive {
        let points = rawPoints ?? [
            track(offset: 0, latitude: 37.5, longitude: 127.0, accuracy: 8, paused: false),
            track(offset: 30, latitude: 37.5005, longitude: 127.0005, accuracy: 8, paused: false),
        ]
        return WorkoutSessionArchive(
            id: id,
            runID: runID,
            startedAt: baseDate,
            endedAt: baseDate.addingTimeInterval(600),
            elapsedTimeSeconds: 600,
            timerTimeSeconds: 590,
            movingTimeSeconds: 580,
            distanceMeters: 1_610,
            averageHeartRate: 151,
            averageCadence: 174,
            averagePaceSeconds: 360,
            elevationGainM: 24,
            source: "watch-healthkit",
            trackPoints: points,
            rawTrackPoints: points,
            displayTrackPoints: displayRoute,
            laps: [WorkoutLap(
                index: 1,
                startTime: baseDate,
                endTime: baseDate.addingTimeInterval(600),
                distanceMeters: 1_610,
                timerTimeSeconds: 590,
                averageHeartRate: 151,
                averageCadence: 174,
                averagePaceSeconds: 360,
                elevationGainM: 24
            )],
            events: [
                WorkoutSessionEvent(kind: .start, timestamp: baseDate),
                WorkoutSessionEvent(kind: .end, timestamp: baseDate.addingTimeInterval(600)),
            ]
        )
    }

    private func track(
        offset: TimeInterval,
        latitude: Double,
        longitude: Double,
        accuracy: Double,
        paused: Bool
    ) -> WorkoutTrackPoint {
        WorkoutTrackPoint(
            timestamp: baseDate.addingTimeInterval(offset),
            latitude: latitude,
            longitude: longitude,
            altitude: 10 + offset / 10,
            horizontalAccuracy: accuracy,
            speedMetersPerSecond: paused ? 0 : 3.2,
            heartRate: 150 + offset / 30,
            cadence: 174,
            gpsPoor: accuracy > 30,
            paused: paused
        )
    }
}
