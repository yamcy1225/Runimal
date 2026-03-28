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
