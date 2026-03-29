import Foundation
import Observation

@MainActor
@Observable
final class WatchOfflineMapPackStorage {
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
                let manifestURL = url.appendingPathComponent("manifest.json")
                let tilesURL = url.appendingPathComponent("tiles.mbtiles")
                guard fileManager.fileExists(atPath: manifestURL.path),
                      fileManager.fileExists(atPath: tilesURL.path) else { return nil }
                return url.lastPathComponent
            }
        )
    }

    func storeTransferredFile(tempURL: URL, packID: String, kind: String) {
        let packURL = storageRootURL.appendingPathComponent(packID, isDirectory: true)
        let destinationURL = packURL.appendingPathComponent(kind == "manifest" ? "manifest.json" : "tiles.mbtiles")

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
        let url = storageRootURL
            .appendingPathComponent(packID, isDirectory: true)
            .appendingPathComponent("tiles.mbtiles")
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    private var storageRootURL: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return base.appendingPathComponent("OfflineMaps", isDirectory: true)
    }
}
