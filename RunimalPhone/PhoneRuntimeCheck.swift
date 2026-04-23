import Foundation
import RunimalCore
import RunimalPhoneAdapterV2
import RunimalRewardV2
import SwiftUI

enum PhoneRuntimeCheck: String {
    case resourceLedgerV2 = "resource-ledger-v2"

    static var current: PhoneRuntimeCheck? {
        ProcessInfo.processInfo.environment["RUNIMAL_RUNTIME_CHECK"].flatMap(Self.init(rawValue:))
    }
}

struct PhoneRuntimeCheckRoot: View {
    let check: PhoneRuntimeCheck
    @State private var status = "Running..."

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Runimal Runtime Check")
                .font(.headline.monospaced().weight(.black))
            Text(check.rawValue)
                .font(.subheadline.monospaced())
            Text(status)
                .font(.footnote.monospaced())
        }
        .padding()
        .task {
            do {
                switch check {
                case .resourceLedgerV2:
                    let report = try await PhoneResourceLedgerRuntimeCheck.run()
                    status = report.passed ? "PASS: \(report.reportPath)" : "FAIL: \(report.failures.joined(separator: ", "))"
                }
            } catch {
                status = "ERROR: \(error.localizedDescription)"
            }
        }
    }
}

@MainActor
enum PhoneResourceLedgerRuntimeCheck {
    struct Report: Codable, Equatable {
        let checkID: String
        let generatedAt: Date
        let reportPath: String
        let sidecarCreated: Bool
        let sidecarUnspentCountAfterReceipt: Int
        let companionFeedSpent: Bool
        let eggForgeSpent: Bool
        let eggIncubationSpent: Bool
        let unspentResourcePrunedAfterDelete: Bool
        let spentResourcePreservedAfterDelete: Bool
        let failures: [String]

        var passed: Bool {
            failures.isEmpty
        }
    }

    private struct ScenarioResult {
        let archiveID: UUID
        let reportDirectoryName: String
        let resourceExistedBeforeAction: Bool
        let resourceIsSpentAfterAction: Bool?
        let loadedLedgerAfterAction: RunimalRewardV2.RunResourceLedger
    }

    static func run(
        fileManager: FileManager = .default,
        generatedAt: Date = Date()
    ) async throws -> Report {
        let receipt = try ingestScenario(
            id: "receipt",
            fileManager: fileManager,
            action: { _ in }
        )
        let companionFeed = try ingestScenario(
            id: "companion-feed",
            fileManager: fileManager,
            action: { progress in
                guard let run = progress.completedRuns.first,
                      let companion = progress.ownedCompanions.first else { return }
                _ = progress.feed(
                    run: run,
                    to: companion,
                    activeEffects: [],
                    season: runtimeSeason
                )
            }
        )
        let eggForge = try ingestScenario(
            id: "egg-forge",
            fileManager: fileManager,
            configure: { progress in
                progress.ownedCompanions = []
                progress.eggInventory = []
                progress.mainCompanionSelection = nil
                progress.activeCompanionID = nil
            },
            action: { progress in
                guard let run = progress.completedRuns.first else { return }
                _ = progress.forgeEgg(from: run)
            }
        )
        let eggIncubation = try ingestScenario(
            id: "egg-incubation",
            fileManager: fileManager,
            configure: { progress in
                let egg = EggInventoryEntry(
                    id: "runtime-egg",
                    shell: .gale,
                    title: "Runtime Egg",
                    createdAt: Date(timeIntervalSince1970: 12_000),
                    sourceRunID: "runtime-seed-run",
                    storedExperience: 20,
                    hatchThreshold: 400,
                    incubationRunIDs: [],
                    unlockedAchievementIDs: [],
                    starterBoosted: false
                )
                progress.eggInventory = [egg]
                progress.mainCompanionSelection = MainCompanionSelection(kind: .egg, targetID: egg.id)
            },
            action: { progress in
                guard let run = progress.completedRuns.first else { return }
                _ = progress.incubateMainEgg(with: run)
            }
        )
        let unspentPrune = try pruningScenario(
            id: "unspent-prune",
            fileManager: fileManager,
            spendBeforeDelete: false
        )
        let spentPreserve = try pruningScenario(
            id: "spent-preserve",
            fileManager: fileManager,
            spendBeforeDelete: true
        )

        let sidecarURL = directoryURL(fileManager: fileManager, directoryName: receipt.reportDirectoryName)
            .appendingPathComponent(RunimalRewardV2.RunResourceLedgerCodec.defaultFileName)
        var failures: [String] = []
        let sidecarCreated = fileManager.fileExists(atPath: sidecarURL.path)
        let receiptUnspentCount = receipt.loadedLedgerAfterAction.resources.filter { !$0.isSpent }.count
        let companionFeedSpent = companionFeed.resourceIsSpentAfterAction == true
        let eggForgeSpent = eggForge.resourceIsSpentAfterAction == true
        let eggIncubationSpent = eggIncubation.resourceIsSpentAfterAction == true
        let unspentResourcePrunedAfterDelete = unspentPrune.resourceIsSpentAfterAction == nil
        let spentResourcePreservedAfterDelete = spentPreserve.resourceIsSpentAfterAction == true

        if sidecarCreated == false { failures.append("sidecar-not-created") }
        if receiptUnspentCount != 1 { failures.append("receipt-unspent-count-\(receiptUnspentCount)") }
        if companionFeedSpent == false { failures.append("companion-feed-not-spent") }
        if eggForgeSpent == false { failures.append("egg-forge-not-spent") }
        if eggIncubationSpent == false { failures.append("egg-incubation-not-spent") }
        if unspentResourcePrunedAfterDelete == false { failures.append("unspent-resource-not-pruned") }
        if spentResourcePreservedAfterDelete == false { failures.append("spent-resource-not-preserved") }

        let reportURL = reportURL(fileManager: fileManager)
        let report = Report(
            checkID: PhoneRuntimeCheck.resourceLedgerV2.rawValue,
            generatedAt: generatedAt,
            reportPath: reportURL.path,
            sidecarCreated: sidecarCreated,
            sidecarUnspentCountAfterReceipt: receiptUnspentCount,
            companionFeedSpent: companionFeedSpent,
            eggForgeSpent: eggForgeSpent,
            eggIncubationSpent: eggIncubationSpent,
            unspentResourcePrunedAfterDelete: unspentResourcePrunedAfterDelete,
            spentResourcePreservedAfterDelete: spentResourcePreservedAfterDelete,
            failures: failures
        )

        try fileManager.createDirectory(
            at: reportURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(report).write(to: reportURL, options: [.atomic])
        return report
    }

    private static func ingestScenario(
        id: String,
        fileManager: FileManager,
        configure: (PhoneProgressStore) -> Void = { _ in },
        action: (PhoneProgressStore) -> Void
    ) throws -> ScenarioResult {
        let directoryName = "RunimalPhoneRuntimeChecks/\(id)"
        let progress = try freshProgress(fileManager: fileManager, directoryName: directoryName)
        let run = fixtureRun(id: "runtime-\(id)-run")
        let archive = fixtureArchive(for: run, archiveID: "runtime-\(id)-archive")
        applyReceipt(archive: archive, run: run, to: progress)
        progress.ownedCompanions = [fixtureCompanion(id: "runtime-\(id)-companion")]
        progress.activeCompanionID = progress.ownedCompanions.first?.id
        progress.mainCompanionSelection = progress.activeCompanionID.map { MainCompanionSelection(kind: .pet, targetID: $0) }
        configure(progress)
        progress.save()

        let archiveUUID = RunimalPhoneAdapterV2.resourceArchiveID(forExistingCoreArchiveID: archive.id)
        let before = progress.runResourceLedger.resource(forArchiveID: archiveUUID)
        action(progress)
        progress.save()

        let loadedLedger = PhoneRunResourceLedgerPersistence(
            fileManager: fileManager,
            directoryName: directoryName
        ).loadLedger()
        return ScenarioResult(
            archiveID: archiveUUID,
            reportDirectoryName: directoryName,
            resourceExistedBeforeAction: before != nil,
            resourceIsSpentAfterAction: loadedLedger.resource(forArchiveID: archiveUUID)?.isSpent,
            loadedLedgerAfterAction: loadedLedger
        )
    }

    private static func pruningScenario(
        id: String,
        fileManager: FileManager,
        spendBeforeDelete: Bool
    ) throws -> ScenarioResult {
        try ingestScenario(
            id: id,
            fileManager: fileManager,
            action: { progress in
                guard let run = progress.completedRuns.first else { return }
                if spendBeforeDelete {
                    _ = progress.spendRunResourceIfPresent(
                        runID: run.id,
                        target: .companion,
                        targetID: "runtime-prune-companion"
                    )
                }
                _ = progress.removeRun(id: run.id)
            }
        )
    }

    private static func freshProgress(
        fileManager: FileManager,
        directoryName: String
    ) throws -> PhoneProgressStore {
        let defaultsName = "RunimalRuntimeCheck.\(directoryName.replacingOccurrences(of: "/", with: "."))"
        let defaults = UserDefaults(suiteName: defaultsName) ?? .standard
        defaults.removePersistentDomain(forName: defaultsName)
        let directory = directoryURL(fileManager: fileManager, directoryName: directoryName)
        if fileManager.fileExists(atPath: directory.path) {
            try fileManager.removeItem(at: directory)
        }
        let progress = PhoneProgressStore(
            defaults: defaults,
            archivePersistence: PhoneWorkoutArchivePersistence(
                fileManager: fileManager,
                directoryName: directoryName
            ),
            resourceLedgerPersistence: PhoneRunResourceLedgerPersistence(
                fileManager: fileManager,
                directoryName: directoryName
            )
        )
        progress.load()
        return progress
    }

    private static func applyReceipt(
        archive: WorkoutSessionArchive,
        run: CompletedRunRecord,
        to progress: PhoneProgressStore
    ) {
        let plan = RunimalPhoneAdapterV2.ingestPlan(
            forExistingCoreArchive: archive,
            options: .init(
                existingArchiveRunIDs: Set(progress.workoutArchives.map(\.runID)),
                receiverDeviceID: progress.deviceID
            )
        )
        let applied = RunimalPhoneAdapterV2.IngestApplication.apply(
            plan,
            to: .init(
                workoutArchives: progress.workoutArchives,
                resourceLedger: progress.runResourceLedger
            )
        )
        progress.workoutArchives = applied.state.workoutArchives
        progress.runResourceLedger = applied.state.resourceLedger
        progress.append(completedRun: run)
    }

    private static func fixtureRun(id: String) -> CompletedRunRecord {
        let summary = RunSummary(
            distanceKm: 4.2,
            averagePaceSeconds: 330,
            cadence: 172,
            elevationGainM: 24,
            variability: 0.08,
            aura: .day,
            shape: .outAndBack,
            environmentCondition: .clear
        )
        let reward = RunimalGameEngine.evaluateReward(for: summary)
        let endedAt = Date(timeIntervalSince1970: 20_000)
        let startedAt = endedAt.addingTimeInterval(-1_386)
        return RunimalGameEngine.makeCompletedRunRecord(
            reward: reward,
            snapshot: LiveRunSnapshot(
                elapsedSeconds: 1_386,
                distanceMeters: 4_200,
                currentHeartRate: 148,
                cadence: 172,
                elevationGainM: 24,
                averagePaceSeconds: 330
            ),
            startedAt: startedAt,
            endedAt: endedAt,
            averageHeartRate: 148,
            route: fixtureRoute(startedAt: startedAt),
            source: "runtime-check",
            sourceLabel: "Runtime Check",
            environmentCondition: .clear,
            id: id
        )
    }

    private static func fixtureArchive(
        for run: CompletedRunRecord,
        archiveID: String
    ) -> WorkoutSessionArchive {
        let track = fixtureTrack(startedAt: run.startedAt)
        return WorkoutSessionArchive(
            id: archiveID,
            runID: run.id,
            startedAt: run.startedAt,
            endedAt: run.endedAt,
            elapsedTimeSeconds: run.durationSeconds,
            timerTimeSeconds: run.durationSeconds,
            movingTimeSeconds: run.durationSeconds,
            distanceMeters: run.distanceMeters,
            averageHeartRate: run.averageHeartRate,
            averageCadence: run.cadence,
            averagePaceSeconds: run.averagePaceSeconds,
            elevationGainM: run.elevationGainM,
            source: "runtime-check",
            trackPoints: track,
            rawTrackPoints: track,
            displayTrackPoints: run.route,
            laps: [
                WorkoutLap(
                    index: 0,
                    startTime: run.startedAt,
                    endTime: run.endedAt,
                    distanceMeters: run.distanceMeters,
                    timerTimeSeconds: run.durationSeconds,
                    averageHeartRate: run.averageHeartRate,
                    averageCadence: run.cadence,
                    averagePaceSeconds: run.averagePaceSeconds,
                    elevationGainM: run.elevationGainM
                ),
            ],
            events: [
                WorkoutSessionEvent(kind: .start, timestamp: run.startedAt),
                WorkoutSessionEvent(kind: .end, timestamp: run.endedAt),
            ]
        )
    }

    private static func fixtureCompanion(id: String) -> PetCollectionEntry {
        let pet = RunimalGameEngine.generatePet(
            from: RunSummary(
                distanceKm: 4.2,
                averagePaceSeconds: 330,
                cadence: 172,
                elevationGainM: 24,
                variability: 0.08,
                aura: .day,
                shape: .outAndBack,
                environmentCondition: .clear
            )
        )
        return PetCollectionEntry(
            id: id,
            pet: pet,
            level: 1,
            bond: 10,
            totalDistanceKm: 0,
            headline: "Runtime check companion"
        )
    }

    private static var runtimeSeason: WeeklySeason {
        WeeklySeason(
            title: "Runtime Check",
            subtitle: "Resource ledger verification",
            bonus: "No seasonal bonus",
            rewardTitle: "Ledger Proof",
            evolutionTitle: "Spend Boundary",
            focusSpecies: .windrunner,
            focusVariant: nil
        )
    }

    private static func fixtureTrack(startedAt: Date) -> [WorkoutTrackPoint] {
        fixtureRoute(startedAt: startedAt).enumerated().map { index, point in
            WorkoutTrackPoint(
                timestamp: point.timestamp,
                latitude: point.latitude,
                longitude: point.longitude,
                altitude: point.altitude,
                horizontalAccuracy: 5,
                speedMetersPerSecond: 3.03,
                heartRate: Double(145 + index),
                cadence: 172,
                gpsPoor: false,
                paused: false
            )
        }
    }

    private static func fixtureRoute(startedAt: Date) -> [RoutePoint] {
        [
            RoutePoint(latitude: 37.56650, longitude: 126.97800, altitude: 38, timestamp: startedAt),
            RoutePoint(latitude: 37.56695, longitude: 126.97900, altitude: 40, timestamp: startedAt.addingTimeInterval(60)),
            RoutePoint(latitude: 37.56745, longitude: 126.98010, altitude: 43, timestamp: startedAt.addingTimeInterval(120)),
            RoutePoint(latitude: 37.56810, longitude: 126.98120, altitude: 47, timestamp: startedAt.addingTimeInterval(180)),
        ]
    }

    private static func directoryURL(fileManager: FileManager, directoryName: String) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return baseURL.appendingPathComponent(directoryName, isDirectory: true)
    }

    private static func reportURL(fileManager: FileManager) -> URL {
        directoryURL(fileManager: fileManager, directoryName: "RunimalPhoneRuntimeChecks")
            .appendingPathComponent("resource-ledger-v2-report.json")
    }
}
