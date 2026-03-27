import Foundation
import Observation
import RunimalCore

@MainActor
@Observable
final class PhoneCloudMirrorManager {
    private let snapshotKey = "runimal.cloud.snapshot"
    private let store = NSUbiquitousKeyValueStore.default

    var statusLabel = "Cloud idle"
    var lastMirroredAt: Date?
    var validationHeadline = "Cloud runtime not checked"
    var hasIdentity = false

    func restoreIfAvailable() -> RunimalProgressSnapshot? {
        guard let encoded = store.string(forKey: snapshotKey),
              let data = Data(base64Encoded: encoded),
              let snapshot = try? JSONDecoder().decode(RunimalProgressSnapshot.self, from: data) else {
            statusLabel = "Cloud empty"
            return nil
        }

        lastMirroredAt = snapshot.savedAt
        statusLabel = "Cloud restored"
        return snapshot
    }

    func mirror(snapshot: RunimalProgressSnapshot) {
        do {
            let data = try JSONEncoder().encode(snapshot)
            store.set(data.base64EncodedString(), forKey: snapshotKey)
            store.synchronize()
            lastMirroredAt = snapshot.savedAt
            statusLabel = "Cloud mirrored"
        } catch {
            statusLabel = "Cloud mirror failed"
        }
    }

    func validateRuntime() {
        hasIdentity = FileManager.default.ubiquityIdentityToken != nil
        let syncResult = store.synchronize()
        validationHeadline = hasIdentity
            ? "iCloud account detected · sync \(syncResult ? "ok" : "failed")"
            : "No iCloud identity token in current runtime"
    }
}
