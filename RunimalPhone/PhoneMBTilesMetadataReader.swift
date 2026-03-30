import Foundation
import SQLite3
import RunimalCore

struct PhoneMBTilesMetadata {
    let tileCount: Int?
    let minZoom: Int?
    let maxZoom: Int?
    let boundingBox: OfflineMapBoundingBox?
    let sourceLabel: String?
    let licenseLabel: String?
    let attributionText: String?

    static let empty = PhoneMBTilesMetadata(
        tileCount: nil,
        minZoom: nil,
        maxZoom: nil,
        boundingBox: nil,
        sourceLabel: nil,
        licenseLabel: nil,
        attributionText: nil
    )
}

enum PhoneMBTilesMetadataReader {
    static func read(from url: URL) throws -> PhoneMBTilesMetadata {
        var db: OpaquePointer?
        guard sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK, let db else {
            throw NSError(domain: "Runimal.MBTiles", code: 1, userInfo: [NSLocalizedDescriptionKey: "MBTiles를 열 수 없습니다."])
        }
        defer { sqlite3_close(db) }

        let zoomLevels = try readZoomLevels(db: db)
        let tileCount = try readTileCount(db: db)
        let metadata = try readMetadataMap(db: db)

        let bounds = metadata["bounds"].flatMap(parseBounds)
        let minZoom = metadata["minzoom"].flatMap(Int.init) ?? zoomLevels.minZoom
        let maxZoom = metadata["maxzoom"].flatMap(Int.init) ?? zoomLevels.maxZoom

        return PhoneMBTilesMetadata(
            tileCount: tileCount,
            minZoom: minZoom,
            maxZoom: maxZoom,
            boundingBox: bounds,
            sourceLabel: metadata["source"],
            licenseLabel: metadata["license"],
            attributionText: metadata["attribution"]
        )
    }

    private static func readTileCount(db: OpaquePointer) throws -> Int? {
        let query = "SELECT COUNT(*) FROM tiles;"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK, let statement else {
            return nil
        }
        defer { sqlite3_finalize(statement) }
        return sqlite3_step(statement) == SQLITE_ROW ? Int(sqlite3_column_int(statement, 0)) : nil
    }

    private static func readZoomLevels(db: OpaquePointer) throws -> (minZoom: Int?, maxZoom: Int?) {
        let query = "SELECT MIN(zoom_level), MAX(zoom_level) FROM tiles;"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK, let statement else {
            return (nil, nil)
        }
        defer { sqlite3_finalize(statement) }
        guard sqlite3_step(statement) == SQLITE_ROW else { return (nil, nil) }
        let minZoom = sqlite3_column_type(statement, 0) == SQLITE_NULL ? nil : Int(sqlite3_column_int(statement, 0))
        let maxZoom = sqlite3_column_type(statement, 1) == SQLITE_NULL ? nil : Int(sqlite3_column_int(statement, 1))
        return (minZoom, maxZoom)
    }

    private static func readMetadataMap(db: OpaquePointer) throws -> [String: String] {
        let query = "SELECT name, value FROM metadata;"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK, let statement else {
            return [:]
        }
        defer { sqlite3_finalize(statement) }

        var values: [String: String] = [:]
        while sqlite3_step(statement) == SQLITE_ROW {
            guard
                let namePointer = sqlite3_column_text(statement, 0),
                let valuePointer = sqlite3_column_text(statement, 1)
            else { continue }
            let key = String(cString: namePointer)
            let value = String(cString: valuePointer)
            values[key] = value
        }
        return values
    }

    private static func parseBounds(_ raw: String) -> OfflineMapBoundingBox? {
        let values = raw.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard values.count == 4 else { return nil }
        return OfflineMapBoundingBox(
            minLatitude: values[1],
            minLongitude: values[0],
            maxLatitude: values[3],
            maxLongitude: values[2]
        )
    }
}
