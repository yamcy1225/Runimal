import Foundation
import RunimalCore

struct PhoneContentCatalog {
    private struct RaidTemplate: Decodable {
        let id: String
        let title: String
        let detail: String
        let recommendedReward: String
        let claimThreshold: Int
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
