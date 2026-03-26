import Foundation
import Observation
import RunimalCore

@MainActor
@Observable
final class PhoneProgressStore {
    private enum Keys {
        static let journal = "runimal.phone.journal"
    }

    private let defaults: UserDefaults
    var journal: [RunJournalEntry] = []

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() {
        guard let data = defaults.data(forKey: Keys.journal) else {
            journal = []
            return
        }

        do {
            journal = try JSONDecoder().decode([RunJournalEntry].self, from: data)
        } catch {
            journal = []
        }
    }

    func seedIfNeeded(from summaries: [RunSummary]) {
        guard journal.isEmpty else { return }

        let seededEntries = summaries.enumerated().map { index, summary in
            let reward = RunimalGameEngine.evaluateReward(for: summary)
            let createdAt = Calendar.current.date(byAdding: .day, value: -(index + 1), to: Date()) ?? Date()

            return RunimalGameEngine.makeJournalEntry(
                reward: reward,
                distanceKm: summary.distanceKm,
                cadence: summary.cadence,
                createdAt: createdAt
            )
        }

        journal = seededEntries
        save()
    }

    func append(reward: RunRewardSummary, snapshot: LiveRunSnapshot?) {
        let distanceKm = (snapshot?.distanceMeters ?? 0) / 1000
        let cadence = snapshot?.cadence ?? reward.pet.stats.dexterity * 10 + 130
        let entry = RunimalGameEngine.makeJournalEntry(reward: reward, distanceKm: distanceKm, cadence: cadence)

        if let latest = journal.first,
           latest.reward == reward,
           abs(latest.createdAt.timeIntervalSince(entry.createdAt)) < 90 {
            return
        }

        journal.insert(entry, at: 0)
        journal = Array(journal.prefix(18))
        save()
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(journal)
            defaults.set(data, forKey: Keys.journal)
        } catch {
            defaults.removeObject(forKey: Keys.journal)
        }
    }
}
