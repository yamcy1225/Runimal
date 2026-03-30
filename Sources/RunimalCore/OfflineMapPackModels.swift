import Foundation

public enum OfflineMapArchiveFormat: String, Codable, Equatable, Sendable {
    case mbtiles
    case pmtiles

    public var defaultFilename: String {
        switch self {
        case .mbtiles: return "tiles.mbtiles"
        case .pmtiles: return "tiles.pmtiles"
        }
    }
}

public struct OfflineMapBoundingBox: Codable, Equatable, Sendable {
    public let minLatitude: Double
    public let minLongitude: Double
    public let maxLatitude: Double
    public let maxLongitude: Double

    public init(minLatitude: Double, minLongitude: Double, maxLatitude: Double, maxLongitude: Double) {
        self.minLatitude = minLatitude
        self.minLongitude = minLongitude
        self.maxLatitude = maxLatitude
        self.maxLongitude = maxLongitude
    }
}

public struct OfflineMapPackSummary: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let createdAt: Date
    public let sourceLabel: String
    public let licenseLabel: String
    public let attributionText: String
    public let boundingBox: OfflineMapBoundingBox
    public let minZoom: Int
    public let maxZoom: Int
    public let tileCount: Int
    public let byteCount: Int64
    public let transferredToWatch: Bool
    public let localRelativePath: String?
    public let manifestReady: Bool
    public let tilesReady: Bool
    public let archiveFormat: OfflineMapArchiveFormat
    public let archiveFilename: String

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case createdAt
        case sourceLabel
        case licenseLabel
        case attributionText
        case boundingBox
        case minZoom
        case maxZoom
        case tileCount
        case byteCount
        case transferredToWatch
        case localRelativePath
        case manifestReady
        case tilesReady
        case archiveFormat
        case archiveFilename
    }

    public init(
        id: String = UUID().uuidString,
        title: String,
        createdAt: Date = Date(),
        sourceLabel: String = "OpenStreetMap (self-built)",
        licenseLabel: String = "ODbL",
        attributionText: String = "© OpenStreetMap contributors",
        boundingBox: OfflineMapBoundingBox,
        minZoom: Int,
        maxZoom: Int,
        tileCount: Int,
        byteCount: Int64,
        transferredToWatch: Bool = false,
        localRelativePath: String? = nil,
        manifestReady: Bool = false,
        tilesReady: Bool = false,
        archiveFormat: OfflineMapArchiveFormat = .mbtiles,
        archiveFilename: String? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.sourceLabel = sourceLabel
        self.licenseLabel = licenseLabel
        self.attributionText = attributionText
        self.boundingBox = boundingBox
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        self.tileCount = tileCount
        self.byteCount = byteCount
        self.transferredToWatch = transferredToWatch
        self.localRelativePath = localRelativePath
        self.manifestReady = manifestReady
        self.tilesReady = tilesReady
        self.archiveFormat = archiveFormat
        self.archiveFilename = archiveFilename ?? archiveFormat.defaultFilename
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        sourceLabel = try container.decodeIfPresent(String.self, forKey: .sourceLabel) ?? "OpenStreetMap (self-built)"
        licenseLabel = try container.decodeIfPresent(String.self, forKey: .licenseLabel) ?? "ODbL"
        attributionText = try container.decodeIfPresent(String.self, forKey: .attributionText) ?? "© OpenStreetMap contributors"
        boundingBox = try container.decode(OfflineMapBoundingBox.self, forKey: .boundingBox)
        minZoom = try container.decode(Int.self, forKey: .minZoom)
        maxZoom = try container.decode(Int.self, forKey: .maxZoom)
        tileCount = try container.decode(Int.self, forKey: .tileCount)
        byteCount = try container.decode(Int64.self, forKey: .byteCount)
        transferredToWatch = try container.decode(Bool.self, forKey: .transferredToWatch)
        localRelativePath = try container.decodeIfPresent(String.self, forKey: .localRelativePath)
        manifestReady = try container.decodeIfPresent(Bool.self, forKey: .manifestReady) ?? false
        tilesReady = try container.decodeIfPresent(Bool.self, forKey: .tilesReady) ?? false
        archiveFormat = try container.decodeIfPresent(OfflineMapArchiveFormat.self, forKey: .archiveFormat) ?? .mbtiles
        archiveFilename = try container.decodeIfPresent(String.self, forKey: .archiveFilename) ?? archiveFormat.defaultFilename
    }
}

public struct OfflineMapPackManifest: Codable, Equatable, Sendable {
    public let version: Int
    public let pack: OfflineMapPackSummary
    public let archiveFormat: OfflineMapArchiveFormat
    public let tilesFilename: String
    public let createdAt: Date

    public init(
        version: Int = 1,
        pack: OfflineMapPackSummary,
        archiveFormat: OfflineMapArchiveFormat? = nil,
        tilesFilename: String? = nil,
        createdAt: Date = Date()
    ) {
        self.version = version
        self.pack = pack
        self.archiveFormat = archiveFormat ?? pack.archiveFormat
        self.tilesFilename = tilesFilename ?? pack.archiveFilename
        self.createdAt = createdAt
    }
}
