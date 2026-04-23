import Foundation
import RunimalDomainV2

/// External workout interoperability boundary.
public enum RunimalExportV2 {
    public enum ExternalWorkoutFormat: String, Codable, Sendable {
        case fit
        case json
        case healthKit
    }

    public struct ImportReceipt: Codable, Equatable, Identifiable, Sendable {
        public let id: UUID
        public let sourceFormat: ExternalWorkoutFormat
        public let sourceName: String
        public let canonicalArchiveID: UUID?
        public let createdAt: Date
        public let warning: String?

        public init(
            id: UUID = UUID(),
            sourceFormat: ExternalWorkoutFormat,
            sourceName: String,
            canonicalArchiveID: UUID? = nil,
            createdAt: Date = Date(),
            warning: String? = nil
        ) {
            self.id = id
            self.sourceFormat = sourceFormat
            self.sourceName = sourceName
            self.canonicalArchiveID = canonicalArchiveID
            self.createdAt = createdAt
            self.warning = warning
        }
    }

    public struct ExportRequest: Codable, Equatable, Identifiable, Sendable {
        public let id: UUID
        public let archiveID: UUID
        public let requestedFormat: ExternalWorkoutFormat
        public let createdAt: Date

        public init(
            id: UUID = UUID(),
            archiveID: UUID,
            requestedFormat: ExternalWorkoutFormat,
            createdAt: Date = Date()
        ) {
            self.id = id
            self.archiveID = archiveID
            self.requestedFormat = requestedFormat
            self.createdAt = createdAt
        }

        public init(archive: RunimalDomainV2.CompletedRunArchive, requestedFormat: ExternalWorkoutFormat, createdAt: Date = Date()) {
            self.init(archiveID: archive.id, requestedFormat: requestedFormat, createdAt: createdAt)
        }
    }
}
