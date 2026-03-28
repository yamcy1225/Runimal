import Foundation
import RunimalCore

@MainActor
extension PhoneProgressStore {
    private static let sanctuaryDateKey = "runimal.phone.sanctuary.date"
    private static let sanctuaryEventKey = "runimal.phone.sanctuary.event"

    func evaluateSanctuaryRewardIfNeeded(today: Date = Date()) {
        let calendar = Calendar.current
        let defaults = UserDefaults.standard

        if let data = defaults.data(forKey: Self.sanctuaryEventKey),
           let event = try? JSONDecoder().decode(SanctuaryRewardEvent.self, from: data),
           calendar.isDate(event.date, inSameDayAs: today) {
            lastSanctuaryReward = event
            return
        }

        if let lastDate = defaults.object(forKey: Self.sanctuaryDateKey) as? Date,
           calendar.isDate(lastDate, inSameDayAs: today) {
            return
        }

        guard let reward = RunimalSanctuaryEngine.restDayReward(
            today: today,
            completedRuns: completedRuns,
            mainCompanion: mainPetSelection,
            buildState: mainPetSelection.flatMap { buildState(for: $0.id) }
        ) else {
            defaults.set(today, forKey: Self.sanctuaryDateKey)
            return
        }

        essenceBalance += reward.essenceGained
        lastSanctuaryReward = reward
        defaults.set(today, forKey: Self.sanctuaryDateKey)
        if let data = try? JSONEncoder().encode(reward) {
            defaults.set(data, forKey: Self.sanctuaryEventKey)
        }
        save()
    }
}
