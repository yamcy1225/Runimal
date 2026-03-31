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
    public let mutationBodyStage: Int?
    public let mutationEcologyStage: Int?
    public let mutationRhythmStage: Int?
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
        mutationBodyStage: Int? = nil,
        mutationEcologyStage: Int? = nil,
        mutationRhythmStage: Int? = nil,
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
        self.mutationBodyStage = mutationBodyStage
        self.mutationEcologyStage = mutationEcologyStage
        self.mutationRhythmStage = mutationRhythmStage
        self.eggShell = eggShell
        self.eggTitle = eggTitle
        self.eggProgressRatio = eggProgressRatio
        self.eggReadyToHatch = eggReadyToHatch
        self.updatedAt = updatedAt
    }

    public var displayName: String {
        switch selection.kind {
        case .pet:
            return petName ?? "동행체"
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
        case mutationBodyStage
        case mutationEcologyStage
        case mutationRhythmStage
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
        mutationBodyStage = try container.decodeIfPresent(Int.self, forKey: .mutationBodyStage)
        mutationEcologyStage = try container.decodeIfPresent(Int.self, forKey: .mutationEcologyStage)
        mutationRhythmStage = try container.decodeIfPresent(Int.self, forKey: .mutationRhythmStage)
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
        if let mutationBodyStage {
            payload["mutationBodyStage"] = mutationBodyStage
        }
        if let mutationEcologyStage {
            payload["mutationEcologyStage"] = mutationEcologyStage
        }
        if let mutationRhythmStage {
            payload["mutationRhythmStage"] = mutationRhythmStage
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
            if let petName {
                payload["watchSelected_petName"] = petName
            }
            if let petHeadline {
                payload["watchSelected_petHeadline"] = petHeadline
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
            mutationBodyStage: wcPayload["mutationBodyStage"] as? Int,
            mutationEcologyStage: wcPayload["mutationEcologyStage"] as? Int,
            mutationRhythmStage: wcPayload["mutationRhythmStage"] as? Int,
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
            self.init(
                selection: selection,
                petName: payload["watchSelected_petName"] as? String ?? payload["watchSelected_displayName"] as? String,
                petHeadline: payload["watchSelected_petHeadline"] as? String,
                detailText: payload["watchSelected_detailText"] as? String,
                mutationBodyStage: payload["watchSelected_mutationBodyStage"] as? Int,
                mutationEcologyStage: payload["watchSelected_mutationEcologyStage"] as? Int,
                mutationRhythmStage: payload["watchSelected_mutationRhythmStage"] as? Int,
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
