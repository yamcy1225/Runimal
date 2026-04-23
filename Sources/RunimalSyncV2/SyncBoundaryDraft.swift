import Foundation
import RunimalDomainV2

/// V2 sync state model. Transport details such as WatchConnectivity stay outside this boundary.
public enum RunimalSyncV2 {
    public enum QueueState: String, Codable, Sendable {
        case pendingLocalArchive
        case readyToTransfer
        case transferring
        case waitingForAcknowledgement
        case acknowledged
        case retryableFailure
        case terminalFailure
    }

    public enum PayloadKind: String, Codable, Sendable {
        case completedRunArchive
        case archivePackage
        case auditEvent
    }

    public struct SyncEnvelope: Codable, Equatable, Identifiable, Sendable {
        public let id: UUID
        public let archiveID: UUID
        public let runID: UUID
        public let payloadKind: PayloadKind
        public let createdAt: Date
        public let sourceDeviceID: String
        public let destinationHint: String?
        public let state: QueueState
        public let retryCount: Int
        public let lastError: String?

        public init(
            id: UUID = UUID(),
            archiveID: UUID,
            runID: UUID,
            payloadKind: PayloadKind = .completedRunArchive,
            createdAt: Date = Date(),
            sourceDeviceID: String,
            destinationHint: String? = nil,
            state: QueueState = .readyToTransfer,
            retryCount: Int = 0,
            lastError: String? = nil
        ) {
            self.id = id
            self.archiveID = archiveID
            self.runID = runID
            self.payloadKind = payloadKind
            self.createdAt = createdAt
            self.sourceDeviceID = sourceDeviceID
            self.destinationHint = destinationHint
            self.state = state
            self.retryCount = max(0, retryCount)
            self.lastError = lastError
        }

        public init(
            archive: RunimalDomainV2.CompletedRunArchive,
            sourceDeviceID: String,
            createdAt: Date = Date()
        ) {
            self.init(
                archiveID: archive.id,
                runID: archive.runID,
                createdAt: createdAt,
                sourceDeviceID: sourceDeviceID
            )
        }

        public func transitioning(to nextState: QueueState, error: String? = nil) -> Self {
            SyncEnvelope(
                id: id,
                archiveID: archiveID,
                runID: runID,
                payloadKind: payloadKind,
                createdAt: createdAt,
                sourceDeviceID: sourceDeviceID,
                destinationHint: destinationHint,
                state: nextState,
                retryCount: nextState == .retryableFailure ? retryCount + 1 : retryCount,
                lastError: error
            )
        }
    }

    public typealias ArchiveSyncEnvelope = SyncEnvelope

    public struct SyncQueueItem: Codable, Equatable, Identifiable, Sendable {
        public let id: UUID
        public let envelope: SyncEnvelope
        public let localArchiveURL: URL?
        public let queuedAt: Date

        public init(id: UUID = UUID(), envelope: SyncEnvelope, localArchiveURL: URL? = nil, queuedAt: Date = Date()) {
            self.id = id
            self.envelope = envelope
            self.localArchiveURL = localArchiveURL
            self.queuedAt = queuedAt
        }
    }

    public struct SyncAuditEvent: Codable, Equatable, Identifiable, Sendable {
        public let id: UUID
        public let envelopeID: UUID
        public let state: QueueState
        public let message: String
        public let createdAt: Date

        public init(id: UUID = UUID(), envelopeID: UUID, state: QueueState, message: String, createdAt: Date = Date()) {
            self.id = id
            self.envelopeID = envelopeID
            self.state = state
            self.message = message
            self.createdAt = createdAt
        }
    }
}
