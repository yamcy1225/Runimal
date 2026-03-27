import Foundation
import Observation
import RunimalCore

@MainActor
@Observable
final class PhoneProgressStore {
    private enum Keys {
        static let journal = "runimal.phone.journal"
        static let completedRuns = "runimal.phone.completedRuns"
        static let claimedWeeklyRewards = "runimal.phone.claimedWeeklyRewards"
        static let activeCompanionID = "runimal.phone.activeCompanionID"
        static let growthRecords = "runimal.phone.growthRecords"
        static let retiredCompanionIDs = "runimal.phone.retiredCompanionIDs"
        static let essenceBalance = "runimal.phone.essenceBalance"
        static let overdriveCharges = "runimal.phone.overdriveCharges"
        static let seasonSigils = "runimal.phone.seasonSigils"
        static let buildStates = "runimal.phone.buildStates"
        static let claimedSeasonRewardIDs = "runimal.phone.claimedSeasonRewardIDs"
        static let claimedRaidRewardIDs = "runimal.phone.claimedRaidRewardIDs"
        static let raidShardBalance = "runimal.phone.raidShardBalance"
        static let deviceID = "runimal.phone.deviceID"
        static let lastRaidResolution = "runimal.phone.lastRaidResolution"
        static let conflictPolicy = "runimal.phone.conflictPolicy"
        static let verificationRecords = "runimal.phone.verificationRecords"
        static let duplicatePriority = "runimal.phone.duplicatePriority"
    }

    private let defaults: UserDefaults
    var journal: [RunJournalEntry] = []
    var completedRuns: [CompletedRunRecord] = []
    var claimedWeeklyRewards: [String] = []
    var activeCompanionID: String?
    var growthRecords: [CompanionGrowthRecord] = []
    var retiredCompanionIDs: [String] = []
    var essenceBalance = 0
    var overdriveCharges = 0
    var seasonSigils = 0
    var buildStates: [CompanionBuildState] = []
    var claimedSeasonRewardIDs: [String] = []
    var claimedRaidRewardIDs: [String] = []
    var raidShardBalance = 0
    var deviceID = UUID().uuidString
    var lastRaidResolution: RaidResolution?
    var conflictPolicy: SnapshotConflictPolicy = .merged
    var verificationRecords: [DeviceVerificationRecord] = []
    var duplicatePriority: SnapshotDuplicatePriority = .newestWins

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() {
        if let data = defaults.data(forKey: Keys.journal) {
            do {
                journal = try JSONDecoder().decode([RunJournalEntry].self, from: data)
            } catch {
                journal = []
            }
        } else {
            journal = []
        }

        if let data = defaults.data(forKey: Keys.completedRuns) {
            do {
                completedRuns = try JSONDecoder().decode([CompletedRunRecord].self, from: data)
            } catch {
                completedRuns = []
            }
        } else {
            completedRuns = []
        }

        claimedWeeklyRewards = defaults.stringArray(forKey: Keys.claimedWeeklyRewards) ?? []
        activeCompanionID = defaults.string(forKey: Keys.activeCompanionID)

        if let data = defaults.data(forKey: Keys.growthRecords) {
            do {
                growthRecords = try JSONDecoder().decode([CompanionGrowthRecord].self, from: data)
            } catch {
                growthRecords = []
            }
        } else {
            growthRecords = []
        }

        retiredCompanionIDs = defaults.stringArray(forKey: Keys.retiredCompanionIDs) ?? []
        essenceBalance = defaults.integer(forKey: Keys.essenceBalance)
        overdriveCharges = defaults.integer(forKey: Keys.overdriveCharges)
        seasonSigils = defaults.integer(forKey: Keys.seasonSigils)

        if let data = defaults.data(forKey: Keys.buildStates) {
            do {
                buildStates = try JSONDecoder().decode([CompanionBuildState].self, from: data)
            } catch {
                buildStates = []
            }
        } else {
            buildStates = []
        }

        claimedSeasonRewardIDs = defaults.stringArray(forKey: Keys.claimedSeasonRewardIDs) ?? []
        claimedRaidRewardIDs = defaults.stringArray(forKey: Keys.claimedRaidRewardIDs) ?? []
        raidShardBalance = defaults.integer(forKey: Keys.raidShardBalance)
        deviceID = defaults.string(forKey: Keys.deviceID) ?? UUID().uuidString
        if let data = defaults.data(forKey: Keys.lastRaidResolution) {
            lastRaidResolution = try? JSONDecoder().decode(RaidResolution.self, from: data)
        } else {
            lastRaidResolution = nil
        }
        if let raw = defaults.string(forKey: Keys.conflictPolicy),
           let decoded = SnapshotConflictPolicy(rawValue: raw) {
            conflictPolicy = decoded
        } else {
            conflictPolicy = .merged
        }
        if let data = defaults.data(forKey: Keys.verificationRecords) {
            verificationRecords = (try? JSONDecoder().decode([DeviceVerificationRecord].self, from: data)) ?? []
        } else {
            verificationRecords = []
        }
        if let raw = defaults.string(forKey: Keys.duplicatePriority),
           let decoded = SnapshotDuplicatePriority(rawValue: raw) {
            duplicatePriority = decoded
        } else {
            duplicatePriority = .newestWins
        }
    }

    func seedIfNeeded(from summaries: [RunSummary]) {
        if journal.isEmpty {
            let seededEntries = summaries.enumerated().map { index, summary in
                let reward = RunimalGameEngine.evaluateReward(for: summary)
                let createdAt = Calendar.current.date(byAdding: .day, value: -(index + 1), to: Date()) ?? Date()

                return RunimalGameEngine.makeJournalEntry(
                    reward: reward,
                    distanceKm: summary.distanceKm,
                    cadence: summary.cadence,
                    createdAt: createdAt
                )
            }

            journal = seededEntries
        }

        if completedRuns.isEmpty, let summary = summaries.first {
            let reward = RunimalGameEngine.evaluateReward(for: summary)
            let endedAt = Date().addingTimeInterval(-3600)
            let startedAt = endedAt.addingTimeInterval(-summary.distanceKm * Double(summary.averagePaceSeconds))
            let snapshot = LiveRunSnapshot(
                elapsedSeconds: Int(summary.distanceKm * Double(summary.averagePaceSeconds)),
                distanceMeters: summary.distanceKm * 1000,
                currentHeartRate: 152,
                cadence: summary.cadence,
                elevationGainM: summary.elevationGainM,
                averagePaceSeconds: summary.averagePaceSeconds
            )

            completedRuns = [
                RunimalGameEngine.makeCompletedRunRecord(
                    reward: reward,
                    snapshot: snapshot,
                    startedAt: startedAt,
                    endedAt: endedAt,
                    averageHeartRate: 152,
                    route: [],
                    source: "seeded-archive",
                    id: "seeded-archive-run"
                )
            ]
        }

        save()
    }

    func activateCompanion(id: String) {
        activeCompanionID = id
        save()
    }

    func growthRecord(for companionID: String) -> CompanionGrowthRecord? {
        growthRecords.first(where: { $0.companionID == companionID })
    }

    func buildState(for companionID: String) -> CompanionBuildState? {
        buildStates.first(where: { $0.companionID == companionID })
    }

    func unassignedRuns(from runs: [CompletedRunRecord]) -> [CompletedRunRecord] {
        let assigned = Set(growthRecords.flatMap(\.assignedRunIDs))
        return runs.filter { !assigned.contains($0.id) }
    }

    @discardableResult
    func feed(
        run: CompletedRunRecord,
        to companion: PetCollectionEntry,
        activeEffects: [WeeklyRewardEffect],
        season: WeeklySeason
    ) -> Bool {
        if growthRecords.flatMap(\.assignedRunIDs).contains(run.id) {
            return false
        }

        let currentRecord = growthRecord(for: companion.id)
        let currentProgress = RunimalCompanionGrowthEngine.evolutionProgress(for: currentRecord)
        let resonance = RunimalEffectResonanceEngine.effectResonance(
            for: companion,
            progress: currentProgress,
            activeEffects: activeEffects
        )
        let bonusExperience = RunimalCompanionGrowthEngine.feedBonusExperience(
            baseExperience: run.reward.experience,
            resonance: resonance
        )
        let forgeBonus = RunimalEssenceForgeEngine.bonusExperience(
            using: forgeInventory,
            companion: companion,
            season: season
        )
        let buildBonus = RunimalCompanionBuildEngine.feedBonus(
            for: buildState(for: companion.id),
            run: run,
            companion: companion
        )

        let updated = CompanionGrowthRecord(
            companionID: companion.id,
            totalExperience: (currentRecord?.totalExperience ?? 0) + run.reward.experience + bonusExperience + forgeBonus.bonus + buildBonus,
            feedCount: (currentRecord?.feedCount ?? 0) + 1,
            assignedRunIDs: (currentRecord?.assignedRunIDs ?? []) + [run.id],
            lastFedAt: run.endedAt
        )

        growthRecords.removeAll(where: { $0.companionID == companion.id })
        growthRecords.append(updated)
        activeCompanionID = companion.id
        if forgeBonus.consumeOverdrive {
            overdriveCharges = max(overdriveCharges - 1, 0)
        }
        if forgeBonus.consumeSeasonSigil {
            seasonSigils = max(seasonSigils - 1, 0)
        }
        save()
        return true
    }

    @discardableResult
    func retireCompanion(_ companionID: String, essenceReward: Int) -> Bool {
        guard !retiredCompanionIDs.contains(companionID) else { return false }
        guard companionID != activeCompanionID else { return false }

        retiredCompanionIDs.append(companionID)
        essenceBalance += essenceReward
        save()
        return true
    }

    func append(reward: RunRewardSummary, snapshot: LiveRunSnapshot?) {
        let distanceKm = (snapshot?.distanceMeters ?? 0) / 1000
        let cadence = snapshot?.cadence ?? reward.pet.stats.dexterity * 10 + 130
        let entry = RunimalGameEngine.makeJournalEntry(reward: reward, distanceKm: distanceKm, cadence: cadence)

        if let latest = journal.first,
           latest.reward == reward,
           abs(latest.createdAt.timeIntervalSince(entry.createdAt)) < 90 {
            return
        }

        journal.insert(entry, at: 0)
        journal = Array(journal.prefix(18))
        save()
    }

    func append(completedRun: CompletedRunRecord) {
        if completedRuns.contains(where: { $0.id == completedRun.id }) {
            return
        }

        completedRuns.insert(completedRun, at: 0)
        completedRuns = Array(completedRuns.prefix(12))
        save()
    }

    func claimWeeklyReward(id: String) {
        guard !claimedWeeklyRewards.contains(id) else { return }
        claimedWeeklyRewards.append(id)
        save()
    }

    func setConflictPolicy(_ policy: SnapshotConflictPolicy) {
        conflictPolicy = policy
        save()
    }

    func setDuplicatePriority(_ priority: SnapshotDuplicatePriority) {
        duplicatePriority = priority
        save()
    }

    func recordVerification(_ title: String, passed: Bool) {
        verificationRecords.insert(
            DeviceVerificationRecord(
                id: UUID().uuidString,
                title: title,
                passed: passed,
                recordedAt: Date()
            ),
            at: 0
        )
        verificationRecords = Array(verificationRecords.prefix(8))
        save()
    }

    func importSelectiveCandidate(
        id: String,
        type: String,
        local: RunimalProgressSnapshot?,
        cloud: RunimalProgressSnapshot?
    ) {
        guard let cloud else { return }

        switch type {
        case "run":
            if let record = cloud.completedRuns.first(where: { $0.id == id }),
               !completedRuns.contains(where: { $0.id == id }) {
                completedRuns.insert(record, at: 0)
            }
        case "journal":
            if let entry = cloud.journal.first(where: { $0.id == id }),
               !journal.contains(where: { $0.id == id }) {
                journal.insert(entry, at: 0)
            }
        default:
            break
        }

        if local != nil {
            save()
        }
    }

    @discardableResult
    func claimSeasonReward(id: String) -> Bool {
        guard !claimedSeasonRewardIDs.contains(id) else { return false }
        claimedSeasonRewardIDs.append(id)
        essenceBalance += 40
        seasonSigils += 1
        save()
        return true
    }

    @discardableResult
    func claimRaidReward(
        id: String,
        title: String,
        readinessScore: Int,
        threshold: Int,
        branchReward: RaidBranchReward?
    ) -> Bool {
        guard readinessScore >= threshold else { return false }
        guard !claimedRaidRewardIDs.contains(id) else { return false }

        let resolution = RunimalRaidResolutionEngine.resolve(
            encounter: RaidEncounter(
                id: id,
                title: title,
                detail: "",
                readinessScore: readinessScore,
                recommendedReward: "",
                claimThreshold: threshold
            )
        )
        claimedRaidRewardIDs.append(id)
        raidShardBalance += resolution.shardReward
        essenceBalance += resolution.essenceReward
        essenceBalance += branchReward?.extraEssence ?? 0
        seasonSigils += branchReward?.extraSigils ?? 0
        overdriveCharges += branchReward?.extraOverdrive ?? 0
        if let activeCompanionID {
            if let existing = growthRecord(for: activeCompanionID) {
                let updated = CompanionGrowthRecord(
                    companionID: existing.companionID,
                    totalExperience: existing.totalExperience + (branchReward?.extraEssence ?? 0) + (branchReward?.extraSigils ?? 0) * 18 + (branchReward?.extraOverdrive ?? 0) * 24,
                    feedCount: existing.feedCount,
                    assignedRunIDs: existing.assignedRunIDs,
                    lastFedAt: existing.lastFedAt
                )
                growthRecords.removeAll(where: { $0.companionID == activeCompanionID })
                growthRecords.append(updated)
            }
        }
        lastRaidResolution = resolution
        save()
        return true
    }

    func importAllSelectiveCandidates(type: String, local: RunimalProgressSnapshot?, cloud: RunimalProgressSnapshot?) {
        let candidates = RunimalSelectiveMergeEngine.candidates(local: local, cloud: cloud)
        for candidate in candidates where candidate.type == type {
            importSelectiveCandidate(id: candidate.id, type: candidate.type, local: local, cloud: cloud)
        }
    }

    func resolveRecordDiff(id: String, type: String, useCloud: Bool, local: RunimalProgressSnapshot?, cloud: RunimalProgressSnapshot?) {
        guard let local, let cloud else { return }

        switch type {
        case "run":
            guard let localRecord = local.completedRuns.first(where: { $0.id == id }),
                  let cloudRecord = cloud.completedRuns.first(where: { $0.id == id }) else { return }
            completedRuns.removeAll(where: { $0.id == id })
            completedRuns.insert(useCloud ? cloudRecord : localRecord, at: 0)
        case "journal":
            guard let localEntry = local.journal.first(where: { $0.id == id }),
                  let cloudEntry = cloud.journal.first(where: { $0.id == id }) else { return }
            journal.removeAll(where: { $0.id == id })
            journal.insert(useCloud ? cloudEntry : localEntry, at: 0)
        default:
            break
        }

        save()
    }

    func resolveAllRecordDiffs(
        type: String,
        useCloud: Bool,
        local: RunimalProgressSnapshot?,
        cloud: RunimalProgressSnapshot?
    ) {
        let choices = RunimalRecordDiffEngine.choices(local: local, cloud: cloud).filter { $0.type == type }
        for choice in choices {
            resolveRecordDiff(id: choice.id, type: choice.type, useCloud: useCloud, local: local, cloud: cloud)
        }
    }

    func snapshot(savedAt: Date = Date()) -> RunimalProgressSnapshot {
        RunimalProgressSnapshot(
            savedAt: savedAt,
            originDeviceID: deviceID,
            journal: journal,
            completedRuns: completedRuns,
            claimedWeeklyRewards: claimedWeeklyRewards,
            activeCompanionID: activeCompanionID,
            growthRecords: growthRecords,
            retiredCompanionIDs: retiredCompanionIDs,
            essenceBalance: essenceBalance,
            overdriveCharges: overdriveCharges,
            seasonSigils: seasonSigils,
            buildStates: buildStates,
            claimedSeasonRewardIDs: claimedSeasonRewardIDs,
            claimedRaidRewardIDs: claimedRaidRewardIDs,
            raidShardBalance: raidShardBalance
        )
    }

    func restore(from snapshot: RunimalProgressSnapshot) {
        journal = snapshot.journal
        completedRuns = snapshot.completedRuns
        claimedWeeklyRewards = snapshot.claimedWeeklyRewards
        activeCompanionID = snapshot.activeCompanionID
        growthRecords = snapshot.growthRecords
        retiredCompanionIDs = snapshot.retiredCompanionIDs
        essenceBalance = snapshot.essenceBalance
        overdriveCharges = snapshot.overdriveCharges
        seasonSigils = snapshot.seasonSigils
        buildStates = snapshot.buildStates
        claimedSeasonRewardIDs = snapshot.claimedSeasonRewardIDs
        claimedRaidRewardIDs = snapshot.claimedRaidRewardIDs
        raidShardBalance = snapshot.raidShardBalance
        if deviceID.isEmpty {
            deviceID = snapshot.originDeviceID
        }
        save()
    }

    var forgeInventory: ForgeInventory {
        ForgeInventory(overdriveCharges: overdriveCharges, seasonSigils: seasonSigils)
    }

    @discardableResult
    func purchaseForgeOption(_ option: EssenceForgeOption) -> Bool {
        guard essenceBalance >= option.cost else { return false }

        essenceBalance -= option.cost

        switch option.id {
        case "forge-overdrive":
            overdriveCharges += 1
        case "forge-season-sigil":
            seasonSigils += 1
        default:
            essenceBalance += option.cost
            return false
        }

        save()
        return true
    }

    func selectRole(_ role: CompanionRole, for companionID: String) {
        let current = buildState(for: companionID)
        let next = CompanionBuildState(
            companionID: companionID,
            selectedRole: role,
            unlockedNodeIDs: current?.selectedRole == role ? (current?.unlockedNodeIDs ?? []) : []
        )
        buildStates.removeAll(where: { $0.companionID == companionID })
        buildStates.append(next)
        save()
    }

    @discardableResult
    func unlockSkillNode(_ nodeID: String, for companionID: String, cost: Int) -> Bool {
        guard essenceBalance >= cost else { return false }
        let current = buildState(for: companionID) ?? CompanionBuildState(
            companionID: companionID,
            selectedRole: .relay,
            unlockedNodeIDs: []
        )
        guard !current.unlockedNodeIDs.contains(nodeID) else { return false }

        essenceBalance -= cost
        let next = CompanionBuildState(
            companionID: companionID,
            selectedRole: current.selectedRole,
            unlockedNodeIDs: current.unlockedNodeIDs + [nodeID]
        )
        buildStates.removeAll(where: { $0.companionID == companionID })
        buildStates.append(next)
        save()
        return true
    }

    private func save() {
        do {
            let journalData = try JSONEncoder().encode(journal)
            defaults.set(journalData, forKey: Keys.journal)
        } catch {
            defaults.removeObject(forKey: Keys.journal)
        }

        do {
            let completedRunData = try JSONEncoder().encode(completedRuns)
            defaults.set(completedRunData, forKey: Keys.completedRuns)
        } catch {
            defaults.removeObject(forKey: Keys.completedRuns)
        }

        defaults.set(claimedWeeklyRewards, forKey: Keys.claimedWeeklyRewards)
        defaults.set(activeCompanionID, forKey: Keys.activeCompanionID)

        do {
            let growthRecordData = try JSONEncoder().encode(growthRecords)
            defaults.set(growthRecordData, forKey: Keys.growthRecords)
        } catch {
            defaults.removeObject(forKey: Keys.growthRecords)
        }

        defaults.set(retiredCompanionIDs, forKey: Keys.retiredCompanionIDs)
        defaults.set(essenceBalance, forKey: Keys.essenceBalance)
        defaults.set(overdriveCharges, forKey: Keys.overdriveCharges)
        defaults.set(seasonSigils, forKey: Keys.seasonSigils)

        do {
            let buildStateData = try JSONEncoder().encode(buildStates)
            defaults.set(buildStateData, forKey: Keys.buildStates)
        } catch {
            defaults.removeObject(forKey: Keys.buildStates)
        }

        defaults.set(claimedSeasonRewardIDs, forKey: Keys.claimedSeasonRewardIDs)
        defaults.set(claimedRaidRewardIDs, forKey: Keys.claimedRaidRewardIDs)
        defaults.set(raidShardBalance, forKey: Keys.raidShardBalance)
        defaults.set(deviceID, forKey: Keys.deviceID)
        defaults.set(conflictPolicy.rawValue, forKey: Keys.conflictPolicy)
        defaults.set(duplicatePriority.rawValue, forKey: Keys.duplicatePriority)
        if let data = try? JSONEncoder().encode(verificationRecords) {
            defaults.set(data, forKey: Keys.verificationRecords)
        } else {
            defaults.removeObject(forKey: Keys.verificationRecords)
        }

        if let lastRaidResolution,
           let data = try? JSONEncoder().encode(lastRaidResolution) {
            defaults.set(data, forKey: Keys.lastRaidResolution)
        } else {
            defaults.removeObject(forKey: Keys.lastRaidResolution)
        }
    }
}
