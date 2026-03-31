import Foundation
import RunimalCore

@MainActor
final class PhoneWorldPackManifestManager {
    private enum StorageKey {
        static let enabledPackIDs = "runimal.phone.world.enabledPackIDs.v1"
    }

    private let defaults: UserDefaults
    private(set) var enabledPackIDs: [String] = []

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load(availablePackIDs: [String]) {
        let stored = defaults.stringArray(forKey: StorageKey.enabledPackIDs) ?? []
        let filtered = stored.filter { availablePackIDs.contains($0) }

        if filtered.isEmpty {
            enabledPackIDs = availablePackIDs
        } else {
            let newPackIDs = availablePackIDs.filter { filtered.contains($0) == false }
            enabledPackIDs = filtered + newPackIDs
        }

        defaults.set(enabledPackIDs, forKey: StorageKey.enabledPackIDs)
    }

    func setEnabledPackIDs(_ packIDs: [String], availablePackIDs: [String]) {
        let normalized = availablePackIDs.filter { packIDs.contains($0) }
        enabledPackIDs = normalized.isEmpty ? availablePackIDs : normalized
        defaults.set(enabledPackIDs, forKey: StorageKey.enabledPackIDs)
    }

    func toggle(packID: String, availablePackIDs: [String]) {
        guard availablePackIDs.contains(packID) else { return }

        var next = enabledPackIDs
        if next.contains(packID) {
            next.removeAll { $0 == packID }
        } else {
            next.append(packID)
        }

        setEnabledPackIDs(next, availablePackIDs: availablePackIDs)
    }
}

@MainActor
struct PhoneContentCatalog {
    let manifest: PhoneWorldPackManifestManager

    private struct RaidTemplate: Decodable {
        let id: String
        let title: String
        let detail: String
        let recommendedReward: String
        let claimThreshold: Int
    }

    init(manifest: PhoneWorldPackManifestManager) {
        self.manifest = manifest
    }

    func worldContentPack() -> WorldContentPack {
        WorldContentPackComposer.merge(worldContentPacks()) ?? DefaultWorldContent.pack
    }

    func worldContentPacks() -> [WorldContentPack] {
        let enabledIDs = Set(manifest.enabledPackIDs)
        let packs = DefaultWorldContent.sourcePacks.filter { enabledIDs.contains($0.contentPack.packID) }
        return packs.isEmpty ? DefaultWorldContent.sourcePacks : packs
    }

    func worldContentPackSummaries() -> [ContentPackSummary] {
        worldContentPacks().map(\.contentPack)
    }

    func companionWorldProfile(for pet: GeneratedPet) -> CompanionWorldProfile? {
        RunimalWorldContentEngine.profile(for: pet, pack: worldContentPack())
    }

    func runWorldProfile(for run: CompletedRunRecord) -> RunWorldProfile? {
        RunimalWorldContentEngine.profile(for: run, pack: worldContentPack())
    }

    func rotationEntries(for season: WeeklySeason) -> [ContentRotationEntry]? {
        guard let url = Bundle.main.url(forResource: "rotation", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([ContentRotationEntry].self, from: data) else {
            return nil
        }

        return entries.map { entry in
            ContentRotationEntry(
                id: "\(season.title)-\(entry.id)",
                title: entry.title == "Season Hunt" ? "\(season.title) Hunt" : entry.title,
                detail: entry.detail.replacingOccurrences(of: "이번 시즌", with: "\(season.title) 시즌"),
                reward: entry.reward
            )
        }
    }

    func mergeRaids(_ encounters: [RaidEncounter]) -> [RaidEncounter] {
        guard let url = Bundle.main.url(forResource: "raids", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let templates = try? JSONDecoder().decode([RaidTemplate].self, from: data) else {
            return encounters
        }

        let templateMap = Dictionary(uniqueKeysWithValues: templates.map { ($0.id, $0) })

        return encounters.map { encounter in
            guard let template = templateMap[encounter.id] else { return encounter }

            return RaidEncounter(
                id: encounter.id,
                title: template.title,
                detail: template.detail,
                readinessScore: encounter.readinessScore,
                recommendedReward: template.recommendedReward,
                claimThreshold: template.claimThreshold
            )
        }
    }
}
