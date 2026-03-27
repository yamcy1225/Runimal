import Foundation

public struct CloudRehearsalStep: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let ready: Bool

    public init(id: String, title: String, detail: String, ready: Bool) {
        self.id = id
        self.title = title
        self.detail = detail
        self.ready = ready
    }
}

public struct SnapshotConflictDiffEntry: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let label: String
    public let localValue: String
    public let cloudValue: String

    public init(id: String, label: String, localValue: String, cloudValue: String) {
        self.id = id
        self.label = label
        self.localValue = localValue
        self.cloudValue = cloudValue
    }
}

public struct RaidBossPattern: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let emphasis: String

    public init(id: String, title: String, detail: String, emphasis: String) {
        self.id = id
        self.title = title
        self.detail = detail
        self.emphasis = emphasis
    }
}

public struct RaidTurnResult: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let score: Int

    public init(id: String, title: String, detail: String, score: Int) {
        self.id = id
        self.title = title
        self.detail = detail
        self.score = score
    }
}
