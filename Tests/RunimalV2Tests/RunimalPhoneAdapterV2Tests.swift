import Foundation
import Testing
@testable import RunimalCore
@testable import RunimalDomainV2
@testable import RunimalPhoneAdapterV2
@testable import RunimalRewardV2

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

struct RunimalPhoneIngestApplicationV2Tests {
    @Test
    func appliesNewPhoneIngestPlanToArchiveListAndResourceLedger() throws {
        let archive = makeCompletedArchive()
        let plan = RunimalPhoneAdapterV2.ingestPlan(for: archive)

        let applied = RunimalPhoneAdapterV2.IngestApplication.apply(plan)

        #expect(applied.archiveDisposition == .inserted)
        #expect(applied.resourceDisposition == .inserted)
        #expect(applied.state.workoutArchives.map(\.runID) == [archive.runID.uuidString])
        #expect(applied.state.resourceLedger.resources.count == 1)
        #expect(applied.state.resourceLedger.resource(forArchiveID: archive.id)?.isSpent == false)
        #expect(applied.auditEvents.contains { $0.code == "phone-ingest-v2.apply-archive" })
        #expect(applied.auditEvents.contains { $0.code == "phone-ingest-v2.apply-resource" })
    }

    @Test
    func appliesDuplicatePhoneIngestPlanAsArchiveReplacementWithoutResourceDuplication() throws {
        let firstArchive = makeCompletedArchive(distanceMeters: 1_610)
        let firstPlan = RunimalPhoneAdapterV2.ingestPlan(for: firstArchive)
        let firstApplied = RunimalPhoneAdapterV2.IngestApplication.apply(firstPlan)

        let correctedArchive = makeCompletedArchive(distanceMeters: 1_700)
        let duplicatePlan = RunimalPhoneAdapterV2.ingestPlan(
            for: correctedArchive,
            options: .init(existingArchiveRunIDs: [correctedArchive.runID.uuidString])
        )
        let secondApplied = RunimalPhoneAdapterV2.IngestApplication.apply(
            duplicatePlan,
            to: firstApplied.state
        )

        #expect(secondApplied.archiveDisposition == .replaced)
        #expect(secondApplied.resourceDisposition == .reusedExistingUnspent)
        #expect(secondApplied.state.workoutArchives.count == 1)
        #expect(secondApplied.state.workoutArchives.first?.distanceMeters == 1_700)
        #expect(secondApplied.state.resourceLedger.resources.count == 1)
    }

    @Test
    func duplicatePhoneIngestDoesNotResurrectSpentRunResource() throws {
        let archive = makeCompletedArchive()
        let plan = RunimalPhoneAdapterV2.ingestPlan(for: archive)
        let ledger = RunimalRewardV2.RunResourceLedger(resources: [
            RunimalDomainV2.RunResource(
                id: UUID(uuidString: "12121212-1212-1212-1212-121212121212")!,
                archiveID: archive.id,
                liveCompanionID: "already-spent",
                isSpent: true
            ),
        ])
        let state = RunimalPhoneAdapterV2.IngestState(resourceLedger: ledger)

        let applied = RunimalPhoneAdapterV2.IngestApplication.apply(plan, to: state)

        #expect(applied.archiveDisposition == .inserted)
        #expect(applied.resourceDisposition == .preservedExistingSpent)
        #expect(applied.state.resourceLedger.resources.count == 1)
        #expect(applied.state.resourceLedger.resource(forArchiveID: archive.id)?.isSpent == true)
    }

    private var baseDate: Date { Date(timeIntervalSince1970: 40_000) }

    private func makeCompletedArchive(distanceMeters: Double = 1_610) -> RunimalDomainV2.CompletedRunArchive {
        let points = [
            sample(offset: 0, latitude: 37.5, longitude: 127.0),
            sample(offset: 60, latitude: 37.501, longitude: 127.001),
        ]
        return RunimalDomainV2.CompletedRunArchive(
            id: UUID(uuidString: "34343434-3434-3434-3434-343434343434")!,
            runID: UUID(uuidString: "56565656-5656-5656-5656-565656565656")!,
            startedAt: baseDate,
            endedAt: baseDate.addingTimeInterval(600),
            source: "watch-healthkit-v2",
            metrics: RunimalDomainV2.RunMetricSummary(
                distanceMeters: distanceMeters,
                elapsedSeconds: 600,
                movingSeconds: 580,
                averagePaceSecondsPerKM: 360,
                averageHeartRateBPM: 151,
                averageCadenceSPM: 174,
                elevationGainMeters: 24
            ),
            routePath: RunimalDomainV2.RoutePath(rawPoints: points),
            createdOnDevice: "watch-001",
            liveCompanionID: "companion-windrunner"
        )
    }

    private func sample(
        offset: TimeInterval,
        latitude: Double,
        longitude: Double
    ) -> RunimalDomainV2.RunSamplePoint {
        RunimalDomainV2.RunSamplePoint(
            timestamp: baseDate.addingTimeInterval(offset),
            latitude: latitude,
            longitude: longitude,
            altitudeMeters: 10 + offset / 10,
            horizontalAccuracyMeters: 8,
            speedMetersPerSecond: 3.2,
            heartRateBPM: 151,
            cadenceSPM: 174
        )
    }
}

struct RunimalPhoneIngestPersistenceDraftV2Tests {
    @Test
    func appliedIngestProducesPhonePersistenceDraftWithoutAppTargetImports() throws {
        let archive = makeCompletedArchive()
        let plan = RunimalPhoneAdapterV2.ingestPlan(for: archive)
        let applied = RunimalPhoneAdapterV2.IngestApplication.apply(plan)
        let savedAt = Date(timeIntervalSince1970: 60_000)

        let draft = applied.persistenceDraft(savedAt: savedAt)
        let encodedLedger = try RunimalRewardV2.RunResourceLedgerCodec.encode(draft.resourceLedgerSnapshot)
        let decodedLedger = try RunimalRewardV2.RunResourceLedgerCodec.decode(encodedLedger)

        #expect(draft.workoutArchivesFileName == "workout-archives.json")
        #expect(draft.resourceLedgerFileName == "run-resource-ledger-v2.json")
        #expect(draft.workoutArchives.map(\.runID) == [archive.runID.uuidString])
        #expect(draft.resourceLedgerSnapshot.savedAt == savedAt)
        #expect(decodedLedger == draft.resourceLedgerSnapshot)
        #expect(decodedLedger.ledger.resources.first?.archiveID == archive.id)
        #expect(decodedLedger.ledger.resources.first?.isSpent == false)
    }

    private var baseDate: Date { Date(timeIntervalSince1970: 70_000) }

    private func makeCompletedArchive() -> RunimalDomainV2.CompletedRunArchive {
        let points = [
            RunimalDomainV2.RunSamplePoint(
                timestamp: baseDate,
                latitude: 37.5,
                longitude: 127.0,
                altitudeMeters: 10,
                horizontalAccuracyMeters: 8
            ),
            RunimalDomainV2.RunSamplePoint(
                timestamp: baseDate.addingTimeInterval(60),
                latitude: 37.501,
                longitude: 127.001,
                altitudeMeters: 14,
                horizontalAccuracyMeters: 8
            ),
        ]
        return RunimalDomainV2.CompletedRunArchive(
            id: UUID(uuidString: "78787878-7878-7878-7878-787878787878")!,
            runID: UUID(uuidString: "89898989-8989-8989-8989-898989898989")!,
            startedAt: baseDate,
            endedAt: baseDate.addingTimeInterval(600),
            source: "watch-healthkit-v2",
            metrics: RunimalDomainV2.RunMetricSummary(
                distanceMeters: 1_500,
                elapsedSeconds: 600,
                movingSeconds: 590
            ),
            routePath: RunimalDomainV2.RoutePath(rawPoints: points),
            createdOnDevice: "watch-001"
        )
    }
}

struct RunimalPhoneCoreArchiveIngestPlanV2Tests {
    @Test
    func coreArchiveIngestPlanPreservesExistingPhoneArchiveIdentity() throws {
        let archive = makeCoreArchive(id: "legacy-core-archive", runID: "legacy-run-id")

        let plan = RunimalPhoneAdapterV2.ingestPlan(
            forExistingCoreArchive: archive,
            options: .init(existingArchiveRunIDs: ["legacy-run-id"], receiverDeviceID: "iphone-001"),
            liveCompanionID: "companion-windrunner"
        )
        let secondPlan = RunimalPhoneAdapterV2.ingestPlan(forExistingCoreArchive: archive)
        let publicArchiveID = RunimalPhoneAdapterV2.resourceArchiveID(
            forExistingCoreArchiveID: "legacy-core-archive"
        )

        #expect(plan.archiveForPersistence == archive)
        #expect(plan.archiveForPersistence.id == "legacy-core-archive")
        #expect(plan.archiveForPersistence.runID == "legacy-run-id")
        #expect(plan.disposition == .replaceExistingArchive)
        #expect(plan.runResource.archiveID == secondPlan.runResource.archiveID)
        #expect(plan.runResource.archiveID == publicArchiveID)
        #expect(plan.runResource.liveCompanionID == "companion-windrunner")
        #expect(plan.runResource.isSpent == false)
        #expect(plan.auditEvents.contains { $0.code == "phone-ingest-v2.stable-core-archive-id" })
    }

    private var baseDate: Date { Date(timeIntervalSince1970: 80_000) }

    private func makeCoreArchive(id: String, runID: String) -> WorkoutSessionArchive {
        let points = [
            WorkoutTrackPoint(
                timestamp: baseDate,
                latitude: 37.5,
                longitude: 127.0,
                altitude: 10,
                horizontalAccuracy: 8,
                speedMetersPerSecond: 3.2,
                heartRate: 150,
                cadence: 174,
                gpsPoor: false,
                paused: false
            ),
            WorkoutTrackPoint(
                timestamp: baseDate.addingTimeInterval(60),
                latitude: 37.501,
                longitude: 127.001,
                altitude: 14,
                horizontalAccuracy: 8,
                speedMetersPerSecond: 3.2,
                heartRate: 152,
                cadence: 176,
                gpsPoor: false,
                paused: false
            ),
        ]
        return WorkoutSessionArchive(
            id: id,
            runID: runID,
            startedAt: baseDate,
            endedAt: baseDate.addingTimeInterval(600),
            elapsedTimeSeconds: 600,
            timerTimeSeconds: 600,
            movingTimeSeconds: 590,
            distanceMeters: 1_500,
            averageHeartRate: 151,
            averageCadence: 175,
            averagePaceSeconds: 400,
            elevationGainM: 20,
            source: "watch-healthkit",
            trackPoints: points,
            rawTrackPoints: points,
            displayTrackPoints: [],
            laps: [],
            events: []
        )
    }
}
