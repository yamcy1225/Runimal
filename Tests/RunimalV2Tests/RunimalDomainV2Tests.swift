import Foundation
import Testing
@testable import RunimalDomainV2

struct RunimalDomainV2Tests {
    @Test
    func sessionDraftCreatesDurableArchiveBeforeSync() throws {
        let runID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let start = Date(timeIntervalSince1970: 1_000)
        var draft = RunimalDomainV2.RunSessionDraft(
            identity: RunimalDomainV2.RunIdentity(
                id: runID,
                sourceDeviceID: "watch-001",
                source: "watch-healthkit-v2"
            ),
            startedAt: start,
            liveCompanionID: "companion-windrunner"
        )

        draft.start()
        draft.record(sample(offset: 0, latitude: 37.5000, longitude: 127.0000, altitude: 10, heartRate: 140, cadence: 170))
        draft.record(sample(offset: 30, latitude: 37.5005, longitude: 127.0005, altitude: 12, heartRate: 150, cadence: 174))
        draft.finish(at: start.addingTimeInterval(30))

        let archive = try #require(draft.completedArchive(createdOnDevice: "watch-001"))

        #expect(archive.runID == runID)
        #expect(archive.schemaVersion == 1)
        #expect(archive.createdOnDevice == "watch-001")
        #expect(archive.liveCompanionID == "companion-windrunner")
        #expect(archive.metrics.distanceMeters > 60)
        #expect(archive.metrics.movingSeconds == 30)
        #expect(archive.routePath.rawPoints.count == 2)
        #expect(archive.routePath.displayPoints.count == 2)
        #expect(archive.routePath.bounds != nil)
    }

    @Test
    func routePathDropsPausedAndInvalidPointsForDisplayWithoutLosingRawEvidence() {
        let rawPoints = [
            sample(offset: 0, latitude: 37.0, longitude: 127.0, accuracy: 8),
            sample(offset: 5, latitude: 999.0, longitude: 127.0, accuracy: 8),
            sample(offset: 10, latitude: 37.001, longitude: 127.001, accuracy: 8, isPaused: true),
            sample(offset: 15, latitude: 37.002, longitude: 127.002, accuracy: 8),
        ]

        let routePath = RunimalDomainV2.RoutePath(rawPoints: rawPoints)

        #expect(routePath.rawPoints.count == 4)
        #expect(routePath.displayPoints.count == 2)
        #expect(routePath.sourceSampleCount == 4)
        #expect(routePath.bounds?.minimumLatitude == 37.0)
        #expect(routePath.bounds?.maximumLatitude == 37.002)
    }

    @Test
    func routeQualityFlagsDegradedGps() {
        let points = [
            sample(offset: 0, latitude: 37.0, longitude: 127.0, accuracy: 8),
            sample(offset: 5, latitude: 37.001, longitude: 127.001, accuracy: 120),
            sample(offset: 40, latitude: 37.002, longitude: 127.002, accuracy: 120),
        ]

        let summary = RunimalDomainV2.RouteQualityAnalyzer.summarize(points)

        #expect(summary.totalPointCount == 3)
        #expect(summary.usablePointCount == 1)
        #expect(summary.poorAccuracyPointCount == 2)
        #expect(summary.gapCount == 1)
        #expect(summary.quality == .degraded)
    }

    private func sample(
        offset: TimeInterval,
        latitude: Double,
        longitude: Double,
        altitude: Double = 0,
        accuracy: Double = 8,
        heartRate: Double? = nil,
        cadence: Int? = nil,
        isPaused: Bool = false
    ) -> RunimalDomainV2.RunSamplePoint {
        RunimalDomainV2.RunSamplePoint(
            timestamp: Date(timeIntervalSince1970: 1_000 + offset),
            latitude: latitude,
            longitude: longitude,
            altitudeMeters: altitude,
            horizontalAccuracyMeters: accuracy,
            heartRateBPM: heartRate,
            cadenceSPM: cadence,
            isPaused: isPaused
        )
    }
}
