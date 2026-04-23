import Foundation

/// Draft manual-spend policy for v2. Calculation backend will initially remain in RunimalCore.
public enum RunimalRewardV2 {
    public enum SpendTarget: String, Codable, Sendable {
        case companion
        case eggForge
        case eggIncubation
    }

    public struct SpendIntent: Codable, Equatable, Identifiable, Sendable {
        public let id: UUID
        public let runResourceID: UUID
        public let target: SpendTarget
        public let targetID: String
        public let createdAt: Date

        public init(
            id: UUID = UUID(),
            runResourceID: UUID,
            target: SpendTarget,
            targetID: String,
            createdAt: Date = Date()
        ) {
            self.id = id
            self.runResourceID = runResourceID
            self.target = target
            self.targetID = targetID
            self.createdAt = createdAt
        }
    }
}
