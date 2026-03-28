import Foundation

public struct SanctuaryRewardEvent: Codable, Equatable, Identifiable, Sendable {
    public let date: Date
    public let essenceGained: Int
    public let itemLabel: String?
    public let logLine: String

    public var id: String {
        "\(date.timeIntervalSince1970)-\(essenceGained)"
    }

    public init(date: Date, essenceGained: Int, itemLabel: String?, logLine: String) {
        self.date = date
        self.essenceGained = essenceGained
        self.itemLabel = itemLabel
        self.logLine = logLine
    }
}
