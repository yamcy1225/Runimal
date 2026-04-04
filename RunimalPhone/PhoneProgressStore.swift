import Foundation
import Observation
import RunimalCore

struct CompanionFeedProjection {
    let runID: String
    let coreLabel: String
    let baseExperience: Int
    let supportBonusExperience: Int
    let dataBonusExperience: Int
    let storedPotentialExperience: Int
    let potentialExperienceSpent: Int
    let projectedRemainingStoredPotentialExperience: Int
    let projectedTotalExperience: Int
    let beforeSnapshot: CompanionProgressionSnapshot
    let projectedSnapshot: CompanionProgressionSnapshot
    let beforeProgress: EvolutionProgress
    let projectedProgress: EvolutionProgress
    let bonusLabels: [String]

    var hasPotentialSpend: Bool {
        potentialExperienceSpent > 0
    }

    var levelGain: Int {
        projectedSnapshot.level - beforeSnapshot.level
    }

    var stageAdvanced: Bool {
        beforeSnapshot.stageIndex != projectedSnapshot.stageIndex
    }
}

@MainActor
@Observable
final class PhoneProgressStore {
    private enum Keys {
        static let journal = "runimal.phone.journal"
        static let completedRuns = "runimal.phone.completedRuns"
        static let ownedCompanions = "runimal.phone.ownedCompanions"
        static let eggInventory = "runimal.phone.eggInventory"
        static let unlockedEggAchievementIDs = "runimal.phone.unlockedEggAchievementIDs"
        static let claimedWeeklyRewards = "runimal.phone.claimedWeeklyRewards"
        static let activeCompanionID = "runimal.phone.activeCompanionID"
        static let mainCompanionSelection = "runimal.phone.mainCompanionSelection"
        static let watchCompanionSelection = "runimal.phone.watchCompanionSelection"
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
        static let workoutArchives = "runimal.phone.workoutArchives"
        static let autoPauseEnabled = "runimal.phone.autoPauseEnabled"
        static let worldProgress = "runimal.phone.worldProgress"
    }

    private let defaults: UserDefaults
    private let archivePersistence: PhoneWorkoutArchivePersistence
    var journal: [RunJournalEntry] = []
    var completedRuns: [CompletedRunRecord] = []
    var ownedCompanions: [PetCollectionEntry] = []
    var eggInventory: [EggInventoryEntry] = []
    var unlockedEggAchievementIDs: [String] = []
    var claimedWeeklyRewards: [String] = []
    var activeCompanionID: String?
    var mainCompanionSelection: MainCompanionSelection?
    var watchCompanionSelection: MainCompanionSelection?
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
    var lastSanctuaryReward: SanctuaryRewardEvent?
    var workoutArchives: [WorkoutSessionArchive] = []
    var autoPauseEnabled = true
    var worldProgressSnapshot: WorldProgressSnapshot = .empty

    init(
        defaults: UserDefaults = .standard,
        archivePersistence: PhoneWorkoutArchivePersistence = PhoneWorkoutArchivePersistence()
    ) {
        self.defaults = defaults
        self.archivePersistence = archivePersistence
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

        completedRuns = archivePersistence.loadCompletedRuns(
            fallbackData: defaults.data(forKey: Keys.completedRuns)
        )

        if let data = defaults.data(forKey: Keys.ownedCompanions) {
            ownedCompanions = (try? JSONDecoder().decode([PetCollectionEntry].self, from: data)) ?? []
        } else {
            ownedCompanions = []
        }

        if let data = defaults.data(forKey: Keys.eggInventory) {
            eggInventory = (try? JSONDecoder().decode([EggInventoryEntry].self, from: data)) ?? []
        } else {
            eggInventory = []
        }

        unlockedEggAchievementIDs = defaults.stringArray(forKey: Keys.unlockedEggAchievementIDs) ?? []
        claimedWeeklyRewards = defaults.stringArray(forKey: Keys.claimedWeeklyRewards) ?? []
        activeCompanionID = defaults.string(forKey: Keys.activeCompanionID)
        if let data = defaults.data(forKey: Keys.mainCompanionSelection) {
            mainCompanionSelection = try? JSONDecoder().decode(MainCompanionSelection.self, from: data)
        } else {
            mainCompanionSelection = nil
        }
        if let data = defaults.data(forKey: Keys.watchCompanionSelection) {
            watchCompanionSelection = try? JSONDecoder().decode(MainCompanionSelection.self, from: data)
        } else {
            watchCompanionSelection = nil
        }

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

        workoutArchives = archivePersistence.loadWorkoutArchives(
            fallbackData: defaults.data(forKey: Keys.workoutArchives)
        )

        if defaults.object(forKey: Keys.autoPauseEnabled) == nil {
            autoPauseEnabled = true
        } else {
            autoPauseEnabled = defaults.bool(forKey: Keys.autoPauseEnabled)
        }

        if let data = defaults.data(forKey: Keys.worldProgress) {
            worldProgressSnapshot = (try? JSONDecoder().decode(WorldProgressSnapshot.self, from: data)) ?? .empty
        } else {
            worldProgressSnapshot = .empty
        }

        if worldProgressSnapshot == .empty, completedRuns.isEmpty == false {
            worldProgressSnapshot = RunimalWorldProgressEngine.rebuild(from: completedRuns)
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
            completedRuns = [makeSeededArchiveRun(from: summary)]
        }

        if ownedCompanions.isEmpty,
           eggInventory.isEmpty,
           let seededRun = completedRuns.first {
            let shell = RunimalEggEngine.shell(for: seededRun)
            eggInventory = [
                EggInventoryEntry(
                    id: "starter-egg-\(seededRun.id)",
                    shell: shell,
                    title: RunimalEggEngine.title(for: shell),
                    createdAt: seededRun.endedAt,
                    sourceRunID: seededRun.id,
                    storedExperience: RunimalEggEngine.initialExperience(
                        for: seededRun,
                        starterBoosted: true
                    ),
                    hatchThreshold: RunimalEggEngine.hatchThreshold(
                        for: shell,
                        run: seededRun,
                        starterBoosted: true
                    ),
                    incubationRunIDs: [],
                    unlockedAchievementIDs: [],
                    starterBoosted: true
                )
            ]
        }

        if mainCompanionSelection == nil {
            if let firstEgg = eggInventory.first {
                mainCompanionSelection = MainCompanionSelection(kind: .egg, targetID: firstEgg.id)
                activeCompanionID = nil
            } else if let firstCompanion = ownedCompanions.first {
                mainCompanionSelection = MainCompanionSelection(kind: .pet, targetID: firstCompanion.id)
                activeCompanionID = activeCompanionID ?? firstCompanion.id
            }
        }

        if watchCompanionSelection == nil {
            watchCompanionSelection = mainCompanionSelection
        }

        save()
    }

    func activateCompanion(id: String) {
        activeCompanionID = id
        mainCompanionSelection = MainCompanionSelection(kind: .pet, targetID: id)
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
        let eggConsumed = Set(eggInventory.flatMap { [$0.sourceRunID] + $0.incubationRunIDs })
        return runs.filter { !assigned.contains($0.id) && !eggConsumed.contains($0.id) }
    }

    func feedProjection(
        run: CompletedRunRecord,
        to companion: PetCollectionEntry,
        activeEffects: [WeeklyRewardEffect],
        season: WeeklySeason
    ) -> CompanionFeedProjection? {
        guard let computation = makeFeedComputation(
            run: run,
            to: companion,
            activeEffects: activeEffects,
            season: season
        ) else {
            return nil
        }

        return computation.projection
    }

    @discardableResult
    func feed(
        run: CompletedRunRecord,
        to companion: PetCollectionEntry,
        activeEffects: [WeeklyRewardEffect],
        season: WeeklySeason
    ) -> CompanionFeedOutcome? {
        guard let computation = makeFeedComputation(
            run: run,
            to: companion,
            activeEffects: activeEffects,
            season: season
        ) else {
            return nil
        }

        growthRecords.removeAll(where: { $0.companionID == companion.id })
        growthRecords.append(computation.updatedRecord)
        activeCompanionID = companion.id
        if computation.forgeBonus.consumeOverdrive {
            overdriveCharges = max(overdriveCharges - 1, 0)
        }
        if computation.forgeBonus.consumeSeasonSigil {
            seasonSigils = max(seasonSigils - 1, 0)
        }
        save()
        return CompanionFeedOutcome(
            runID: run.id,
            coreLabel: run.reward.coreLabel,
            gainedExperience: computation.gainedExperience,
            baseExperience: computation.baseExperience,
            supportBonusExperience: computation.supportBonusExperience,
            dataBonusExperience: computation.dataBonusExperience,
            storedPotentialExperienceBefore: computation.storedPotentialExperience,
            potentialExperienceSpent: computation.potentialExperienceSpent,
            remainingStoredPotentialExperience: computation.remainingStoredPotentialExperience,
            bonusLabels: computation.bonusLabels,
            beforeSnapshot: computation.beforeSnapshot,
            afterSnapshot: computation.afterSnapshot,
            beforeProgress: computation.beforeProgress,
            afterProgress: computation.afterProgress,
            stageAdvanced: computation.beforeProgress.stageLabel != computation.afterProgress.stageLabel
        )
    }

    private func makeFeedComputation(
        run: CompletedRunRecord,
        to companion: PetCollectionEntry,
        activeEffects: [WeeklyRewardEffect],
        season: WeeklySeason
    ) -> CompanionFeedComputation? {
        if growthRecords.flatMap(\.assignedRunIDs).contains(run.id) {
            return nil
        }

        let currentRecord = growthRecord(for: companion.id)
        let beforeSnapshot = RunimalCompanionGrowthEngine.progressionSnapshot(
            for: currentRecord,
            species: companion.pet.species
        )
        let beforeProgress = beforeSnapshot.progress
        let resonance = RunimalEffectResonanceEngine.effectResonance(
            for: companion,
            progress: beforeProgress,
            activeEffects: activeEffects
        )
        let resonanceBonus = RunimalCompanionGrowthEngine.feedBonusExperience(
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
        var interactionEvents: [CompanionProgressionEvent] = []
        if let lastFedAt = currentRecord?.lastFedAt {
            if Calendar.current.isDate(lastFedAt, inSameDayAs: Date()) == false {
                interactionEvents.append(.firstFeedOfDay)
            }
        } else {
            interactionEvents.append(.firstFeedOfDay)
        }
        if canonicalProgressionSpeciesID(for: run.reward.pet.species) == canonicalProgressionSpeciesID(for: companion.pet.species) {
            interactionEvents.append(.matchingSpecies)
        }
        if let runVariant = run.reward.pet.rareVariant,
           runVariant == companion.pet.rareVariant {
            interactionEvents.append(.matchingVariant)
        }
        if RunimalGameEngine.seasonAffinity(for: companion.pet, season: season) {
            interactionEvents.append(.seasonAffinity)
        }
        if run.reward.completedQuestCount >= 2 {
            interactionEvents.append(.masteryLink)
        }
        if let latestAssignedRun = currentRecord
            .flatMap({ record in completedRuns.filter { record.assignedRunIDs.contains($0.id) }.sorted { $0.endedAt < $1.endedAt }.last }),
           latestAssignedRun.worldImpact?.regionID == run.worldImpact?.regionID {
            interactionEvents.append(.homeRegion)
        }
        if run.worldImpact?.episodeID != nil {
            interactionEvents.append(.episodeSignal)
        }
        if run.worldImpact?.unlockedRegion == true {
            interactionEvents.append(.regionUnlock)
        }
        if run.worldImpact?.unlockedSeason == true {
            interactionEvents.append(.seasonUnlock)
        }
        if run.worldImpact?.unlockedEpisode == true {
            interactionEvents.append(.episodeUnlock)
        }
        let interactionBonus = RunimalCompanionProgressionEngine.interactionBonus(
            baseExperience: run.reward.experience,
            events: interactionEvents,
            stageIndex: beforeSnapshot.stageIndex
        )
        let dataProfile = RunimalRunCoreGrowthBalanceEngine.dataProfile(for: run)
        let levelBefore = beforeSnapshot.level
        let seasonAligned = RunimalGameEngine.seasonAffinity(for: companion.pet, season: season)
        let storedPotential = currentRecord?.storedPotentialExperience ?? 0
        let potentialSpend = min(
            storedPotential,
            RunimalRunCoreGrowthBalanceEngine.potentialSpendCap(
                baseExperience: run.reward.experience,
                level: levelBefore
            )
        )
        let lateGrowthBonus = RunimalCompanionProgressionEngine.lateGrowthBonus(
            level: levelBefore,
            dataProfile: dataProfile,
            potentialSpend: potentialSpend,
            seasonAligned: seasonAligned,
            worldImpact: run.worldImpact
        )
        let retainedGrowthLabels = RunimalCompanionProgressionEngine.lateGrowthRetentionLabels(
            level: levelBefore,
            run: run,
            dataProfile: dataProfile,
            seasonTitle: season.title,
            seasonAligned: seasonAligned
        )
        let rawExperience = run.reward.experience +
            dataProfile.bonusExperience +
            resonanceBonus +
            forgeBonus.bonus +
            buildBonus +
            interactionBonus.bonusExperience +
            lateGrowthBonus.bonusExperience +
            potentialSpend
        let starterStageGuarantee = RunimalStarterLoopEngine.shouldGuaranteeFirstVisibleStageAdvance(
            record: currentRecord,
            currentStageLabel: beforeProgress.stageLabel,
            run: run
        )
        let stageLock = RunimalRewardPulseEngine.stageLock(
            currentProgress: beforeProgress,
            proposedExperience: rawExperience
        )
        let currentExperience = currentRecord?.totalExperience ?? 0
        let uncappedExperience: Int

        if starterStageGuarantee {
            uncappedExperience = max(
                rawExperience + stageLock.bonusExperience,
                RunimalStarterLoopEngine.guaranteedFirstVisibleStageGain(
                    currentExperience: currentExperience,
                    species: companion.pet.species
                )
            )
        } else {
            uncappedExperience = rawExperience + stageLock.bonusExperience
        }

        let gainedExperience = RunimalBalanceConfig.cappedExperienceGain(
            currentExperience: currentExperience,
            proposedGain: starterStageGuarantee ? 0 : uncappedExperience,
            currentLevel: levelBefore,
            runDistanceKm: run.distanceMeters / 1000
        )
        let resolvedGainedExperience = starterStageGuarantee ? uncappedExperience : gainedExperience
        let growthCapApplied = starterStageGuarantee == false && gainedExperience < uncappedExperience

        let remainingStoredPotentialExperience = max(storedPotential - potentialSpend, 0)
        let updatedRecord = CompanionGrowthRecord(
            companionID: companion.id,
            totalExperience: currentExperience + resolvedGainedExperience,
            storedPotentialExperience: remainingStoredPotentialExperience,
            feedCount: (currentRecord?.feedCount ?? 0) + 1,
            assignedRunIDs: (currentRecord?.assignedRunIDs ?? []) + [run.id],
            lastFedAt: run.endedAt
        )
        let afterSnapshot = RunimalCompanionGrowthEngine.progressionSnapshot(
            for: updatedRecord,
            species: companion.pet.species
        )
        let afterProgress = afterSnapshot.progress
        let supportBonusExperience = resonanceBonus +
            forgeBonus.bonus +
            buildBonus +
            interactionBonus.bonusExperience +
            lateGrowthBonus.bonusExperience +
            stageLock.bonusExperience
        let bonusLabels = stageLock.bonusLabels +
            interactionBonus.labels +
            lateGrowthBonus.labels +
            (starterStageGuarantee ? ["첫 성장 고정"] : []) +
            (growthCapApplied ? ["10km 미만 1레벨 상한"] : []) +
            retainedGrowthLabels +
            (potentialSpend > 0 ? ["동행 잠재 사용 +\(potentialSpend)"] : [])

        return CompanionFeedComputation(
            runID: run.id,
            coreLabel: run.reward.coreLabel,
            baseExperience: run.reward.experience,
            supportBonusExperience: supportBonusExperience,
            dataBonusExperience: dataProfile.bonusExperience,
            storedPotentialExperience: storedPotential,
            potentialExperienceSpent: potentialSpend,
            remainingStoredPotentialExperience: remainingStoredPotentialExperience,
            gainedExperience: resolvedGainedExperience,
            beforeSnapshot: beforeSnapshot,
            afterSnapshot: afterSnapshot,
            beforeProgress: beforeProgress,
            afterProgress: afterProgress,
            bonusLabels: bonusLabels,
            updatedRecord: updatedRecord,
            forgeBonus: forgeBonus
        )
    }

    private struct CompanionFeedComputation {
        let runID: String
        let coreLabel: String
        let baseExperience: Int
        let supportBonusExperience: Int
        let dataBonusExperience: Int
        let storedPotentialExperience: Int
        let potentialExperienceSpent: Int
        let remainingStoredPotentialExperience: Int
        let gainedExperience: Int
        let beforeSnapshot: CompanionProgressionSnapshot
        let afterSnapshot: CompanionProgressionSnapshot
        let beforeProgress: EvolutionProgress
        let afterProgress: EvolutionProgress
        let bonusLabels: [String]
        let updatedRecord: CompanionGrowthRecord
        let forgeBonus: (bonus: Int, consumeOverdrive: Bool, consumeSeasonSigil: Bool)

        var projection: CompanionFeedProjection {
            CompanionFeedProjection(
                runID: runID,
                coreLabel: coreLabel,
                baseExperience: baseExperience,
                supportBonusExperience: supportBonusExperience,
                dataBonusExperience: dataBonusExperience,
                storedPotentialExperience: storedPotentialExperience,
                potentialExperienceSpent: potentialExperienceSpent,
                projectedRemainingStoredPotentialExperience: remainingStoredPotentialExperience,
                projectedTotalExperience: gainedExperience,
                beforeSnapshot: beforeSnapshot,
                projectedSnapshot: afterSnapshot,
                beforeProgress: beforeProgress,
                projectedProgress: afterProgress,
                bonusLabels: bonusLabels
            )
        }
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

    func append(
        completedRun: CompletedRunRecord,
        pack: WorldContentPack = DefaultWorldContent.pack
    ) {
        completedRuns.removeAll(where: { $0.id == completedRun.id })
        let recalculatedRun = completedRunWithDerivedState(completedRun, pack: pack)
        completedRuns.insert(recalculatedRun, at: 0)
        worldProgressSnapshot = RunimalWorldProgressEngine.applying(
            run: recalculatedRun,
            to: worldProgressSnapshot,
            pack: pack
        )
        save()
    }

    @discardableResult
    func storeLiveCompanionPotential(from run: CompletedRunRecord, companionID: String) -> LiveCompanionPotentialProfile {
        let profile = RunimalRunCoreGrowthBalanceEngine.livePotential(for: run)
        guard profile.storedPotentialExperience > 0 else { return profile }

        let existing = growthRecord(for: companionID)
        let currentLevel = RunimalBalanceConfig.companionLevel(
            forExperience: existing?.totalExperience ?? 0
        )
        let updated = CompanionGrowthRecord(
            companionID: companionID,
            totalExperience: existing?.totalExperience ?? 0,
            storedPotentialExperience: min(
                (existing?.storedPotentialExperience ?? 0) + profile.storedPotentialExperience,
                RunimalRunCoreGrowthBalanceEngine.storedPotentialCap(forLevel: currentLevel)
            ),
            feedCount: existing?.feedCount ?? 0,
            assignedRunIDs: existing?.assignedRunIDs ?? [],
            lastFedAt: existing?.lastFedAt
        )

        growthRecords.removeAll(where: { $0.companionID == companionID })
        growthRecords.append(updated)
        save()
        return profile
    }

    func append(workoutArchive: WorkoutSessionArchive) {
        workoutArchives.removeAll(where: { $0.runID == workoutArchive.runID })
        workoutArchives.insert(workoutArchive, at: 0)
        save()
    }

    private func completedRunWithDerivedState(
        _ run: CompletedRunRecord,
        pack: WorldContentPack
    ) -> CompletedRunRecord {
        let speciesRuns = runsForMutationProgress(species: run.reward.pet.species, including: run)
        let mutationForm = SpeciesMutationUnlockEngine.resolveForm(
            for: speciesRuns,
            preferredSpecies: run.reward.pet.species
        )?.snapshot
        let mutationContribution = run.mutationContribution ?? SpeciesMutationContributionEngine.runContribution(
            for: run,
            preferredSpecies: run.reward.pet.species
        )
        let baseRun = CompletedRunRecord(
            id: run.id,
            startedAt: run.startedAt,
            endedAt: run.endedAt,
            distanceMeters: run.distanceMeters,
            durationSeconds: run.durationSeconds,
            averageHeartRate: run.averageHeartRate,
            averagePaceSeconds: run.averagePaceSeconds,
            cadence: run.cadence,
            elevationGainM: run.elevationGainM,
            reward: run.reward,
            route: run.route,
            source: run.source,
            sourceLabel: run.sourceLabel,
            raidContribution: run.raidContribution,
            environmentCondition: run.environmentCondition,
            rareEventCompleted: run.rareEventCompleted,
            liveCompanionID: run.liveCompanionID,
            liveCompanionName: run.liveCompanionName,
            livePotentialProfile: run.livePotentialProfile,
            mutationForm: mutationForm,
            mutationContribution: mutationContribution,
            worldImpact: run.worldImpact
        )
        let worldImpact = RunimalWorldProgressEngine.impact(
            for: baseRun,
            current: worldProgressSnapshot,
            pack: pack
        ) ?? run.worldImpact

        return CompletedRunRecord(
            id: run.id,
            startedAt: run.startedAt,
            endedAt: run.endedAt,
            distanceMeters: run.distanceMeters,
            durationSeconds: run.durationSeconds,
            averageHeartRate: run.averageHeartRate,
            averagePaceSeconds: run.averagePaceSeconds,
            cadence: run.cadence,
            elevationGainM: run.elevationGainM,
            reward: run.reward,
            route: run.route,
            source: run.source,
            sourceLabel: run.sourceLabel,
            raidContribution: run.raidContribution,
            environmentCondition: run.environmentCondition,
            rareEventCompleted: run.rareEventCompleted,
            liveCompanionID: run.liveCompanionID,
            liveCompanionName: run.liveCompanionName,
            livePotentialProfile: run.livePotentialProfile,
            mutationForm: mutationForm,
            mutationContribution: mutationContribution,
            worldImpact: worldImpact
        )
    }

    private func runsForMutationProgress(species: PetSpecies, including run: CompletedRunRecord) -> [CompletedRunRecord] {
        let canonicalSpeciesID = canonicalMutationSpeciesID(for: species)
        var runs = completedRuns.filter { canonicalMutationSpeciesID(for: $0.reward.pet.species) == canonicalSpeciesID }
        runs.append(run)
        return runs.sorted { $0.endedAt < $1.endedAt }
    }

    private func canonicalMutationSpeciesID(for species: PetSpecies) -> String {
        switch species {
        case .shadebit:
            return PetSpecies.sparkfang.rawValue
        default:
            return species.rawValue
        }
    }

    private func canonicalProgressionSpeciesID(for species: PetSpecies) -> String {
        switch species {
        case .shadebit:
            return PetSpecies.sparkfang.rawValue
        default:
            return species.rawValue
        }
    }

    func workoutArchive(for runID: String) -> WorkoutSessionArchive? {
        workoutArchives.first(where: { $0.runID == runID })
    }

    func removeImportedExternalRuns() {
        let importedIDs = Set(
            completedRuns
                .filter { $0.source.hasPrefix("healthkit:") || $0.source.hasPrefix("fit:") }
                .map(\.id)
        )
        guard !importedIDs.isEmpty else { return }

        completedRuns.removeAll { importedIDs.contains($0.id) }
        workoutArchives.removeAll { importedIDs.contains($0.runID) }
        journal.removeAll { importedIDs.contains($0.id) }
        growthRecords = growthRecords.map { record in
            CompanionGrowthRecord(
                companionID: record.companionID,
                totalExperience: record.totalExperience,
                storedPotentialExperience: record.storedPotentialExperience,
                feedCount: record.feedCount,
                assignedRunIDs: record.assignedRunIDs.filter { !importedIDs.contains($0) },
                lastFedAt: record.lastFedAt
            )
        }
        eggInventory.removeAll { importedIDs.contains($0.sourceRunID) }
        eggInventory = eggInventory.map { egg in
            EggInventoryEntry(
                id: egg.id,
                shell: egg.shell,
                title: egg.title,
                createdAt: egg.createdAt,
                sourceRunID: egg.sourceRunID,
                storedExperience: egg.storedExperience,
                hatchThreshold: egg.hatchThreshold,
                incubationRunIDs: egg.incubationRunIDs.filter { !importedIDs.contains($0) },
                unlockedAchievementIDs: egg.unlockedAchievementIDs,
                starterBoosted: egg.starterBoosted
            )
        }

        if case .egg = mainCompanionSelection?.kind,
           let targetID = mainCompanionSelection?.targetID,
           eggInventory.contains(where: { $0.id == targetID }) == false {
            mainCompanionSelection = activeCompanionID.map { MainCompanionSelection(kind: .pet, targetID: $0) }
        }

        rebuildWorldProgress()
        save()
    }

    func canDeleteRun(id: String) -> Bool {
        guard completedRuns.contains(where: { $0.id == id }) else { return false }
        if growthRecords.contains(where: { $0.assignedRunIDs.contains(id) }) { return false }
        if eggInventory.contains(where: { $0.sourceRunID == id || $0.incubationRunIDs.contains(id) }) { return false }
        return true
    }

    @discardableResult
    func removeRun(
        id: String,
        pack: WorldContentPack = DefaultWorldContent.pack
    ) -> Bool {
        guard canDeleteRun(id: id) else { return false }

        completedRuns.removeAll(where: { $0.id == id })
        workoutArchives.removeAll(where: { $0.runID == id })
        journal.removeAll(where: { $0.id == id })

        do {
            try archivePersistence.removeWorkoutPackageFiles(forRunID: id)
        } catch {
            // The persisted arrays remain canonical even if package file cleanup fails.
        }

        rebuildWorldProgress(pack: pack)
        save()
        return true
    }

    func rebuildWorldProgress(pack: WorldContentPack = DefaultWorldContent.pack) {
        worldProgressSnapshot = RunimalWorldProgressEngine.rebuild(from: completedRuns, pack: pack)
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

    func setAutoPauseEnabled(_ enabled: Bool) {
        autoPauseEnabled = enabled
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
                    storedPotentialExperience: existing.storedPotentialExperience,
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
            ownedCompanions: ownedCompanions,
            eggInventory: eggInventory,
            unlockedEggAchievementIDs: unlockedEggAchievementIDs,
            claimedWeeklyRewards: claimedWeeklyRewards,
            activeCompanionID: activeCompanionID,
            mainCompanionSelection: mainCompanionSelection,
            growthRecords: growthRecords,
            retiredCompanionIDs: retiredCompanionIDs,
            essenceBalance: essenceBalance,
            overdriveCharges: overdriveCharges,
            seasonSigils: seasonSigils,
            buildStates: buildStates,
            claimedSeasonRewardIDs: claimedSeasonRewardIDs,
            claimedRaidRewardIDs: claimedRaidRewardIDs,
            raidShardBalance: raidShardBalance,
            raidContributionTotal: completedRuns.reduce(0) { $0 + $1.raidContribution },
            worldProgress: worldProgressSnapshot
        )
    }

    func restore(from snapshot: RunimalProgressSnapshot) {
        journal = snapshot.journal
        completedRuns = snapshot.completedRuns
        ownedCompanions = snapshot.ownedCompanions
        eggInventory = snapshot.eggInventory
        unlockedEggAchievementIDs = snapshot.unlockedEggAchievementIDs
        claimedWeeklyRewards = snapshot.claimedWeeklyRewards
        activeCompanionID = snapshot.activeCompanionID
        mainCompanionSelection = snapshot.mainCompanionSelection
        if watchCompanionSelection == nil {
            watchCompanionSelection = snapshot.mainCompanionSelection
        }
        growthRecords = snapshot.growthRecords
        retiredCompanionIDs = snapshot.retiredCompanionIDs
        essenceBalance = snapshot.essenceBalance
        overdriveCharges = snapshot.overdriveCharges
        seasonSigils = snapshot.seasonSigils
        buildStates = snapshot.buildStates
        claimedSeasonRewardIDs = snapshot.claimedSeasonRewardIDs
        claimedRaidRewardIDs = snapshot.claimedRaidRewardIDs
        raidShardBalance = snapshot.raidShardBalance
        worldProgressSnapshot = snapshot.worldProgress
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

    func resetProgress(from summaries: [RunSummary]) {
        do {
            try archivePersistence.clearAll()
        } catch {
            // Save will recreate canonical storage after reset.
        }
        journal = []
        completedRuns = []
        workoutArchives = []
        ownedCompanions = []
        eggInventory = []
        unlockedEggAchievementIDs = []
        claimedWeeklyRewards = []
        activeCompanionID = nil
        mainCompanionSelection = nil
        watchCompanionSelection = nil
        growthRecords = []
        retiredCompanionIDs = []
        essenceBalance = 0
        overdriveCharges = 0
        seasonSigils = 0
        buildStates = []
        claimedSeasonRewardIDs = []
        claimedRaidRewardIDs = []
        raidShardBalance = 0
        lastRaidResolution = nil
        verificationRecords = []
        conflictPolicy = .merged
        duplicatePriority = .newestWins
        worldProgressSnapshot = .empty
        save()
        seedIfNeeded(from: summaries)
    }

    var hasPersistedState: Bool {
        let keyedDefaults = [
            Keys.journal,
            Keys.completedRuns,
            Keys.ownedCompanions,
            Keys.eggInventory,
            Keys.unlockedEggAchievementIDs,
            Keys.claimedWeeklyRewards,
            Keys.activeCompanionID,
            Keys.mainCompanionSelection,
            Keys.watchCompanionSelection,
            Keys.growthRecords,
            Keys.retiredCompanionIDs,
            Keys.essenceBalance,
            Keys.overdriveCharges,
            Keys.seasonSigils,
            Keys.buildStates,
            Keys.claimedSeasonRewardIDs,
            Keys.claimedRaidRewardIDs,
            Keys.raidShardBalance,
            Keys.lastRaidResolution,
            Keys.conflictPolicy,
            Keys.verificationRecords,
            Keys.duplicatePriority,
            Keys.workoutArchives,
            Keys.autoPauseEnabled,
            Keys.worldProgress,
        ]

        if keyedDefaults.contains(where: { defaults.object(forKey: $0) != nil }) {
            return true
        }

        return archivePersistence.hasPersistedData()
    }

    func save() {
        do {
            let journalData = try JSONEncoder().encode(journal)
            defaults.set(journalData, forKey: Keys.journal)
        } catch {
            defaults.removeObject(forKey: Keys.journal)
        }

        do {
            try archivePersistence.saveCompletedRuns(completedRuns)
            defaults.removeObject(forKey: Keys.completedRuns)
        } catch {
            if let completedRunData = try? JSONEncoder().encode(completedRuns) {
                defaults.set(completedRunData, forKey: Keys.completedRuns)
            }
        }

        do {
            try archivePersistence.saveWorkoutArchives(workoutArchives)
            defaults.removeObject(forKey: Keys.workoutArchives)
        } catch {
            if let archiveData = try? JSONEncoder().encode(workoutArchives) {
                defaults.set(archiveData, forKey: Keys.workoutArchives)
            }
        }

        if let data = try? JSONEncoder().encode(ownedCompanions) {
            defaults.set(data, forKey: Keys.ownedCompanions)
        } else {
            defaults.removeObject(forKey: Keys.ownedCompanions)
        }

        if let data = try? JSONEncoder().encode(eggInventory) {
            defaults.set(data, forKey: Keys.eggInventory)
        } else {
            defaults.removeObject(forKey: Keys.eggInventory)
        }

        defaults.set(unlockedEggAchievementIDs, forKey: Keys.unlockedEggAchievementIDs)
        defaults.set(claimedWeeklyRewards, forKey: Keys.claimedWeeklyRewards)
        defaults.set(activeCompanionID, forKey: Keys.activeCompanionID)
        if let data = try? JSONEncoder().encode(mainCompanionSelection) {
            defaults.set(data, forKey: Keys.mainCompanionSelection)
        } else {
            defaults.removeObject(forKey: Keys.mainCompanionSelection)
        }
        if let data = try? JSONEncoder().encode(watchCompanionSelection) {
            defaults.set(data, forKey: Keys.watchCompanionSelection)
        } else {
            defaults.removeObject(forKey: Keys.watchCompanionSelection)
        }

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
        defaults.set(autoPauseEnabled, forKey: Keys.autoPauseEnabled)
        if let data = try? JSONEncoder().encode(worldProgressSnapshot) {
            defaults.set(data, forKey: Keys.worldProgress)
        } else {
            defaults.removeObject(forKey: Keys.worldProgress)
        }
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

    private func makeSeededArchiveRun(from summary: RunSummary) -> CompletedRunRecord {
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

        return RunimalGameEngine.makeCompletedRunRecord(
            reward: reward,
            snapshot: snapshot,
            startedAt: startedAt,
            endedAt: endedAt,
            averageHeartRate: 152,
            route: [],
            source: "seeded-archive",
            id: "seeded-archive-run"
        )
    }
}
