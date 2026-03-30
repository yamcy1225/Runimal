import Foundation
import Observation
import RunimalCore

@MainActor
@Observable
final class WatchOfflineMapPackStorage {
    enum PackAvailabilityStatus: Equatable {
        case ready
        case missingManifest
        case invalidManifest
        case missingArchive
        case emptyArchive
    }

    var storedPackIDs: Set<String> = []

    private let fileManager = FileManager.default

    func reloadFromDisk() {
        let root = storageRootURL
        guard let children = try? fileManager.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            storedPackIDs = []
            return
        }

        storedPackIDs = Set(
            children.compactMap { url in
                guard availabilityStatus(forPackFolderURL: url) == .ready else { return nil }
                return url.lastPathComponent
            }
        )
    }

    func storeTransferredFile(tempURL: URL, packID: String, kind: String) {
        let packURL = storageRootURL.appendingPathComponent(packID, isDirectory: true)
        let destinationURL = packURL.appendingPathComponent(kind == "manifest" ? "manifest.json" : kind)

        do {
            try fileManager.createDirectory(at: packURL, withIntermediateDirectories: true)
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: tempURL, to: destinationURL)
        } catch {
            return
        }

        reloadFromDisk()
    }

    func tilesDatabaseURL(for packID: String) -> URL? {
        let packURL = storageRootURL.appendingPathComponent(packID, isDirectory: true)
        let manifestURL = packURL.appendingPathComponent("manifest.json")
        guard
            let manifestData = try? Data(contentsOf: manifestURL),
            let manifest = try? JSONDecoder().decode(OfflineMapPackManifest.self, from: manifestData),
            manifest.archiveFormat == .mbtiles,
            availabilityStatus(for: packID) == .ready
        else { return nil }

        let url = packURL.appendingPathComponent(manifest.tilesFilename)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    func pmtilesArchiveURL(for packID: String) -> URL? {
        let packURL = storageRootURL.appendingPathComponent(packID, isDirectory: true)
        let manifestURL = packURL.appendingPathComponent("manifest.json")
        guard
            let manifestData = try? Data(contentsOf: manifestURL),
            let manifest = try? JSONDecoder().decode(OfflineMapPackManifest.self, from: manifestData),
            manifest.archiveFormat == .pmtiles,
            availabilityStatus(for: packID) == .ready
        else { return nil }

        let url = packURL.appendingPathComponent(manifest.tilesFilename)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    func availabilityStatus(for packID: String) -> PackAvailabilityStatus {
        let packURL = storageRootURL.appendingPathComponent(packID, isDirectory: true)
        return availabilityStatus(forPackFolderURL: packURL)
    }

    private func availabilityStatus(forPackFolderURL packURL: URL) -> PackAvailabilityStatus {
        let manifestURL = packURL.appendingPathComponent("manifest.json")
        guard fileManager.fileExists(atPath: manifestURL.path) else { return .missingManifest }
        guard
            let manifestData = try? Data(contentsOf: manifestURL),
            let manifest = try? JSONDecoder().decode(OfflineMapPackManifest.self, from: manifestData)
        else { return .invalidManifest }

        let archiveURL = packURL.appendingPathComponent(manifest.tilesFilename)
        guard fileManager.fileExists(atPath: archiveURL.path) else { return .missingArchive }
        let fileSize = (try? archiveURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        guard fileSize > 0 else { return .emptyArchive }
        return .ready
    }

    private var storageRootURL: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return base.appendingPathComponent("OfflineMaps", isDirectory: true)
    }
}
