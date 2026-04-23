import Foundation

/// Draft external workout interoperability boundary.
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
}
