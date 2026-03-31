import Foundation

public enum WorldContentPackLoader {
    private static var resourceBundle: Bundle {
        .module
    }

    public static func loadSeedPack() -> WorldContentPack? {
        load(resourceName: "runimal-world-content.seed", bundle: resourceBundle)
    }

    public static func load(resourceName: String, bundle: Bundle) -> WorldContentPack? {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }

        return try? JSONDecoder().decode(WorldContentPack.self, from: data)
    }

    public static func loadAllPacks() -> [WorldContentPack] {
        availablePackResourceNames().compactMap { load(resourceName: $0, bundle: resourceBundle) }
    }

    public static func loadAllPacks(in bundle: Bundle) -> [WorldContentPack] {
        availablePackResourceNames(in: bundle).compactMap { load(resourceName: $0, bundle: bundle) }
    }

    public static func availablePackResourceNames() -> [String] {
        availablePackResourceNames(in: resourceBundle)
    }

    public static func availablePackResourceNames(in bundle: Bundle) -> [String] {
        let urls = bundle.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? []
        return urls
            .map { $0.deletingPathExtension().lastPathComponent }
            .filter { $0.contains("world-content") }
            .sorted()
    }
}
