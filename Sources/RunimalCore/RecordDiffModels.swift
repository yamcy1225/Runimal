import Foundation

public struct RecordDiffChoice: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let type: String
    public let title: String
    public let localLabel: String
    public let cloudLabel: String

    public init(id: String, type: String, title: String, localLabel: String, cloudLabel: String) {
        self.id = id
        self.type = type
        self.title = title
        self.localLabel = localLabel
        self.cloudLabel = cloudLabel
    }
}

public struct SeasonalUnlock: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let unlocked: Bool

    public init(id: String, title: String, detail: String, unlocked: Bool) {
        self.id = id
        self.title = title
        self.detail = detail
        self.unlocked = unlocked
    }
}
