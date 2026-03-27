import Foundation
import Observation
import RunimalCore

@MainActor
@Observable
final class PhoneVaultSyncManager {
    var lastSyncedAt: Date?
    var statusLabel = "Vault idle"

    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func loadSnapshot() -> RunimalProgressSnapshot? {
        guard let url = snapshotURL() else {
            statusLabel = "Vault unavailable"
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let snapshot = try JSONDecoder().decode(RunimalProgressSnapshot.self, from: data)
            lastSyncedAt = snapshot.savedAt
            statusLabel = "Vault restored"
            return snapshot
        } catch {
            statusLabel = "Vault restore skipped"
            return nil
        }
    }

    func save(snapshot: RunimalProgressSnapshot) {
        guard let url = snapshotURL() else {
            statusLabel = "Vault unavailable"
            return
        }

        do {
            try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: url, options: [.atomic])
            lastSyncedAt = snapshot.savedAt
            statusLabel = "Vault synced"
        } catch {
            statusLabel = "Vault sync failed"
        }
    }

    private func snapshotURL() -> URL? {
        guard let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }

        return baseURL
            .appendingPathComponent("RunimalVault", isDirectory: true)
            .appendingPathComponent("progress-snapshot.json", isDirectory: false)
    }
}
