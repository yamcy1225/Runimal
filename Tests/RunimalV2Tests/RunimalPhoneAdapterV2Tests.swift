import Foundation
import Testing
@testable import RunimalCore
@testable import RunimalDomainV2
@testable import RunimalPhoneAdapterV2

struct RunimalPhoneAdapterV2Tests {
    @Test
    func createsPhoneIngestPlanWithPersistableArchiveAndUnspentRunResource() throws {
        let archive = makeCompletedArchive()

        let plan = RunimalPhoneAdapterV2.ingestPlan(
            for: archive,
            options: .init(receiverDeviceID: "iphone-001")
        )

        #expect(plan.disposition == .insertNewArchive)
        #expect(plan.archiveForPersistence.id == archive.id.uuidString)
        #expect(plan.archiveForPersistence.runID == archive.runID.uuidString)
        #expect(plan.archiveForPersistence.startedAt == archive.startedAt)
        #expect(plan.archiveForPersistence.endedAt == archive.endedAt)
        #expect(plan.archiveForPersistence.distanceMeters == 1_610)
        #expect(plan.archiveForPersistence.elapsedTimeSeconds == 600)
        #expect(plan.archiveForPersistence.movingTimeSeconds == 580)
        #expect(plan.archiveForPersistence.averageHeartRate == 151)
        #expect(plan.archiveForPersistence.averageCadence == 174)
        #expect(plan.archiveForPersistence.averagePaceSeconds == 360)
        #expect(plan.archiveForPersistence.elevationGainM == 24)
        #expect(plan.archiveForPersistence.source == "watch-healthkit-v2")
        #expect(plan.archiveForPersistence.rawTrackPoints.count == 3)
        #expect(plan.archiveForPersistence.displayTrackPoints.count == 2)
        #expect(plan.archiveForPersistence.laps.count == 1)
        #expect(plan.archiveForPersistence.events.map(\.kind) == [.start, .end])

        #expect(plan.runResource.archiveID == archive.id)
        #expect(plan.runResource.liveCompanionID == "companion-windrunner")
        #expect(plan.runResource.isSpent == false)
        #expect(plan.createsCompletedRunRecordImmediately == false)
        #expect(plan.spendsRunResourceImmediately == false)
        #expect(plan.auditEvents.contains { $0.code == "phone-ingest-v2.resource-unspent" })
        #expect(plan.auditEvents.contains { $0.code == "phone-ingest-v2.receiver" })
    }

    @Test
    func marksMatchingRunIDAsReplacementCandidateInsteadOfDuplicateInsert() throws {
        let archive = makeCompletedArchive()

        let plan = RunimalPhoneAdapterV2.ingestPlan(
            for: archive,
            options: .init(existingArchiveRunIDs: [archive.runID.uuidString])
        )

        #expect(plan.disposition == .replaceExistingArchive)
        #expect(plan.auditEvents.contains { $0.code == "phone-ingest-v2.replace" })
    }

    @Test
    func dropsInvalidGpsFromPersistenceCandidateWithoutLosingMetricSummary() throws {
        let archive = makeCompletedArchive(rawPoints: [
            sample(offset: 0, latitude: 37.5, longitude: 127.0, accuracy: 8),
            sample(offset: 10, latitude: nil, longitude: 127.0, accuracy: 8),
            sample(offset: 20, latitude: 37.501, longitude: 127.001, accuracy: 120),
        ])

        let plan = RunimalPhoneAdapterV2.ingestPlan(for: archive)

        #expect(plan.archiveForPersistence.rawTrackPoints.count == 2)
        #expect(plan.archiveForPersistence.rawTrackPoints.last?.gpsPoor == true)
        #expect(plan.archiveForPersistence.distanceMeters == 1_610)
        #expect(plan.auditEvents.contains { $0.code == "phone-ingest-v2.dropped-invalid-gps" })
    }

    @Test
    func phoneArchiveCandidateRoundTripsThroughCoreJsonShape() throws {
        let archive = makeCompletedArchive()
        let plan = RunimalPhoneAdapterV2.ingestPlan(for: archive)

        let data = try JSONEncoder().encode(plan.archiveForPersistence)
        let decoded = try JSONDecoder().decode(WorkoutSessionArchive.self, from: data)

        #expect(decoded == plan.archiveForPersistence)
        #expect(decoded.effectiveRawTrackPoints.count == 3)
        #expect(decoded.effectiveDisplayTrackPoints.count == 2)
    }

    private var baseDate: Date { Date(timeIntervalSince1970: 20_000) }

    private func makeCompletedArchive(
        rawPoints: [RunimalDomainV2.RunSamplePoint]? = nil
    ) -> RunimalDomainV2.CompletedRunArchive {
        let points = rawPoints ?? [
            sample(offset: 0, latitude: 37.5, longitude: 127.0, accuracy: 8, heartRate: 150, cadence: 174),
            sample(offset: 30, latitude: 37.5005, longitude: 127.0005, accuracy: 8, heartRate: 152, cadence: 176, isPaused: true),
            sample(offset: 60, latitude: 37.501, longitude: 127.001, accuracy: 8, heartRate: 151, cadence: 173),
        ]

        return RunimalDomainV2.CompletedRunArchive(
            id: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
            runID: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
            startedAt: baseDate,
            endedAt: baseDate.addingTimeInterval(600),
            source: "watch-healthkit-v2",
            metrics: RunimalDomainV2.RunMetricSummary(
                distanceMeters: 1_610,
                elapsedSeconds: 600,
                movingSeconds: 580,
                averagePaceSecondsPerKM: 360,
                averageHeartRateBPM: 151,
                averageCadenceSPM: 174,
                elevationGainMeters: 24
            ),
            routePath: RunimalDomainV2.RoutePath(
                rawPoints: points,
                displayPoints: [points[0], points[points.count - 1]],
                sourceSampleCount: points.count
            ),
            createdOnDevice: "watch-001",
            liveCompanionID: "companion-windrunner"
        )
    }

    private func sample(
        offset: TimeInterval,
        latitude: Double?,
        longitude: Double?,
        accuracy: Double,
        heartRate: Double? = nil,
        cadence: Int? = nil,
        isPaused: Bool = false
    ) -> RunimalDomainV2.RunSamplePoint {
        RunimalDomainV2.RunSamplePoint(
            timestamp: baseDate.addingTimeInterval(offset),
            latitude: latitude,
            longitude: longitude,
            altitudeMeters: 10 + offset / 10,
            horizontalAccuracyMeters: accuracy,
            speedMetersPerSecond: isPaused ? 0 : 3.2,
            heartRateBPM: heartRate,
            cadenceSPM: cadence,
            isPaused: isPaused
        )
    }
}
