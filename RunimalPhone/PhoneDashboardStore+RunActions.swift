import Foundation
import RunimalCore

@MainActor
extension PhoneDashboardStore {
    func requestHealthAuthorization() async {
        await healthKit.requestAuthorization()
    }

    func syncExternalHealthKitRuns() async {
        if healthKit.authorizationStatus == "not requested" {
            await healthKit.requestAuthorization()
        }

        let imports = await healthKit.syncExternalRuns(
            claimedRewardIDs: claimedWeeklyRewardIDs,
            existingRunsByID: Dictionary(uniqueKeysWithValues: completedRuns.map { ($0.id, $0) })
        )

        guard !imports.isEmpty else { return }

        for item in imports.reversed() {
            progress.append(completedRun: item.record)
            progress.append(reward: item.reward, snapshot: item.snapshot)
            telemetry.log("external_workout_imported", detail: "\(item.sourceName) · \(item.id)")
        }

        persistVault()
    }

    func importFITRun(from url: URL) async {
        do {
            let item = try await fitImport.importFile(
                from: url,
                claimedRewardIDs: claimedWeeklyRewardIDs
            )
            progress.append(completedRun: item.record)
            progress.append(reward: item.reward, snapshot: item.snapshot)
            telemetry.log("fit_file_imported", detail: "\(item.sourceName) · \(item.id)")
            persistVault()
        } catch {
            fitImport.markImportFailed(error.localizedDescription)
        }
    }

    func clearImportedExternalRuns() {
        progress.removeImportedExternalRuns()
        healthKit.resetImportedWorkoutIDs()
        fitImport.resetImportedStatus()
        telemetry.log("external_workout_cleared", detail: "manual clear")
        persistVault()
    }

    func ingestLatestReward() {
        guard let reward = connectivity.lastReward else { return }
        let adjustedReward: RunRewardSummary

        if let snapshot = connectivity.lastSnapshot {
            adjustedReward = RunimalGameEngine.evaluateReward(for: snapshot, claimedRewardIDs: claimedWeeklyRewardIDs)
        } else {
            adjustedReward = RunimalGameEngine.applyWeeklyRewardModifiers(to: reward, claimedRewardIDs: claimedWeeklyRewardIDs)
        }

        progress.append(reward: adjustedReward, snapshot: connectivity.lastSnapshot)
        persistVault()
        logRewardPulseTelemetry(for: adjustedReward)
        telemetry.log("reward_ingested", detail: adjustedReward.coreLabel)
    }

    func ingestCompletedRun() {
        guard let record = connectivity.lastCompletedRun else { return }
        let isFirstCompletedRun = completedRuns.contains(where: { $0.source != "seeded-archive" }) == false
        let stampedRecord: CompletedRunRecord
        if let companion = progress.watchPetSelection {
            let livePotential = RunimalRunCoreGrowthBalanceEngine.livePotential(for: record)
            stampedRecord = CompletedRunRecord(
                id: record.id,
                startedAt: record.startedAt,
                endedAt: record.endedAt,
                distanceMeters: record.distanceMeters,
                durationSeconds: record.durationSeconds,
                averageHeartRate: record.averageHeartRate,
                averagePaceSeconds: record.averagePaceSeconds,
                cadence: record.cadence,
                elevationGainM: record.elevationGainM,
                reward: record.reward,
                route: record.route,
                source: record.source,
                sourceLabel: record.sourceLabel,
                raidContribution: record.raidContribution,
                environmentCondition: record.environmentCondition,
                rareEventCompleted: record.rareEventCompleted,
                liveCompanionID: companion.id,
                liveCompanionName: companion.pet.displayName,
                livePotentialProfile: livePotential,
                mutationForm: record.mutationForm,
                mutationContribution: record.mutationContribution,
                worldImpact: record.worldImpact
            )
        } else {
            stampedRecord = record
        }
        progress.append(completedRun: stampedRecord)
        if let companion = progress.watchPetSelection {
            let livePotential = progress.storeLiveCompanionPotential(from: stampedRecord, companionID: companion.id)
            if livePotential.storedPotentialExperience > 0 {
                telemetry.log("live_companion_potential", detail: "\(companion.id):\(livePotential.storedPotentialExperience)")
            }
        }
        persistVault()
        if isFirstCompletedRun {
            telemetry.log("first_run_completed", detail: record.id)
        }
        telemetry.log("completed_run_ingested", detail: record.id)
    }

    func logRewardPulseTelemetry(for reward: RunRewardSummary) {
        guard reward.bonusLabels.isEmpty == false else { return }
        telemetry.log("reward_pulse_applied", detail: reward.bonusLabels.joined(separator: ", "))
    }
}
