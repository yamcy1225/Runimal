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
    struct SpendRequest: Equatable, Sendable {
        public let archiveID: UUID
        public let target: RunimalRewardV2.SpendTarget
        public let targetID: String
        public let createdAt: Date
        public let intentID: UUID

        public init(
            archiveID: UUID,
            target: RunimalRewardV2.SpendTarget,
            targetID: String,
            createdAt: Date = Date(),
            intentID: UUID = UUID()
        ) {
            self.archiveID = archiveID
            self.target = target
            self.targetID = targetID
            self.createdAt = createdAt
            self.intentID = intentID
        }
    }

    struct SpendState: Equatable, Sendable {
        public var resourceLedger: RunimalRewardV2.RunResourceLedger

        public init(resourceLedger: RunimalRewardV2.RunResourceLedger = .init()) {
            self.resourceLedger = resourceLedger
        }
    }

    struct AppliedSpend: Equatable, Sendable {
        public let state: SpendState
        public let validation: RunimalRewardV2.SpendValidation
        public let intent: RunimalRewardV2.SpendIntent?
        public let auditEvents: [AuditEvent]

        public init(
            state: SpendState,
            validation: RunimalRewardV2.SpendValidation,
            intent: RunimalRewardV2.SpendIntent?,
            auditEvents: [AuditEvent]
        ) {
            self.state = state
            self.validation = validation
            self.intent = intent
            self.auditEvents = auditEvents
        }
    }

    enum SpendApplication {
        public static func apply(
            _ request: SpendRequest,
            to state: SpendState
        ) -> AppliedSpend {
            guard let resource = state.resourceLedger.resource(forArchiveID: request.archiveID) else {
                return AppliedSpend(
                    state: state,
                    validation: .missingResource,
                    intent: nil,
                    auditEvents: [
                        AuditEvent(
                            code: "phone-spend-v2.missing-resource",
                            message: "No run resource exists for archive \(request.archiveID.uuidString)."
                        ),
                    ]
                )
            }

            let intent = RunimalRewardV2.SpendIntent(
                id: request.intentID,
                runResourceID: resource.id,
                archiveID: request.archiveID,
                target: request.target,
                targetID: request.targetID,
                createdAt: request.createdAt
            )
            var nextState = state
            let validation = nextState.resourceLedger.spend(intent)

            return AppliedSpend(
                state: nextState,
                validation: validation,
                intent: validation == .allowed ? intent : nil,
                auditEvents: [
                    AuditEvent(
                        code: "phone-spend-v2.\(validation.auditCodeSuffix)",
                        message: "Spend request for archive \(request.archiveID.uuidString) resolved as \(validation.auditCodeSuffix)."
                    ),
                ]
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

private extension RunimalRewardV2.SpendValidation {
    var auditCodeSuffix: String {
        switch self {
        case .allowed:
            return "allowed"
        case .missingResource:
            return "missing-resource"
        case .alreadySpent:
            return "already-spent"
        case .archiveMismatch:
            return "archive-mismatch"
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
