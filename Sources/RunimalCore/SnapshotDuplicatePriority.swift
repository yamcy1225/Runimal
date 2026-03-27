import Foundation

public enum SnapshotDuplicatePriority: String, Codable, CaseIterable, Sendable {
    case localWins = "local-wins"
    case newestWins = "newest-wins"
    case cloudWins = "cloud-wins"
}
