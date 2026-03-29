import Foundation
import Observation
import RunimalCore

@MainActor
@Observable
final class PhoneOfflineMapPackManager {
    private enum Keys {
        static let packs = "runimal.phone.offlineMapPacks"
        static let selectedPackID = "runimal.phone.selectedOfflineMapPackID"
    }

    private let defaults: UserDefaults
    private let fileManager = FileManager.default
    var packs: [OfflineMapPackSummary] = []
    var selectedPackID: String?
    var importStatusLabel = "MBTiles 파일 대기"
    var lastImportError: String?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() {
        if let data = defaults.data(forKey: Keys.packs) {
            packs = (try? JSONDecoder().decode([OfflineMapPackSummary].self, from: data)) ?? []
        } else {
            packs = []
        }
        selectedPackID = defaults.string(forKey: Keys.selectedPackID)
        normalizeSelection()
    }

    func save() {
        if let data = try? JSONEncoder().encode(packs) {
            defaults.set(data, forKey: Keys.packs)
        } else {
            defaults.removeObject(forKey: Keys.packs)
        }

        if let selectedPackID {
            defaults.set(selectedPackID, forKey: Keys.selectedPackID)
        } else {
            defaults.removeObject(forKey: Keys.selectedPackID)
        }
    }

    func upsert(_ pack: OfflineMapPackSummary) {
        packs.removeAll { $0.id == pack.id }
        packs.insert(pack, at: 0)
        packs = Array(packs.prefix(12))
        if selectedPackID == nil {
            selectedPackID = pack.id
        }
        normalizeSelection()
        save()
    }

    func prepareLocalStorage(for pack: OfflineMapPackSummary) {
        let packFolder = storageRootURL.appendingPathComponent(pack.id, isDirectory: true)
        let manifestURL = packFolder.appendingPathComponent("manifest.json")
        let tilesURL = packFolder.appendingPathComponent("tiles.mbtiles")

        do {
            try fileManager.createDirectory(at: packFolder, withIntermediateDirectories: true)
            let storedPack = OfflineMapPackSummary(
                id: pack.id,
                title: pack.title,
                createdAt: pack.createdAt,
                boundingBox: pack.boundingBox,
                minZoom: pack.minZoom,
                maxZoom: pack.maxZoom,
                tileCount: pack.tileCount,
                byteCount: pack.byteCount,
                transferredToWatch: pack.transferredToWatch,
                localRelativePath: "OfflineMaps/\(pack.id)",
                manifestReady: true,
                tilesReady: false
            )
            if fileManager.fileExists(atPath: tilesURL.path) == false {
                fileManager.createFile(atPath: tilesURL.path, contents: Data())
            }
            let manifest = OfflineMapPackManifest(pack: storedPack)
            let manifestData = try JSONEncoder().encode(manifest)
            try manifestData.write(to: manifestURL, options: .atomic)
            upsert(storedPack)
        } catch {
            upsert(pack)
        }
    }

    func importMBTiles(from url: URL, into packID: String) throws {
        guard let pack = packs.first(where: { $0.id == packID }) else { return }

        let accessedSecurityScope = url.startAccessingSecurityScopedResource()
        defer {
            if accessedSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard let localRelativePath = pack.localRelativePath else { return }
        let packURL = applicationSupportBaseURL.appendingPathComponent(localRelativePath, isDirectory: true)
        let destinationURL = packURL.appendingPathComponent("tiles.mbtiles")

        try fileManager.createDirectory(at: packURL, withIntermediateDirectories: true)
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.copyItem(at: url, to: destinationURL)

        let parsedMetadata = (try? PhoneMBTilesMetadataReader.read(from: destinationURL)) ?? .empty
        let actualByteCount = (try? destinationURL.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init)
            ?? pack.byteCount

        let updatedPack = OfflineMapPackSummary(
            id: pack.id,
            title: pack.title,
            createdAt: pack.createdAt,
            boundingBox: parsedMetadata.boundingBox ?? pack.boundingBox,
            minZoom: parsedMetadata.minZoom ?? pack.minZoom,
            maxZoom: parsedMetadata.maxZoom ?? pack.maxZoom,
            tileCount: parsedMetadata.tileCount ?? pack.tileCount,
            byteCount: actualByteCount,
            transferredToWatch: false,
            localRelativePath: pack.localRelativePath,
            manifestReady: true,
            tilesReady: true
        )
        try writeManifest(for: updatedPack)
        upsert(updatedPack)
        importStatusLabel = "\(updatedPack.title) MBTiles 연결 완료 · Z\(updatedPack.minZoom)-\(updatedPack.maxZoom)"
        lastImportError = nil
    }

    func markImportFailed(_ message: String) {
        importStatusLabel = "MBTiles 가져오기 실패"
        lastImportError = message
    }

    func selectPack(id: String) {
        guard packs.contains(where: { $0.id == id }) else { return }
        selectedPackID = id
        save()
    }

    func renamePack(id: String, title: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedTitle.isEmpty == false else { return }

        packs = packs.map { pack in
            guard pack.id == id else { return pack }
            return OfflineMapPackSummary(
                id: pack.id,
                title: trimmedTitle,
                createdAt: pack.createdAt,
                boundingBox: pack.boundingBox,
                minZoom: pack.minZoom,
                maxZoom: pack.maxZoom,
                tileCount: pack.tileCount,
                byteCount: pack.byteCount,
                transferredToWatch: pack.transferredToWatch,
                localRelativePath: pack.localRelativePath,
                manifestReady: pack.manifestReady,
                tilesReady: pack.tilesReady
            )
        }
        if let renamedPack = packs.first(where: { $0.id == id }) {
            try? writeManifest(for: renamedPack)
        }
        save()
    }

    func deletePack(id: String) {
        guard let pack = packs.first(where: { $0.id == id }) else { return }

        if let localRelativePath = pack.localRelativePath {
            let packURL = applicationSupportBaseURL.appendingPathComponent(localRelativePath, isDirectory: true)
            try? fileManager.removeItem(at: packURL)
        }

        packs.removeAll { $0.id == id }
        normalizeSelection()
        save()
    }

    func payloadURLs(for packID: String) -> [URL] {
        guard let pack = packs.first(where: { $0.id == packID }),
              let localRelativePath = pack.localRelativePath else { return [] }

        let packURL = applicationSupportBaseURL.appendingPathComponent(localRelativePath, isDirectory: true)
        let manifestURL = packURL.appendingPathComponent("manifest.json")
        let tilesURL = packURL.appendingPathComponent("tiles.mbtiles")

        return [manifestURL, tilesURL].filter { fileManager.fileExists(atPath: $0.path) }
    }

    func markTransferredToWatch(ids: Set<String>) {
        guard !ids.isEmpty else { return }
        packs = packs.map { pack in
            guard ids.contains(pack.id), pack.transferredToWatch == false else { return pack }
            return OfflineMapPackSummary(
                id: pack.id,
                title: pack.title,
                createdAt: pack.createdAt,
                boundingBox: pack.boundingBox,
                minZoom: pack.minZoom,
                maxZoom: pack.maxZoom,
                tileCount: pack.tileCount,
                byteCount: pack.byteCount,
                transferredToWatch: true,
                localRelativePath: pack.localRelativePath,
                manifestReady: pack.manifestReady,
                tilesReady: pack.tilesReady
            )
        }
        normalizeSelection()
        save()
    }

    private var storageRootURL: URL {
        applicationSupportBaseURL.appendingPathComponent("OfflineMaps", isDirectory: true)
    }

    private var applicationSupportBaseURL: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
    }

    private func writeManifest(for pack: OfflineMapPackSummary) throws {
        guard let localRelativePath = pack.localRelativePath else { return }
        let packURL = applicationSupportBaseURL.appendingPathComponent(localRelativePath, isDirectory: true)
        try fileManager.createDirectory(at: packURL, withIntermediateDirectories: true)
        let manifestURL = packURL.appendingPathComponent("manifest.json")
        let manifest = OfflineMapPackManifest(pack: pack)
        let data = try JSONEncoder().encode(manifest)
        try data.write(to: manifestURL, options: .atomic)
    }

    private func normalizeSelection() {
        guard packs.isEmpty == false else {
            selectedPackID = nil
            return
        }

        if let selectedPackID, packs.contains(where: { $0.id == selectedPackID }) {
            return
        }

        selectedPackID = packs.first?.id
    }
}
