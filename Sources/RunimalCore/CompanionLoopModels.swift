import Foundation

public enum MainCompanionKind: String, Codable, Sendable {
    case pet
    case egg
}

public enum EggShellType: String, Codable, CaseIterable, Sendable {
    case ember
    case gale
    case moss
    case dusk
    case stone
}

public struct MainCompanionSelection: Codable, Equatable, Identifiable, Sendable {
    public let kind: MainCompanionKind
    public let targetID: String

    public var id: String {
        "\(kind.rawValue)-\(targetID)"
    }

    public init(kind: MainCompanionKind, targetID: String) {
        self.kind = kind
        self.targetID = targetID
    }
}

public struct EggInventoryEntry: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let shell: EggShellType
    public let title: String
    public let createdAt: Date
    public let sourceRunID: String
    public let storedExperience: Int
    public let hatchThreshold: Int
    public let incubationRunIDs: [String]
    public let unlockedAchievementIDs: [String]
    public let starterBoosted: Bool

    public var progressRatio: Double {
        guard hatchThreshold > 0 else { return 1 }
        return min(Double(storedExperience) / Double(hatchThreshold), 1)
    }

    public var readyToHatch: Bool {
        storedExperience >= hatchThreshold
    }

    public init(
        id: String,
        shell: EggShellType,
        title: String,
        createdAt: Date,
        sourceRunID: String,
        storedExperience: Int,
        hatchThreshold: Int,
        incubationRunIDs: [String],
        unlockedAchievementIDs: [String],
        starterBoosted: Bool = false
    ) {
        self.id = id
        self.shell = shell
        self.title = title
        self.createdAt = createdAt
        self.sourceRunID = sourceRunID
        self.storedExperience = storedExperience
        self.hatchThreshold = hatchThreshold
        self.incubationRunIDs = incubationRunIDs
        self.unlockedAchievementIDs = unlockedAchievementIDs
        self.starterBoosted = starterBoosted
    }

    public var decodedName: String {
        title
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case shell
        case title
        case createdAt
        case sourceRunID
        case storedExperience
        case hatchThreshold
        case incubationRunIDs
        case unlockedAchievementIDs
        case starterBoosted
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        shell = try container.decodeIfPresent(EggShellType.self, forKey: .shell) ?? .gale
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "???"
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        sourceRunID = try container.decode(String.self, forKey: .sourceRunID)
        storedExperience = try container.decode(Int.self, forKey: .storedExperience)
        hatchThreshold = try container.decode(Int.self, forKey: .hatchThreshold)
        incubationRunIDs = try container.decodeIfPresent([String].self, forKey: .incubationRunIDs) ?? []
        unlockedAchievementIDs = try container.decodeIfPresent([String].self, forKey: .unlockedAchievementIDs) ?? []
        starterBoosted = try container.decodeIfPresent(Bool.self, forKey: .starterBoosted) ?? false
    }
}

public struct WatchMainCompanionContext: Codable, Equatable, Sendable {
    public let selection: MainCompanionSelection
    public let pet: GeneratedPet?
    public let petName: String?
    public let petHeadline: String?
    public let detailText: String?
    public let companionLevel: Int?
    public let companionStageLabel: String?
    public let growthStageIndex: Int?
    public let mutationBodyStage: Int?
    public let mutationEcologyStage: Int?
    public let mutationRhythmStage: Int?
    public let mutationBodyBranchID: String?
    public let mutationEcologyBranchID: String?
    public let mutationRhythmBranchID: String?
    public let eggShell: EggShellType?
    public let eggTitle: String?
    public let eggProgressRatio: Double?
    public let eggReadyToHatch: Bool
    public let updatedAt: Date

    public init(
        selection: MainCompanionSelection,
        pet: GeneratedPet? = nil,
        petName: String? = nil,
        petHeadline: String? = nil,
        detailText: String? = nil,
        companionLevel: Int? = nil,
        companionStageLabel: String? = nil,
        growthStageIndex: Int? = nil,
        mutationBodyStage: Int? = nil,
        mutationEcologyStage: Int? = nil,
        mutationRhythmStage: Int? = nil,
        mutationBodyBranchID: String? = nil,
        mutationEcologyBranchID: String? = nil,
        mutationRhythmBranchID: String? = nil,
        eggShell: EggShellType? = nil,
        eggTitle: String? = nil,
        eggProgressRatio: Double? = nil,
        eggReadyToHatch: Bool = false,
        updatedAt: Date = Date()
    ) {
        self.selection = selection
        self.pet = pet
        self.petName = petName
        self.petHeadline = petHeadline
        self.detailText = detailText
        self.companionLevel = companionLevel
        self.companionStageLabel = companionStageLabel
        self.growthStageIndex = growthStageIndex
        self.mutationBodyStage = mutationBodyStage
        self.mutationEcologyStage = mutationEcologyStage
        self.mutationRhythmStage = mutationRhythmStage
        self.mutationBodyBranchID = mutationBodyBranchID
        self.mutationEcologyBranchID = mutationEcologyBranchID
        self.mutationRhythmBranchID = mutationRhythmBranchID
        self.eggShell = eggShell
        self.eggTitle = eggTitle
        self.eggProgressRatio = eggProgressRatio
        self.eggReadyToHatch = eggReadyToHatch
        self.updatedAt = updatedAt
    }

    public var displayName: String {
        switch selection.kind {
        case .pet:
            return petName ?? "동행"
        case .egg:
            return eggTitle ?? "???"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case selection
        case pet
        case petName
        case petHeadline
        case detailText
        case companionLevel
        case companionStageLabel
        case growthStageIndex
        case mutationBodyStage
        case mutationEcologyStage
        case mutationRhythmStage
        case mutationBodyBranchID
        case mutationEcologyBranchID
        case mutationRhythmBranchID
        case eggShell
        case eggTitle
        case eggProgressRatio
        case eggReadyToHatch
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        selection = try container.decode(MainCompanionSelection.self, forKey: .selection)
        pet = try container.decodeIfPresent(GeneratedPet.self, forKey: .pet)
        petName = try container.decodeIfPresent(String.self, forKey: .petName)
        petHeadline = try container.decodeIfPresent(String.self, forKey: .petHeadline)
        detailText = try container.decodeIfPresent(String.self, forKey: .detailText)
        companionLevel = try container.decodeIfPresent(Int.self, forKey: .companionLevel)
        companionStageLabel = try container.decodeIfPresent(String.self, forKey: .companionStageLabel)
        growthStageIndex = try container.decodeIfPresent(Int.self, forKey: .growthStageIndex)
        mutationBodyStage = try container.decodeIfPresent(Int.self, forKey: .mutationBodyStage)
        mutationEcologyStage = try container.decodeIfPresent(Int.self, forKey: .mutationEcologyStage)
        mutationRhythmStage = try container.decodeIfPresent(Int.self, forKey: .mutationRhythmStage)
        mutationBodyBranchID = try container.decodeIfPresent(String.self, forKey: .mutationBodyBranchID)
        mutationEcologyBranchID = try container.decodeIfPresent(String.self, forKey: .mutationEcologyBranchID)
        mutationRhythmBranchID = try container.decodeIfPresent(String.self, forKey: .mutationRhythmBranchID)
        eggShell = try container.decodeIfPresent(EggShellType.self, forKey: .eggShell)
        eggTitle = try container.decodeIfPresent(String.self, forKey: .eggTitle)
        eggProgressRatio = try container.decodeIfPresent(Double.self, forKey: .eggProgressRatio)
        eggReadyToHatch = try container.decodeIfPresent(Bool.self, forKey: .eggReadyToHatch) ?? false
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? .distantPast
    }

    public var wcPayload: [String: Any] {
        var payload: [String: Any] = [
            "kind": selection.kind.rawValue,
            "targetID": selection.targetID,
            "updatedAt": updatedAt.timeIntervalSince1970,
            "eggReadyToHatch": eggReadyToHatch,
        ]

        if let pet {
            payload["petSpecies"] = pet.species.rawValue
            payload["petElement"] = pet.element.rawValue
            payload["petPalette"] = pet.palette
            if let rareVariant = pet.rareVariant {
                payload["petRareVariant"] = rareVariant.rawValue
            }
        }

        if let petName {
            payload["petName"] = petName
        }
        if let petHeadline {
            payload["petHeadline"] = petHeadline
        }
        if let detailText {
            payload["detailText"] = detailText
        }
        if let companionLevel {
            payload["companionLevel"] = companionLevel
        }
        if let companionStageLabel {
            payload["companionStageLabel"] = companionStageLabel
        }
        if let growthStageIndex {
            payload["growthStageIndex"] = growthStageIndex
        }
        if let mutationBodyStage {
            payload["mutationBodyStage"] = mutationBodyStage
        }
        if let mutationEcologyStage {
            payload["mutationEcologyStage"] = mutationEcologyStage
        }
        if let mutationRhythmStage {
            payload["mutationRhythmStage"] = mutationRhythmStage
        }
        if let mutationBodyBranchID {
            payload["mutationBodyBranchID"] = mutationBodyBranchID
        }
        if let mutationEcologyBranchID {
            payload["mutationEcologyBranchID"] = mutationEcologyBranchID
        }
        if let mutationRhythmBranchID {
            payload["mutationRhythmBranchID"] = mutationRhythmBranchID
        }
        if let eggShell {
            payload["eggShell"] = eggShell.rawValue
        }
        if let eggTitle {
            payload["eggTitle"] = eggTitle
        }
        if let eggProgressRatio {
            payload["eggProgressRatio"] = eggProgressRatio
        }

        return payload
    }

    public var flattenedWCPayload: [String: Any] {
        wcPayload.reduce(into: [String: Any]()) { partialResult, entry in
            partialResult["mainCompanion_\(entry.key)"] = entry.value
        }
    }

    public var watchSelectionTransportPayload: [String: Any] {
        var payload: [String: Any] = [
            "watchSelected_kind": selection.kind.rawValue,
            "watchSelected_targetID": selection.targetID,
            "watchSelected_updatedAt": updatedAt.timeIntervalSince1970,
            "watchSelected_displayName": displayName,
        ]

        switch selection.kind {
        case .pet:
            if let pet {
                payload["watchSelected_petSpecies"] = pet.species.rawValue
                payload["watchSelected_petElement"] = pet.element.rawValue
                payload["watchSelected_petPalette"] = pet.palette
                if let rareVariant = pet.rareVariant {
                    payload["watchSelected_petRareVariant"] = rareVariant.rawValue
                }
            }
            if let petName {
                payload["watchSelected_petName"] = petName
            }
            if let petHeadline {
                payload["watchSelected_petHeadline"] = petHeadline
            }
            if let companionLevel {
                payload["watchSelected_companionLevel"] = companionLevel
            }
            if let companionStageLabel {
                payload["watchSelected_companionStageLabel"] = companionStageLabel
            }
            if let growthStageIndex {
                payload["watchSelected_growthStageIndex"] = growthStageIndex
            }
            if let mutationBodyStage {
                payload["watchSelected_mutationBodyStage"] = mutationBodyStage
            }
            if let mutationEcologyStage {
                payload["watchSelected_mutationEcologyStage"] = mutationEcologyStage
            }
            if let mutationRhythmStage {
                payload["watchSelected_mutationRhythmStage"] = mutationRhythmStage
            }
            if let mutationBodyBranchID {
                payload["watchSelected_mutationBodyBranchID"] = mutationBodyBranchID
            }
            if let mutationEcologyBranchID {
                payload["watchSelected_mutationEcologyBranchID"] = mutationEcologyBranchID
            }
            if let mutationRhythmBranchID {
                payload["watchSelected_mutationRhythmBranchID"] = mutationRhythmBranchID
            }
        case .egg:
            if let eggTitle {
                payload["watchSelected_eggTitle"] = eggTitle
            }
            if let eggShell {
                payload["watchSelected_eggShell"] = eggShell.rawValue
            }
            if let eggProgressRatio {
                payload["watchSelected_eggProgressRatio"] = eggProgressRatio
            }
            payload["watchSelected_eggReadyToHatch"] = eggReadyToHatch
        }

        if let detailText {
            payload["watchSelected_detailText"] = detailText
        }

        return payload
    }

    public init?(wcPayload: [String: Any]) {
        guard let kindRaw = wcPayload["kind"] as? String,
              let kind = MainCompanionKind(rawValue: kindRaw),
              let targetID = wcPayload["targetID"] as? String else {
            return nil
        }

        let updatedAt = Date(timeIntervalSince1970: wcPayload["updatedAt"] as? Double ?? 0)
        let selection = MainCompanionSelection(kind: kind, targetID: targetID)

        var reconstructedPet: GeneratedPet?
        if let speciesRaw = wcPayload["petSpecies"] as? String,
           let elementRaw = wcPayload["petElement"] as? String,
           let palette = wcPayload["petPalette"] as? String,
           let species = PetSpecies(rawValue: speciesRaw),
           let element = PetElement(rawValue: elementRaw) {
            let rareVariant = (wcPayload["petRareVariant"] as? String).flatMap(RareVariant.init(rawValue:))
            reconstructedPet = GeneratedPet(
                species: species,
                element: element,
                palette: palette,
                rareVariant: rareVariant,
                explanation: [],
                stats: PetStats(vitality: 0, agility: 0, dexterity: 0, focus: 0, defense: 0)
            )
        }

        self.init(
            selection: selection,
            pet: reconstructedPet,
            petName: wcPayload["petName"] as? String,
            petHeadline: wcPayload["petHeadline"] as? String,
            detailText: wcPayload["detailText"] as? String,
            companionLevel: wcPayload["companionLevel"] as? Int,
            companionStageLabel: wcPayload["companionStageLabel"] as? String,
            growthStageIndex: wcPayload["growthStageIndex"] as? Int,
            mutationBodyStage: wcPayload["mutationBodyStage"] as? Int,
            mutationEcologyStage: wcPayload["mutationEcologyStage"] as? Int,
            mutationRhythmStage: wcPayload["mutationRhythmStage"] as? Int,
            mutationBodyBranchID: wcPayload["mutationBodyBranchID"] as? String,
            mutationEcologyBranchID: wcPayload["mutationEcologyBranchID"] as? String,
            mutationRhythmBranchID: wcPayload["mutationRhythmBranchID"] as? String,
            eggShell: (wcPayload["eggShell"] as? String).flatMap(EggShellType.init(rawValue:)),
            eggTitle: wcPayload["eggTitle"] as? String,
            eggProgressRatio: wcPayload["eggProgressRatio"] as? Double,
            eggReadyToHatch: wcPayload["eggReadyToHatch"] as? Bool ?? false,
            updatedAt: updatedAt
        )
    }

    public init?(flattenedWCPayload: [String: Any]) {
        let nestedPayload = flattenedWCPayload.reduce(into: [String: Any]()) { partialResult, entry in
            guard entry.key.hasPrefix("mainCompanion_") else { return }
            let key = String(entry.key.dropFirst("mainCompanion_".count))
            partialResult[key] = entry.value
        }

        guard nestedPayload.isEmpty == false else { return nil }
        self.init(wcPayload: nestedPayload)
    }

    public init?(watchSelectionTransportPayload payload: [String: Any]) {
        guard let kindRaw = payload["watchSelected_kind"] as? String,
              let kind = MainCompanionKind(rawValue: kindRaw),
              let targetID = payload["watchSelected_targetID"] as? String else {
            return nil
        }

        let updatedAt = Date(timeIntervalSince1970: payload["watchSelected_updatedAt"] as? Double ?? Date().timeIntervalSince1970)
        let selection = MainCompanionSelection(kind: kind, targetID: targetID)

        switch kind {
        case .pet:
            var reconstructedPet: GeneratedPet?
            if let speciesRaw = payload["watchSelected_petSpecies"] as? String,
               let elementRaw = payload["watchSelected_petElement"] as? String,
               let palette = payload["watchSelected_petPalette"] as? String,
               let species = PetSpecies(rawValue: speciesRaw),
               let element = PetElement(rawValue: elementRaw) {
                let rareVariant = (payload["watchSelected_petRareVariant"] as? String).flatMap(RareVariant.init(rawValue:))
                reconstructedPet = GeneratedPet(
                    species: species,
                    element: element,
                    palette: palette,
                    rareVariant: rareVariant,
                    explanation: [],
                    stats: PetStats(vitality: 0, agility: 0, dexterity: 0, focus: 0, defense: 0)
                )
            }
            self.init(
                selection: selection,
                pet: reconstructedPet,
                petName: payload["watchSelected_petName"] as? String ?? payload["watchSelected_displayName"] as? String,
                petHeadline: payload["watchSelected_petHeadline"] as? String,
                detailText: payload["watchSelected_detailText"] as? String,
                companionLevel: payload["watchSelected_companionLevel"] as? Int,
                companionStageLabel: payload["watchSelected_companionStageLabel"] as? String,
                growthStageIndex: payload["watchSelected_growthStageIndex"] as? Int,
                mutationBodyStage: payload["watchSelected_mutationBodyStage"] as? Int,
                mutationEcologyStage: payload["watchSelected_mutationEcologyStage"] as? Int,
                mutationRhythmStage: payload["watchSelected_mutationRhythmStage"] as? Int,
                mutationBodyBranchID: payload["watchSelected_mutationBodyBranchID"] as? String,
                mutationEcologyBranchID: payload["watchSelected_mutationEcologyBranchID"] as? String,
                mutationRhythmBranchID: payload["watchSelected_mutationRhythmBranchID"] as? String,
                updatedAt: updatedAt
            )
        case .egg:
            self.init(
                selection: selection,
                detailText: payload["watchSelected_detailText"] as? String,
                eggShell: (payload["watchSelected_eggShell"] as? String).flatMap(EggShellType.init(rawValue:)),
                eggTitle: payload["watchSelected_eggTitle"] as? String ?? payload["watchSelected_displayName"] as? String,
                eggProgressRatio: payload["watchSelected_eggProgressRatio"] as? Double,
                eggReadyToHatch: payload["watchSelected_eggReadyToHatch"] as? Bool ?? false,
                updatedAt: updatedAt
            )
        }
    }
}
