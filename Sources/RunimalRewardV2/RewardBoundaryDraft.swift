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

public extension RunimalRewardV2 {
    enum RunResourceUpsertDisposition: String, Codable, Equatable, Sendable {
        case inserted
        case reusedExistingUnspent
        case preservedExistingSpent
    }

    struct RunResourceUpsertResult: Codable, Equatable, Sendable {
        public let resource: RunimalDomainV2.RunResource
        public let disposition: RunResourceUpsertDisposition

        public init(resource: RunimalDomainV2.RunResource, disposition: RunResourceUpsertDisposition) {
            self.resource = resource
            self.disposition = disposition
        }
    }

    /// Small, Codable resource ledger for v2's resource-first growth loop.
    ///
    /// The ledger is intentionally store-agnostic. Phone app wiring can persist it
    /// to JSON/SwiftData later, while SwiftPM tests already lock the important rule:
    /// duplicate sync must not duplicate resources or resurrect a spent resource.
    struct RunResourceLedger: Codable, Equatable, Sendable {
        public private(set) var resources: [RunimalDomainV2.RunResource]
        public private(set) var spendIntents: [SpendIntent]

        public init(
            resources: [RunimalDomainV2.RunResource] = [],
            spendIntents: [SpendIntent] = []
        ) {
            self.resources = resources
            self.spendIntents = spendIntents
        }

        public func resource(forArchiveID archiveID: UUID) -> RunimalDomainV2.RunResource? {
            resources.first { $0.archiveID == archiveID }
        }

        public func resource(forResourceID resourceID: UUID) -> RunimalDomainV2.RunResource? {
            resources.first { $0.id == resourceID }
        }

        @discardableResult
        public mutating func removeUnspentResources(forArchiveIDs archiveIDs: Set<UUID>) -> Int {
            guard !archiveIDs.isEmpty else { return 0 }
            let originalCount = resources.count
            resources.removeAll { resource in
                archiveIDs.contains(resource.archiveID) && resource.isSpent == false
            }
            return originalCount - resources.count
        }

        @discardableResult
        public mutating func upsert(_ resource: RunimalDomainV2.RunResource) -> RunResourceUpsertResult {
            guard let index = resources.firstIndex(where: { $0.archiveID == resource.archiveID }) else {
                resources.insert(resource, at: 0)
                return RunResourceUpsertResult(resource: resource, disposition: .inserted)
            }

            let existing = resources[index]
            if existing.isSpent {
                return RunResourceUpsertResult(resource: existing, disposition: .preservedExistingSpent)
            }

            let merged = RunimalDomainV2.RunResource(
                id: existing.id,
                archiveID: existing.archiveID,
                liveCompanionID: existing.liveCompanionID ?? resource.liveCompanionID,
                isSpent: false
            )
            resources[index] = merged
            return RunResourceUpsertResult(resource: merged, disposition: .reusedExistingUnspent)
        }

        @discardableResult
        public mutating func spend(_ intent: SpendIntent) -> SpendValidation {
            guard let index = resources.firstIndex(where: { $0.id == intent.runResourceID }) else {
                return .archiveMismatch
            }

            let resource = resources[index]
            let validation = ManualSpendPolicy.validate(resource: resource, intent: intent)
            guard validation == .allowed else { return validation }

            resources[index] = RunimalDomainV2.RunResource(
                id: resource.id,
                archiveID: resource.archiveID,
                liveCompanionID: resource.liveCompanionID,
                isSpent: true
            )
            spendIntents.append(intent)
            return .allowed
        }
    }
}

public extension RunimalRewardV2 {
    static var runResourceLedgerSchemaVersion: Int { 1 }

    struct RunResourceLedgerSnapshot: Codable, Equatable, Sendable {
        public let schemaVersion: Int
        public let savedAt: Date
        public let ledger: RunResourceLedger

        public init(
            schemaVersion: Int = RunimalRewardV2.runResourceLedgerSchemaVersion,
            savedAt: Date = Date(),
            ledger: RunResourceLedger
        ) {
            self.schemaVersion = schemaVersion
            self.savedAt = savedAt
            self.ledger = ledger
        }
    }

    enum RunResourceLedgerCodec {
        public static let defaultFileName = "run-resource-ledger-v2.json"

        public static func encode(_ snapshot: RunResourceLedgerSnapshot) throws -> Data {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            return try encoder.encode(snapshot)
        }

        public static func decode(_ data: Data) throws -> RunResourceLedgerSnapshot {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(RunResourceLedgerSnapshot.self, from: data)
        }
    }
}
