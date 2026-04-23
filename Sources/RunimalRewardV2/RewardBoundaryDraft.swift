import Foundation
import RunimalDomainV2

/// Manual-spend policy for v2. Calculation backends initially remain in RunimalCore.
public enum RunimalRewardV2 {
    public enum SpendTarget: String, Codable, Sendable {
        case companion
        case eggForge
        case eggIncubation
    }

    public enum SpendValidation: Equatable, Sendable {
        case allowed
        case alreadySpent
        case archiveMismatch
    }

    public struct SpendIntent: Codable, Equatable, Identifiable, Sendable {
        public let id: UUID
        public let runResourceID: UUID
        public let archiveID: UUID
        public let target: SpendTarget
        public let targetID: String
        public let createdAt: Date

        public init(
            id: UUID = UUID(),
            runResourceID: UUID,
            archiveID: UUID,
            target: SpendTarget,
            targetID: String,
            createdAt: Date = Date()
        ) {
            self.id = id
            self.runResourceID = runResourceID
            self.archiveID = archiveID
            self.target = target
            self.targetID = targetID
            self.createdAt = createdAt
        }
    }

    public enum ManualSpendPolicy {
        public static func validate(
            resource: RunimalDomainV2.RunResource,
            intent: SpendIntent
        ) -> SpendValidation {
            guard !resource.isSpent else { return .alreadySpent }
            guard resource.archiveID == intent.archiveID else { return .archiveMismatch }
            return .allowed
        }
    }
}
