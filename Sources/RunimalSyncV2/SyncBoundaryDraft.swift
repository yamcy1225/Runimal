import Foundation

/// Draft sync state model. Keep transport details outside this boundary.
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

    public struct ArchiveSyncEnvelope: Codable, Equatable, Identifiable, Sendable {
        public let id: UUID
        public let archiveID: UUID
        public let runID: UUID
        public let createdAt: Date
        public let state: QueueState
        public let retryCount: Int
        public let lastError: String?

        public init(
            id: UUID = UUID(),
            archiveID: UUID,
            runID: UUID,
            createdAt: Date = Date(),
            state: QueueState = .readyToTransfer,
            retryCount: Int = 0,
            lastError: String? = nil
        ) {
            self.id = id
            self.archiveID = archiveID
            self.runID = runID
            self.createdAt = createdAt
            self.state = state
            self.retryCount = retryCount
            self.lastError = lastError
        }
    }
}
