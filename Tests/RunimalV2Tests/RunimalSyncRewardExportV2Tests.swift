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
