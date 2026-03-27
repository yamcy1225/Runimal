import Foundation

enum RunimalPaths {
    static let repoRoot: URL = {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }()

    static let rotationCatalog = repoRoot.appendingPathComponent("RunimalPhone/Content/rotation.json")
    static let raidCatalog = repoRoot.appendingPathComponent("RunimalPhone/Content/raids.json")
    static let feedbackProfiles = repoRoot.appendingPathComponent("SharedUI/AssetCatalog/feedback-profiles.json")
    static let feedbackManifest = repoRoot.appendingPathComponent("SharedUI/AssetCatalog/feedback-manifest.txt")
}
