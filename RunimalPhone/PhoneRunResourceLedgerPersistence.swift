import Foundation
import RunimalRewardV2

struct PhoneRunResourceLedgerPersistence {
    private let fileManager: FileManager
    private let directoryURL: URL

    init(
        fileManager: FileManager = .default,
        directoryName: String = "RunimalPhone"
    ) {
        self.fileManager = fileManager
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        self.directoryURL = baseURL.appendingPathComponent(directoryName, isDirectory: true)
    }

    func loadLedger() -> RunimalRewardV2.RunResourceLedger {
        let fileURL = directoryURL.appendingPathComponent(RunimalRewardV2.RunResourceLedgerCodec.defaultFileName)
        guard let data = try? Data(contentsOf: fileURL),
              let snapshot = try? RunimalRewardV2.RunResourceLedgerCodec.decode(data) else {
            return RunimalRewardV2.RunResourceLedger()
        }
        return snapshot.ledger
    }

    func saveLedger(_ ledger: RunimalRewardV2.RunResourceLedger, savedAt: Date = Date()) throws {
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let snapshot = RunimalRewardV2.RunResourceLedgerSnapshot(savedAt: savedAt, ledger: ledger)
        let data = try RunimalRewardV2.RunResourceLedgerCodec.encode(snapshot)
        let fileURL = directoryURL.appendingPathComponent(RunimalRewardV2.RunResourceLedgerCodec.defaultFileName)
        try data.write(to: fileURL, options: [.atomic])
    }

    func hasPersistedData() -> Bool {
        let fileURL = directoryURL.appendingPathComponent(RunimalRewardV2.RunResourceLedgerCodec.defaultFileName)
        return fileManager.fileExists(atPath: fileURL.path)
    }
}
