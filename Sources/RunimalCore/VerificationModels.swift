import Foundation

public struct DeviceVerificationRecord: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let passed: Bool
    public let recordedAt: Date

    public init(id: String, title: String, passed: Bool, recordedAt: Date) {
        self.id = id
        self.title = title
        self.passed = passed
        self.recordedAt = recordedAt
    }
}

public struct MergeCandidate: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let label: String
    public let source: String
    public let type: String

    public init(id: String, label: String, source: String, type: String) {
        self.id = id
        self.label = label
        self.source = source
        self.type = type
    }
}

public struct RaidBranchReward: Codable, Equatable, Sendable {
    public let branchTitle: String
    public let extraEssence: Int
    public let extraSigils: Int
    public let extraOverdrive: Int

    public init(branchTitle: String, extraEssence: Int, extraSigils: Int, extraOverdrive: Int) {
        self.branchTitle = branchTitle
        self.extraEssence = extraEssence
        self.extraSigils = extraSigils
        self.extraOverdrive = extraOverdrive
    }
}
