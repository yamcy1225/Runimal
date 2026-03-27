import Foundation

public enum RunimalCloudValidationEngine {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    public static func checklist(
        hasIdentity: Bool,
        mirrorStatus: String,
        lastMirroredAt: Date?
    ) -> [CloudValidationState] {
        [
            CloudValidationState(
                title: "Signed Identity",
                detail: hasIdentity ? "iCloud account token detected on this device." : "No iCloud account token is available in the current runtime.",
                success: hasIdentity
            ),
            CloudValidationState(
                title: "Mirror Status",
                detail: mirrorStatus,
                success: !mirrorStatus.localizedCaseInsensitiveContains("failed")
            ),
            CloudValidationState(
                title: "Last Snapshot",
                detail: lastMirroredAt.map { "Mirrored at \(formatter.string(from: $0))" } ?? "No mirrored snapshot yet.",
                success: lastMirroredAt != nil
            ),
        ]
    }
}
