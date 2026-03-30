import CoreGraphics
import Foundation
import Observation
import RunimalCore
import UIKit
import zlib

@MainActor
@Observable
final class WatchPMTilesTileReader {
    var previewImage: UIImage?
    var statusLabel = "PMTiles 대기"
    private var lastPreviewKey: String?

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

        guard pack.archiveFormat == .pmtiles else {
            previewImage = nil
            statusLabel = "PMTiles 아님"
            return
        }

        guard let archiveURL = storage.pmtilesArchiveURL(for: pack.id) else {
            if previewImage == nil {
                previewImage = placeholderPreviewImage(label: "PACK")
            }
            statusLabel = "PMTiles 전송 필요"
            lastPreviewKey = nil
            return
        }

        let previewKey = previewKey(for: pack, archiveURL: archiveURL, centerPoint: centerPoint, zoomOverride: zoomOverride)
        if lastPreviewKey == previewKey, previewImage != nil {
            return
        }

        switch loadTileImage(
            from: archiveURL,
            pack: pack,
            centerPoint: centerPoint,
            zoomOverride: zoomOverride
        ) {
        case .success(let image):
            previewImage = image
            statusLabel = "PMTiles 프리뷰 준비"
            lastPreviewKey = previewKey
        case .failure(let label):
            if previewImage == nil {
                previewImage = placeholderPreviewImage(label: "PM")
            }
            statusLabel = label
            lastPreviewKey = previewKey
        }
    }

    private func previewKey(
        for pack: OfflineMapPackSummary,
        archiveURL: URL,
        centerPoint: RoutePoint?,
        zoomOverride: Int?
    ) -> String {
        let fallbackLatitude = (pack.boundingBox.minLatitude + pack.boundingBox.maxLatitude) / 2
        let fallbackLongitude = (pack.boundingBox.minLongitude + pack.boundingBox.maxLongitude) / 2
        let centerLatitude = centerPoint?.latitude ?? fallbackLatitude
        let centerLongitude = centerPoint?.longitude ?? fallbackLongitude
        let zoom = min(max(zoomOverride ?? inferredZoom(for: pack, centerPoint: centerPoint), pack.minZoom), pack.maxZoom)
        let xyz = tileXY(latitude: centerLatitude, longitude: centerLongitude, zoom: zoom)
        return "\(archiveURL.lastPathComponent)-\(pack.id)-\(zoom)-\(xyz.x)-\(xyz.y)"
    }

    private func loadTileImage(
        from archiveURL: URL,
        pack: OfflineMapPackSummary,
        centerPoint: RoutePoint?,
        zoomOverride: Int?
    ) -> PMTilesPreviewLoadResult {
        guard
            let archive = try? PMTilesArchive(url: archiveURL),
            let header = try? archive.readHeader()
        else {
            return .failure("헤더 오류")
        }

        guard header.tileType.isRaster else {
            return .failure("벡터 PMTiles 미지원")
        }

        let fallbackLatitude = (pack.boundingBox.minLatitude + pack.boundingBox.maxLatitude) / 2
        let fallbackLongitude = (pack.boundingBox.minLongitude + pack.boundingBox.maxLongitude) / 2
        let centerLatitude = centerPoint?.latitude ?? fallbackLatitude
        let centerLongitude = centerPoint?.longitude ?? fallbackLongitude
        let preferredZoom = min(
            max(zoomOverride ?? inferredZoom(for: pack, centerPoint: centerPoint), pack.minZoom),
            pack.maxZoom
        )

        for zoom in stride(from: preferredZoom, through: max(pack.minZoom, Int(header.minZoom)), by: -1) {
            let xyz = tileXY(latitude: centerLatitude, longitude: centerLongitude, zoom: zoom)
            if let image = queryTileMosaic(
                archive: archive,
                header: header,
                zoom: zoom,
                centerX: xyz.x,
                centerY: xyz.y
            ) {
                return .success(image)
            }
        }

        return .failure("현재 줌 타일 없음")
    }

    private func queryTileMosaic(
        archive: PMTilesArchive,
        header: PMTilesHeader,
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

                guard let tileData = try? archive.readTile(header: header, zoom: zoom, x: x, y: y),
                      let tileImage = UIImage(data: tileData)?.cgImage else { continue }

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

        guard foundAnyTile, let cgImage = context.makeImage() else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private func placeholderPreviewImage(label: String) -> UIImage? {
        let size = 192
        let bytesPerRow = size * 4
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: size,
                height: size,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo
              ) else {
            return nil
        }

        context.setFillColor(UIColor(GameBoyPalette.lightest).cgColor)
        context.fill(CGRect(x: 0, y: 0, width: size, height: size))

        context.setStrokeColor(UIColor(GameBoyPalette.mediumLight).cgColor)
        context.setLineWidth(2)
        stride(from: 32, to: size, by: 32).forEach { offset in
            context.move(to: CGPoint(x: offset, y: 0))
            context.addLine(to: CGPoint(x: offset, y: size))
            context.move(to: CGPoint(x: 0, y: offset))
            context.addLine(to: CGPoint(x: size, y: offset))
        }
        context.strokePath()

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 28, weight: .black),
            .foregroundColor: UIColor(GameBoyPalette.mediumDark),
            .paragraphStyle: paragraph,
        ]
        let textRect = CGRect(x: 0, y: CGFloat(size / 2 - 18), width: CGFloat(size), height: 36)
        UIGraphicsPushContext(context)
        NSAttributedString(string: label, attributes: attributes).draw(in: textRect)
        UIGraphicsPopContext()

        guard let cgImage = context.makeImage() else { return nil }
        return UIImage(cgImage: cgImage)
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

private struct PMTilesHeader {
    let rootDirectoryOffset: UInt64
    let rootDirectoryLength: UInt64
    let leafDirectoryOffset: UInt64
    let tileDataOffset: UInt64
    let internalCompression: UInt8
    let tileCompression: UInt8
    let tileType: PMTilesTileType
    let minZoom: UInt8
    let maxZoom: UInt8
}

private struct PMTilesEntry {
    let tileID: Int
    let offset: UInt64
    let length: UInt64
    let runLength: Int
}

private enum PMTilesCompression: UInt8 {
    case unknown = 0
    case none = 1
    case gzip = 2
}

private enum PMTilesTileType: UInt8 {
    case unknown = 0
    case mvt = 1
    case png = 2
    case jpeg = 3
    case webp = 4
    case avif = 5

    var isRaster: Bool {
        switch self {
        case .png, .jpeg, .webp, .avif:
            return true
        default:
            return false
        }
    }
}

private enum PMTilesPreviewLoadResult {
    case success(UIImage)
    case failure(String)
}

private final class PMTilesArchive {
    private let handle: FileHandle

    init(url: URL) throws {
        handle = try FileHandle(forReadingFrom: url)
    }

    deinit {
        try? handle.close()
    }

    func readHeader() throws -> PMTilesHeader {
        let data = try read(offset: 0, length: 127)
        guard data.count >= 127, String(data: data.prefix(7), encoding: .utf8) == "PMTiles" else {
            throw PMTilesError.invalidHeader
        }

        let version = data[7]
        guard version == 3 else { throw PMTilesError.unsupportedVersion(version) }

        return PMTilesHeader(
            rootDirectoryOffset: data.uint64LE(at: 8),
            rootDirectoryLength: data.uint64LE(at: 16),
            leafDirectoryOffset: data.uint64LE(at: 40),
            tileDataOffset: data.uint64LE(at: 56),
            internalCompression: data[97],
            tileCompression: data[98],
            tileType: PMTilesTileType(rawValue: data[99]) ?? .unknown,
            minZoom: data[100],
            maxZoom: data[101]
        )
    }

    func readTile(header: PMTilesHeader, zoom: Int, x: Int, y: Int) throws -> Data? {
        guard zoom >= Int(header.minZoom), zoom <= Int(header.maxZoom) else { return nil }

        let tileID = zxyToTileID(z: zoom, x: x, y: y)
        var directoryOffset = header.rootDirectoryOffset
        var directoryLength = header.rootDirectoryLength

        for _ in 0...3 {
            let directory = try readDirectory(
                offset: directoryOffset,
                length: directoryLength,
                compression: header.internalCompression
            )
            guard let entry = findTile(directory, tileID: tileID) else { return nil }

            if entry.runLength > 0 {
                let tileOffset = header.tileDataOffset + entry.offset
                let tileData = try read(offset: tileOffset, length: Int(entry.length))
                return try decompress(tileData, compression: header.tileCompression)
            }

            directoryOffset = header.leafDirectoryOffset + entry.offset
            directoryLength = entry.length
        }

        throw PMTilesError.maximumDepthExceeded
    }

    private func readDirectory(offset: UInt64, length: UInt64, compression: UInt8) throws -> [PMTilesEntry] {
        let rawData = try read(offset: offset, length: Int(length))
        let data = try decompress(rawData, compression: compression)
        return try deserializeDirectory(data)
    }

    private func read(offset: UInt64, length: Int) throws -> Data {
        try handle.seek(toOffset: offset)
        guard let data = try handle.read(upToCount: length), data.count == length else {
            throw PMTilesError.readFailed
        }
        return data
    }

    private func decompress(_ data: Data, compression: UInt8) throws -> Data {
        switch PMTilesCompression(rawValue: compression) ?? .unknown {
        case .none:
            return data
        case .gzip:
            return try data.gunzipped()
        case .unknown:
            throw PMTilesError.unsupportedCompression(compression)
        }
    }

    private func deserializeDirectory(_ data: Data) throws -> [PMTilesEntry] {
        var cursor = 0
        let count = try readVarint(from: data, cursor: &cursor)
        var entries: [PMTilesEntry] = []
        entries.reserveCapacity(count)

        var lastTileID = 0
        for _ in 0..<count {
            let delta = try readVarint(from: data, cursor: &cursor)
            lastTileID += delta
            entries.append(PMTilesEntry(tileID: lastTileID, offset: 0, length: 0, runLength: 1))
        }

        for index in entries.indices {
            let runLength = try readVarint(from: data, cursor: &cursor)
            entries[index] = PMTilesEntry(
                tileID: entries[index].tileID,
                offset: entries[index].offset,
                length: entries[index].length,
                runLength: runLength
            )
        }

        for index in entries.indices {
            let length = try readVarint(from: data, cursor: &cursor)
            entries[index] = PMTilesEntry(
                tileID: entries[index].tileID,
                offset: entries[index].offset,
                length: UInt64(length),
                runLength: entries[index].runLength
            )
        }

        for index in entries.indices {
            let rawOffset = try readVarint(from: data, cursor: &cursor)
            let offset: UInt64
            if index > 0, rawOffset == 0 {
                offset = entries[index - 1].offset + entries[index - 1].length
            } else {
                offset = UInt64(rawOffset - 1)
            }

            entries[index] = PMTilesEntry(
                tileID: entries[index].tileID,
                offset: offset,
                length: entries[index].length,
                runLength: entries[index].runLength
            )
        }

        return entries
    }

    private func findTile(_ entries: [PMTilesEntry], tileID: Int) -> PMTilesEntry? {
        var lower = 0
        var upper = entries.count - 1

        while lower <= upper {
            let middle = (lower + upper) >> 1
            let comparison = tileID - entries[middle].tileID
            if comparison > 0 {
                lower = middle + 1
            } else if comparison < 0 {
                upper = middle - 1
            } else {
                return entries[middle]
            }
        }

        if upper >= 0 {
            let candidate = entries[upper]
            if candidate.runLength == 0 { return candidate }
            if tileID - candidate.tileID < candidate.runLength { return candidate }
        }

        return nil
    }

    private func readVarint(from data: Data, cursor: inout Int) throws -> Int {
        var shift = 0
        var result = 0

        while cursor < data.count {
            let byte = Int(data[cursor])
            cursor += 1
            result |= (byte & 0x7f) << shift
            if (byte & 0x80) == 0 { return result }
            shift += 7
            if shift > 63 { throw PMTilesError.invalidVarint }
        }

        throw PMTilesError.invalidVarint
    }

    private func zxyToTileID(z: Int, x: Int, y: Int) -> Int {
        let accBase = ((1 << z) * (1 << z) - 1) / 3
        var accumulator = accBase
        var bit = z - 1
        var tileX = x
        var tileY = y
        var scale = 1 << max(bit, 0)
        while scale > 0 {
            let rx = tileX & scale
            let ry = tileY & scale
            accumulator += ((3 * rx) ^ ry) * (1 << max(bit, 0))
            let rotated = rotate(scale, tileX, tileY, rx, ry)
            tileX = rotated.x
            tileY = rotated.y
            bit -= 1
            scale >>= 1
        }

        return accumulator
    }

    private func rotate(_ n: Int, _ x: Int, _ y: Int, _ rx: Int, _ ry: Int) -> (x: Int, y: Int) {
        guard ry == 0 else { return (x, y) }
        if rx != 0 {
            return (n - 1 - y, n - 1 - x)
        }
        return (y, x)
    }
}

private enum PMTilesError: Error {
    case invalidHeader
    case unsupportedVersion(UInt8)
    case unsupportedCompression(UInt8)
    case invalidVarint
    case maximumDepthExceeded
    case readFailed
}

private extension Data {
    func uint64LE(at offset: Int) -> UInt64 {
        let range = offset..<(offset + 8)
        return subdata(in: range).withUnsafeBytes { pointer in
            pointer.load(as: UInt64.self).littleEndian
        }
    }

    func gunzipped() throws -> Data {
        guard isEmpty == false else { return Data() }

        let chunkSize = 64 * 1024
        var stream = z_stream()
        var status: Int32
        status = inflateInit2_(&stream, MAX_WBITS + 16, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        guard status == Z_OK else { throw PMTilesError.readFailed }
        defer { inflateEnd(&stream) }

        return try withUnsafeBytes { inputPointer in
            guard let baseAddress = inputPointer.baseAddress?.assumingMemoryBound(to: Bytef.self) else {
                throw PMTilesError.readFailed
            }

            var output = Data()
            stream.next_in = UnsafeMutablePointer<Bytef>(mutating: baseAddress)
            stream.avail_in = uInt(count)

            repeat {
                var buffer = [UInt8](repeating: 0, count: chunkSize)
                status = buffer.withUnsafeMutableBytes { outputPointer in
                    stream.next_out = outputPointer.baseAddress?.assumingMemoryBound(to: Bytef.self)
                    stream.avail_out = uInt(chunkSize)
                    return inflate(&stream, Z_NO_FLUSH)
                }

                let produced = chunkSize - Int(stream.avail_out)
                if produced > 0 {
                    output.append(buffer, count: produced)
                }
            } while status == Z_OK

            guard status == Z_STREAM_END else { throw PMTilesError.readFailed }
            return output
        }
    }
}
