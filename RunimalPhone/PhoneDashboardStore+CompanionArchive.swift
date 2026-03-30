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

    func selectCompanionForWatch(_ companionID: String) {
        progress.selectWatchCompanion(id: companionID)
        syncMainCompanionSelection()
    }

    func selectEggForWatch(_ eggID: String) {
        progress.selectWatchEgg(id: eggID)
        syncMainCompanionSelection()
    }
}
