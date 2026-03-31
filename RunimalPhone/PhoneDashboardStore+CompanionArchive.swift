import RunimalCore

struct CompanionArchiveEntry: Identifiable {
    let companion: PetCollectionEntry
    let retired: Bool

    var id: String { companion.id }
}

@MainActor
extension PhoneDashboardStore {
    var companionArchive: [CompanionArchiveEntry] {
        progress.ownedCompanions.map { companion in
            let effectiveCompanion = RunimalCompanionGrowthEngine.effectiveCompanion(
                from: companion,
                growthRecord: progress.growthRecord(for: companion.id)
            )

            return CompanionArchiveEntry(
                companion: effectiveCompanion,
                retired: progress.retiredCompanionIDs.contains(companion.id)
            )
        }
    }

    var activeInventoryCompanionCount: Int {
        collection.count
    }

    var archivedCompanionCount: Int {
        companionArchive.filter(\.retired).count
    }

    func mutationForm(for companion: PetCollectionEntry) -> MutationFormSnapshot? {
        guard let growthRecord = progress.growthRecord(for: companion.id) else { return nil }

        let runs = progress.completedRuns
            .filter { growthRecord.assignedRunIDs.contains($0.id) }
            .sorted { $0.endedAt < $1.endedAt }

        guard runs.isEmpty == false else { return nil }
        return SpeciesMutationUnlockEngine.resolveForm(
            for: runs,
            preferredSpecies: companion.pet.species
        )?.snapshot
    }

    func mutationHistory(for companion: PetCollectionEntry) -> MutationHistorySnapshot? {
        guard let growthRecord = progress.growthRecord(for: companion.id) else { return nil }

        let runs = progress.completedRuns
            .filter { growthRecord.assignedRunIDs.contains($0.id) }
            .sorted { $0.endedAt < $1.endedAt }

        guard runs.isEmpty == false else { return nil }
        return SpeciesMutationHistoryEngine.history(
            for: runs,
            preferredSpecies: companion.pet.species
        )
    }

    func selectCompanionForWatch(_ companionID: String) {
        progress.selectWatchCompanion(id: companionID)
        syncMainCompanionSelection()
    }

    func selectEggForWatch(_ eggID: String) {
        progress.selectWatchEgg(id: eggID)
        syncMainCompanionSelection()
    }
}
