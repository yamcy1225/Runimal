import Foundation
import RunimalCore

@MainActor
extension PhoneProgressStore {
    var mainPetSelection: PetCollectionEntry? {
        guard let selection = mainCompanionSelection, selection.kind == .pet else { return nil }
        return ownedCompanions.first(where: { $0.id == selection.targetID && !retiredCompanionIDs.contains($0.id) })
    }

    var mainEggSelection: EggInventoryEntry? {
        guard let selection = mainCompanionSelection, selection.kind == .egg else { return nil }
        return eggInventory.first(where: { $0.id == selection.targetID })
    }

    func activateEgg(id: String) {
        guard eggInventory.contains(where: { $0.id == id }) else { return }
        mainCompanionSelection = MainCompanionSelection(kind: .egg, targetID: id)
        saveSelectionState()
    }

    func eggOpportunity(for run: CompletedRunRecord) -> EggCreationOpportunity {
        RunimalEggEngine.opportunity(
            for: run,
            unlockedAchievementIDs: Set(unlockedEggAchievementIDs),
            collectionIsEmpty: ownedCompanions.filter { !retiredCompanionIDs.contains($0.id) }.isEmpty,
            eggInventoryIsEmpty: eggInventory.isEmpty,
            completedRunCount: completedRuns.count
        )
    }

    @discardableResult
    func forgeEgg(from run: CompletedRunRecord) -> EggInventoryEntry? {
        guard unassignedRuns(from: completedRuns).contains(where: { $0.id == run.id }) else { return nil }
        let opportunity = eggOpportunity(for: run)
        guard opportunity.eligible else { return nil }

        let shell = RunimalEggEngine.shell(for: run)

        let entry = EggInventoryEntry(
            id: "egg-\(run.id)",
            shell: shell,
            title: RunimalEggEngine.title(for: shell),
            createdAt: run.endedAt,
            sourceRunID: run.id,
            storedExperience: RunimalEggEngine.initialExperience(
                for: run,
                starterBoosted: opportunity.isFirstRecoveryRun
            ),
            hatchThreshold: RunimalEggEngine.hatchThreshold(
                for: shell,
                run: run,
                starterBoosted: opportunity.isFirstRecoveryRun
            ),
            incubationRunIDs: [],
            unlockedAchievementIDs: opportunity.unlockedAchievementIDs,
            starterBoosted: opportunity.isFirstRecoveryRun
        )

        unlockedEggAchievementIDs = Array(
            Set(unlockedEggAchievementIDs + opportunity.unlockedAchievementIDs)
        ).sorted()
        eggInventory.insert(entry, at: 0)
        if mainCompanionSelection == nil {
            mainCompanionSelection = MainCompanionSelection(kind: .egg, targetID: entry.id)
        }
        saveSelectionState()
        return entry
    }

    @discardableResult
    func incubateMainEgg(with run: CompletedRunRecord) -> EggInventoryEntry? {
        guard let egg = mainEggSelection else { return nil }
        guard unassignedRuns(from: completedRuns).contains(where: { $0.id == run.id }) else { return nil }
        let proposedExperience = RunimalEggEngine.incubationExperienceGain(for: run, egg: egg)
        let hatchLock = RunimalRewardPulseEngine.hatchLock(egg: egg, proposedExperience: proposedExperience)

        let updated = EggInventoryEntry(
            id: egg.id,
            shell: egg.shell,
            title: egg.title,
            createdAt: egg.createdAt,
            sourceRunID: egg.sourceRunID,
            storedExperience: egg.storedExperience + proposedExperience + hatchLock.bonusExperience,
            hatchThreshold: egg.hatchThreshold,
            incubationRunIDs: egg.incubationRunIDs + [run.id],
            unlockedAchievementIDs: egg.unlockedAchievementIDs,
            starterBoosted: egg.starterBoosted
        )

        eggInventory.removeAll(where: { $0.id == egg.id })
        eggInventory.insert(updated, at: 0)
        saveSelectionState()
        return updated
    }

    @discardableResult
    func hatchEgg(_ eggID: String) -> PetCollectionEntry? {
        guard let egg = eggInventory.first(where: { $0.id == eggID }), egg.readyToHatch else { return nil }
        let runIDs = [egg.sourceRunID] + egg.incubationRunIDs
        let contributingRuns = completedRuns.filter { runIDs.contains($0.id) }
        let pet = RunimalEggEngine.hatchPet(
            from: egg,
            using: contributingRuns,
            claimedRewardIDs: Set(claimedWeeklyRewards)
        )

        let companion = PetCollectionEntry(
            id: "hatched-\(egg.id)",
            pet: pet,
            level: 1,
            bond: 18,
            totalDistanceKm: contributingRuns.reduce(0) { $0 + ($1.distanceMeters / 1000) },
            headline: "숨겨진 알에서 깨어난 동행체"
        )

        ownedCompanions.insert(companion, at: 0)
        growthRecords.removeAll(where: { $0.companionID == companion.id })
        growthRecords.append(
            CompanionGrowthRecord(
                companionID: companion.id,
                totalExperience: RunimalEggEngine.starterGrowthSeed(for: egg),
                feedCount: 0,
                assignedRunIDs: runIDs,
                lastFedAt: egg.createdAt
            )
        )
        eggInventory.removeAll(where: { $0.id == eggID })
        activeCompanionID = companion.id
        mainCompanionSelection = MainCompanionSelection(kind: .pet, targetID: companion.id)
        saveSelectionState()
        return companion
    }

    private func saveSelectionState() {
        save()
    }
}
