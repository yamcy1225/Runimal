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
    func claimRaidReward(id: String, readinessScore: Int, threshold: Int) -> Bool {
        guard readinessScore >= threshold else { return false }
        guard !claimedRaidRewardIDs.contains(id) else { return false }

        claimedRaidRewardIDs.append(id)
        raidShardBalance += 1
        essenceBalance += 24
        save()
        return true
    }

    func snapshot(savedAt: Date = Date()) -> RunimalProgressSnapshot {
        RunimalProgressSnapshot(
            savedAt: savedAt,
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
    }
}
