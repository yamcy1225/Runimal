import RunimalCore
import SwiftUI

@MainActor
extension PhoneDashboardStore {
    var watchSelection: MainCompanionSelection? {
        progress.watchCompanionSelection ?? progress.mainCompanionSelection
    }

    var watchSelectionLabel: String {
        switch watchSelection?.kind {
        case .egg:
            return watchEgg?.title ?? "???"
        case .pet:
            return watchPet?.pet.displayName ?? featuredCompanion.pet.displayName
        case nil:
            return featuredCompanion.pet.displayName
        }
    }

    var watchSelectionDetail: String {
        switch watchSelection?.kind {
        case .egg:
            guard let watchEgg else { return "워치에 들고 나갈 알을 고르세요." }
            return watchEgg.readyToHatch
                ? "워치에서 바로 부화 상호작용이 가능합니다."
                : watchEgg.shell.hatchHint
        case .pet:
            return watchPet?.headline ?? featuredCompanion.headline
        case nil:
            return "워치에 들고 나갈 동행체를 고르세요."
        }
    }

    var watchAccentColor: Color {
        watchEgg?.shell.accentColor ?? watchPet?.pet.accentColor ?? mainAccentColor
    }

    var watchPet: PetCollectionEntry? {
        progress.watchPetSelection ?? progress.mainPetSelection
    }

    var watchEgg: EggInventoryEntry? {
        progress.watchEggSelection ?? progress.mainEggSelection
    }

    var watchMainCompanionContext: WatchMainCompanionContext {
        if let selection = watchSelection {
            switch selection.kind {
            case .egg:
                if let egg = eggInventory.first(where: { $0.id == selection.targetID }) {
                    return WatchMainCompanionContext(
                        selection: selection,
                        eggShell: egg.shell,
                        eggTitle: egg.title,
                        eggProgressRatio: egg.progressRatio,
                        eggReadyToHatch: egg.readyToHatch
                    )
                }
            case .pet:
                if let companion = collection.first(where: { $0.id == selection.targetID }) {
                    return WatchMainCompanionContext(
                        selection: selection,
                        pet: companion.pet,
                        petName: companion.pet.displayName,
                        petHeadline: companion.headline
                    )
                }

                if let companion = progress.ownedCompanions.first(where: { $0.id == selection.targetID }) {
                    return WatchMainCompanionContext(
                        selection: selection,
                        pet: companion.pet,
                        petName: companion.pet.displayName,
                        petHeadline: companion.headline
                    )
                }
            }
        }

        if let egg = watchEgg {
            return WatchMainCompanionContext(
                selection: MainCompanionSelection(kind: .egg, targetID: egg.id),
                eggShell: egg.shell,
                eggTitle: egg.title,
                eggProgressRatio: egg.progressRatio,
                eggReadyToHatch: egg.readyToHatch
            )
        }

        let companion = watchPet ?? featuredCompanion
        return WatchMainCompanionContext(
            selection: MainCompanionSelection(kind: .pet, targetID: companion.id),
            pet: companion.pet,
            petName: companion.pet.displayName,
            petHeadline: companion.headline
        )
    }

    func syncMainCompanionSelection() {
        connectivity.pushMainCompanionContext(watchMainCompanionContext)
    }
}
