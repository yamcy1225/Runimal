import Foundation
import RunimalCore
import RunimalRewardV2

public extension RunimalPhoneAdapterV2 {
    struct IngestState: Equatable, Sendable {
        public var workoutArchives: [WorkoutSessionArchive]
        public var resourceLedger: RunimalRewardV2.RunResourceLedger

        public init(
            workoutArchives: [WorkoutSessionArchive] = [],
            resourceLedger: RunimalRewardV2.RunResourceLedger = .init()
        ) {
            self.workoutArchives = workoutArchives
            self.resourceLedger = resourceLedger
        }
    }

    enum ArchiveApplyDisposition: String, Codable, Equatable, Sendable {
        case inserted
        case replaced
    }

    struct AppliedIngest: Equatable, Sendable {
        public let state: IngestState
        public let archiveDisposition: ArchiveApplyDisposition
        public let resourceDisposition: RunimalRewardV2.RunResourceUpsertDisposition
        public let auditEvents: [AuditEvent]

        public init(
            state: IngestState,
            archiveDisposition: ArchiveApplyDisposition,
            resourceDisposition: RunimalRewardV2.RunResourceUpsertDisposition,
            auditEvents: [AuditEvent]
        ) {
            self.state = state
            self.archiveDisposition = archiveDisposition
            self.resourceDisposition = resourceDisposition
            self.auditEvents = auditEvents
        }
    }

    enum IngestApplication {
        public static func apply(_ plan: IngestPlan, to state: IngestState = .init()) -> AppliedIngest {
            var nextState = state
            let archiveDisposition: ArchiveApplyDisposition

            if let index = nextState.workoutArchives.firstIndex(where: { $0.runID == plan.archiveForPersistence.runID }) {
                nextState.workoutArchives[index] = plan.archiveForPersistence
                archiveDisposition = .replaced
            } else {
                nextState.workoutArchives.insert(plan.archiveForPersistence, at: 0)
                archiveDisposition = .inserted
            }

            let resourceResult = nextState.resourceLedger.upsert(plan.runResource)
            var auditEvents = plan.auditEvents
            auditEvents.append(AuditEvent(
                code: "phone-ingest-v2.apply-archive",
                message: "Applied archive with disposition \(archiveDisposition.rawValue)."
            ))
            auditEvents.append(AuditEvent(
                code: "phone-ingest-v2.apply-resource",
                message: "Applied run resource with disposition \(resourceResult.disposition.rawValue)."
            ))

            return AppliedIngest(
                state: nextState,
                archiveDisposition: archiveDisposition,
                resourceDisposition: resourceResult.disposition,
                auditEvents: auditEvents
            )
        }
    }
}

public extension RunimalPhoneAdapterV2 {
    enum PhoneStorageContract {
        public static let workoutArchivesFileName = "workout-archives.json"
        public static let resourceLedgerFileName = RunimalRewardV2.RunResourceLedgerCodec.defaultFileName
    }

    struct PersistenceDraft: Equatable, Sendable {
        public let workoutArchivesFileName: String
        public let resourceLedgerFileName: String
        public let workoutArchives: [WorkoutSessionArchive]
        public let resourceLedgerSnapshot: RunimalRewardV2.RunResourceLedgerSnapshot

        public init(
            workoutArchivesFileName: String = PhoneStorageContract.workoutArchivesFileName,
            resourceLedgerFileName: String = PhoneStorageContract.resourceLedgerFileName,
            workoutArchives: [WorkoutSessionArchive],
            resourceLedgerSnapshot: RunimalRewardV2.RunResourceLedgerSnapshot
        ) {
            self.workoutArchivesFileName = workoutArchivesFileName
            self.resourceLedgerFileName = resourceLedgerFileName
            self.workoutArchives = workoutArchives
            self.resourceLedgerSnapshot = resourceLedgerSnapshot
        }
    }
}

public extension RunimalPhoneAdapterV2.AppliedIngest {
    func persistenceDraft(savedAt: Date = Date()) -> RunimalPhoneAdapterV2.PersistenceDraft {
        RunimalPhoneAdapterV2.PersistenceDraft(
            workoutArchives: state.workoutArchives,
            resourceLedgerSnapshot: RunimalRewardV2.RunResourceLedgerSnapshot(
                savedAt: savedAt,
                ledger: state.resourceLedger
            )
        )
    }
}
