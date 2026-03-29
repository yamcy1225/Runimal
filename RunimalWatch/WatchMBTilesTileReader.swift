import Foundation
import Observation
import RunimalCore
import SQLite3
import UIKit
import CoreGraphics

@MainActor
@Observable
final class WatchMBTilesTileReader {
    var previewImage: UIImage?
    var statusLabel = "타일 대기"

    func loadPreviewTile(
        for pack: OfflineMapPackSummary?,
        storage: WatchOfflineMapPackStorage,
        centerPoint: RoutePoint?,
        zoomOverride: Int?
    ) {
        guard let pack else {
            previewImage = nil
            statusLabel = "팩 필요"
            return
        }

        guard let databaseURL = storage.tilesDatabaseURL(for: pack.id) else {
            previewImage = nil
            statusLabel = "타일 없음"
            return
        }

        guard let image = loadTileImage(
            from: databaseURL,
            pack: pack,
            centerPoint: centerPoint,
            zoomOverride: zoomOverride
        ) else {
            previewImage = nil
            statusLabel = "미리보기 없음"
            return
        }

        previewImage = image
        statusLabel = "3x3 타일 준비"
    }

    private func loadTileImage(
        from databaseURL: URL,
        pack: OfflineMapPackSummary,
        centerPoint: RoutePoint?,
        zoomOverride: Int?
    ) -> UIImage? {
        var database: OpaquePointer?
        guard sqlite3_open_v2(databaseURL.path, &database, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            if let database { sqlite3_close(database) }
            return nil
        }
        defer { sqlite3_close(database) }

        let fallbackLatitude = (pack.boundingBox.minLatitude + pack.boundingBox.maxLatitude) / 2
        let fallbackLongitude = (pack.boundingBox.minLongitude + pack.boundingBox.maxLongitude) / 2
        let centerLatitude = centerPoint?.latitude ?? fallbackLatitude
        let centerLongitude = centerPoint?.longitude ?? fallbackLongitude

        let preferredZoom = min(max(zoomOverride ?? inferredZoom(for: pack, centerPoint: centerPoint), pack.minZoom), pack.maxZoom)

        for zoom in stride(from: preferredZoom, through: pack.minZoom, by: -1) {
            let xyz = tileXY(latitude: centerLatitude, longitude: centerLongitude, zoom: zoom)

            if let image = queryTileMosaic(
                database: database,
                zoom: zoom,
                centerX: xyz.x,
                centerY: xyz.y
            ) {
                return image
            }
        }

        return nil
    }

    private func queryTileMosaic(
        database: OpaquePointer?,
        zoom: Int,
        centerX: Int,
        centerY: Int
    ) -> UIImage? {
        let tileSize = 256
        let mosaicWidth = tileSize * 3
        let mosaicHeight = tileSize * 3
        let worldTileCount = 1 << zoom
        var foundAnyTile = false
        let bytesPerRow = mosaicWidth * 4
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: mosaicWidth,
                height: mosaicHeight,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo
              ) else {
            return nil
        }

        context.interpolationQuality = .none
        context.setFillColor(UIColor(GameBoyPalette.lightest).cgColor)
        context.fill(CGRect(x: 0, y: 0, width: mosaicWidth, height: mosaicHeight))

        for rowOffset in -1...1 {
            for columnOffset in -1...1 {
                let x = wrappedTileX(centerX + columnOffset, worldTileCount: worldTileCount)
                let y = centerY + rowOffset
                guard y >= 0, y < worldTileCount else { continue }

                let tmsY = ((1 << zoom) - 1) - y
                guard let tileImage = querySingleTileImage(
                    database: database,
                    zoom: zoom,
                    column: x,
                    row: tmsY
                )?.cgImage else { continue }

                foundAnyTile = true
                let drawRect = CGRect(
                    x: CGFloat(columnOffset + 1) * CGFloat(tileSize),
                    y: CGFloat(rowOffset + 1) * CGFloat(tileSize),
                    width: CGFloat(tileSize),
                    height: CGFloat(tileSize)
                )
                context.draw(tileImage, in: drawRect)
            }
        }

        guard foundAnyTile,
              let cgImage = context.makeImage() else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    private func querySingleTileImage(
        database: OpaquePointer?,
        zoom: Int,
        column: Int,
        row: Int
    ) -> UIImage? {
        let sql = "SELECT tile_data FROM tiles WHERE zoom_level = ? AND tile_column = ? AND tile_row = ? LIMIT 1;"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            return nil
        }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_int(statement, 1, Int32(zoom))
        sqlite3_bind_int(statement, 2, Int32(column))
        sqlite3_bind_int(statement, 3, Int32(row))

        guard sqlite3_step(statement) == SQLITE_ROW,
              let bytes = sqlite3_column_blob(statement, 0) else { return nil }

        let count = Int(sqlite3_column_bytes(statement, 0))
        let data = Data(bytes: bytes, count: count)
        return UIImage(data: data)
    }

    private func wrappedTileX(_ x: Int, worldTileCount: Int) -> Int {
        let modulo = x % worldTileCount
        return modulo >= 0 ? modulo : modulo + worldTileCount
    }

    private func inferredZoom(for pack: OfflineMapPackSummary, centerPoint: RoutePoint?) -> Int {
        guard centerPoint != nil else { return pack.maxZoom }
        let zoomSpan = max(pack.maxZoom - pack.minZoom, 0)
        if zoomSpan == 0 { return pack.maxZoom }
        return pack.maxZoom - min(1, zoomSpan)
    }

    private func tileXY(latitude: Double, longitude: Double, zoom: Int) -> (x: Int, y: Int) {
        let lat = min(max(latitude, -85.05112878), 85.05112878)
        let lon = min(max(longitude, -180), 180)
        let scale = Double(1 << zoom)

        let x = Int(((lon + 180) / 360 * scale).rounded(.down))
        let latitudeRadians = lat * .pi / 180
        let mercator = log(tan(.pi / 4 + latitudeRadians / 2))
        let y = Int(((1 - mercator / .pi) / 2 * scale).rounded(.down))

        return (
            x: min(max(x, 0), Int(scale - 1)),
            y: min(max(y, 0), Int(scale - 1))
        )
    }
}
