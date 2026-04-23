import Foundation
import Testing
@testable import RunimalDomainV2
@testable import RunimalExportV2
@testable import RunimalRewardV2
@testable import RunimalSyncV2

struct RunimalSyncRewardExportV2Tests {
    @Test
    func syncEnvelopeStartsFromCompletedArchiveAndTracksRetries() throws {
        let archive = sampleArchive()
        let envelope = RunimalSyncV2.SyncEnvelope(archive: archive, sourceDeviceID: "watch-001")

        #expect(envelope.archiveID == archive.id)
        #expect(envelope.runID == archive.runID)
        #expect(envelope.state == .readyToTransfer)
        #expect(envelope.retryCount == 0)

        let failed = envelope.transitioning(to: .retryableFailure, error: "phone unavailable")
        #expect(failed.retryCount == 1)
        #expect(failed.lastError == "phone unavailable")
    }

    @Test
    func manualSpendPolicyKeepsRunResourceUnassignedUntilUserIntent() throws {
        let archive = sampleArchive()
        let resource = RunimalDomainV2.RunResource(archiveID: archive.id, liveCompanionID: "live-only", isSpent: false)
        let intent = RunimalRewardV2.SpendIntent(
            runResourceID: resource.id,
            archiveID: archive.id,
            target: .companion,
            targetID: "companion-windrunner"
        )

        #expect(RunimalRewardV2.ManualSpendPolicy.validate(resource: resource, intent: intent) == .allowed)

        let spentResource = RunimalDomainV2.RunResource(archiveID: archive.id, isSpent: true)
        #expect(RunimalRewardV2.ManualSpendPolicy.validate(resource: spentResource, intent: intent) == .alreadySpent)
    }

    @Test
    func exportRequestReferencesCanonicalArchiveWithoutOwningConversion() throws {
        let archive = sampleArchive()
        let request = RunimalExportV2.ExportRequest(archive: archive, requestedFormat: .fit)
        let receipt = RunimalExportV2.ImportReceipt(
            sourceFormat: .fit,
            sourceName: "manual-fit-import.fit",
            canonicalArchiveID: archive.id
        )

        #expect(request.archiveID == archive.id)
        #expect(request.requestedFormat == .fit)
        #expect(receipt.canonicalArchiveID == archive.id)
    }

    private func sampleArchive() -> RunimalDomainV2.CompletedRunArchive {
        let start = Date(timeIntervalSince1970: 2_000)
        let sample = RunimalDomainV2.RunSamplePoint(
            timestamp: start,
            latitude: 37.0,
            longitude: 127.0,
            horizontalAccuracyMeters: 8
        )
        return RunimalDomainV2.CompletedRunArchive(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            runID: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            startedAt: start,
            endedAt: start.addingTimeInterval(600),
            source: "watch-healthkit-v2",
            metrics: RunimalDomainV2.RunMetricSummary(distanceMeters: 1_500, elapsedSeconds: 600, movingSeconds: 590),
            routePath: RunimalDomainV2.RoutePath(rawPoints: [sample]),
            createdOnDevice: "watch-001"
        )
    }
}

struct RunimalResourceLedgerV2Tests {
    @Test
    func resourceLedgerDeduplicatesResourcesByArchiveID() throws {
        let archiveID = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
        let original = RunimalDomainV2.RunResource(
            id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
            archiveID: archiveID,
            liveCompanionID: "live-companion",
            isSpent: false
        )
        let duplicate = RunimalDomainV2.RunResource(
            id: UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!,
            archiveID: archiveID,
            liveCompanionID: nil,
            isSpent: false
        )

        var ledger = RunimalRewardV2.RunResourceLedger()
        let inserted = ledger.upsert(original)
        let reused = ledger.upsert(duplicate)

        #expect(inserted.disposition == .inserted)
        #expect(reused.disposition == .reusedExistingUnspent)
        #expect(ledger.resources.count == 1)
        #expect(ledger.resource(forArchiveID: archiveID)?.id == original.id)
        #expect(ledger.resource(forArchiveID: archiveID)?.liveCompanionID == "live-companion")
    }

    @Test
    func resourceLedgerSpendMarksResourceSpentAndRecordsIntent() throws {
        let archiveID = UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!
        let resourceID = UUID(uuidString: "EEEEEEEE-EEEE-EEEE-EEEE-EEEEEEEEEEEE")!
        let resource = RunimalDomainV2.RunResource(id: resourceID, archiveID: archiveID, isSpent: false)
        let intent = RunimalRewardV2.SpendIntent(
            id: UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")!,
            runResourceID: resourceID,
            archiveID: archiveID,
            target: .companion,
            targetID: "companion-windrunner",
            createdAt: Date(timeIntervalSince1970: 30_000)
        )

        var ledger = RunimalRewardV2.RunResourceLedger(resources: [resource])
        let validation = ledger.spend(intent)

        #expect(validation == .allowed)
        #expect(ledger.resource(forResourceID: resourceID)?.isSpent == true)
        #expect(ledger.spendIntents == [intent])
        #expect(ledger.spend(intent) == .alreadySpent)
    }

    @Test
    func resourceLedgerDoesNotResurrectSpentResourceOnDuplicateSync() throws {
        let archiveID = UUID(uuidString: "ABABABAB-ABAB-ABAB-ABAB-ABABABABABAB")!
        let spent = RunimalDomainV2.RunResource(
            id: UUID(uuidString: "CDCDCDCD-CDCD-CDCD-CDCD-CDCDCDCDCDCD")!,
            archiveID: archiveID,
            liveCompanionID: "spent-context",
            isSpent: true
        )
        let duplicateUnspent = RunimalDomainV2.RunResource(
            id: UUID(uuidString: "EFEFEFEF-EFEF-EFEF-EFEF-EFEFEFEFEFEF")!,
            archiveID: archiveID,
            liveCompanionID: "resync-context",
            isSpent: false
        )

        var ledger = RunimalRewardV2.RunResourceLedger(resources: [spent])
        let result = ledger.upsert(duplicateUnspent)

        #expect(result.disposition == .preservedExistingSpent)
        #expect(ledger.resources.count == 1)
        #expect(ledger.resource(forArchiveID: archiveID)?.id == spent.id)
        #expect(ledger.resource(forArchiveID: archiveID)?.isSpent == true)
    }
}

struct RunimalResourceLedgerPersistenceV2Tests {
    @Test
    func resourceLedgerSnapshotRoundTripsThroughDeterministicJson() throws {
        let archiveID = UUID(uuidString: "10101010-1010-1010-1010-101010101010")!
        let resource = RunimalDomainV2.RunResource(
            id: UUID(uuidString: "20202020-2020-2020-2020-202020202020")!,
            archiveID: archiveID,
            liveCompanionID: "companion-windrunner",
            isSpent: false
        )
        let ledger = RunimalRewardV2.RunResourceLedger(resources: [resource])
        let snapshot = RunimalRewardV2.RunResourceLedgerSnapshot(
            savedAt: Date(timeIntervalSince1970: 50_000),
            ledger: ledger
        )

        let data = try RunimalRewardV2.RunResourceLedgerCodec.encode(snapshot)
        let decoded = try RunimalRewardV2.RunResourceLedgerCodec.decode(data)
        let json = String(decoding: data, as: UTF8.self)

        #expect(decoded == snapshot)
        #expect(decoded.schemaVersion == 1)
        #expect(RunimalRewardV2.RunResourceLedgerCodec.defaultFileName == "run-resource-ledger-v2.json")
        #expect(json.contains("\"schemaVersion\""))
        #expect(json.contains("\"resources\""))
        #expect(json.contains("companion-windrunner"))
    }
}
