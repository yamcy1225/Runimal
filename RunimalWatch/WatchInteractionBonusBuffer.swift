import Foundation

enum WatchCompanionInteractionStyle: String, Codable, Sendable {
    case tap
    case bond
}

enum WatchInteractionAwardSource: String, Codable, Sendable {
    case home
    case running
}

struct WatchInteractionAwardFeedback: Equatable, Sendable {
    let source: WatchInteractionAwardSource
    let awardedXP: Int
    let totalXP: Int
    let cap: Int

    var bubbleLabel: String {
        "+\(awardedXP) XP"
    }

    var summaryLabel: String {
        switch source {
        case .home:
            return "다음 러닝 +\(totalXP)"
        case .running:
            return "교감 +\(totalXP)/\(cap)"
        }
    }
}

struct WatchInteractionBonusBuffer: Codable, Equatable, Sendable {
    static let pendingHomeCap = 2
    static let inRunCap = 6
    static let combinedCap = 8
    static let homeCooldown: TimeInterval = 8
    static let runCooldown: TimeInterval = 5

    var pendingHomeXP: Int
    var inRunXP: Int
    var lastHomeAwardAt: Date?
    var lastRunAwardAt: Date?

    init(
        pendingHomeXP: Int = 0,
        inRunXP: Int = 0,
        lastHomeAwardAt: Date? = nil,
        lastRunAwardAt: Date? = nil
    ) {
        self.pendingHomeXP = min(max(pendingHomeXP, 0), Self.pendingHomeCap)
        self.inRunXP = min(max(inRunXP, 0), Self.inRunCap)
        self.lastHomeAwardAt = lastHomeAwardAt
        self.lastRunAwardAt = lastRunAwardAt
    }

    var totalXP: Int {
        min(pendingHomeXP + inRunXP, Self.combinedCap)
    }

    var pendingHomeLabel: String? {
        pendingHomeXP > 0 ? "+\(pendingHomeXP)" : nil
    }

    var runCounterLabel: String? {
        inRunXP > 0 ? "+\(inRunXP)/\(Self.inRunCap)" : nil
    }

    func canAward(source: WatchInteractionAwardSource, at date: Date) -> Bool {
        switch source {
        case .home:
            guard pendingHomeXP < Self.pendingHomeCap, totalXP < Self.combinedCap else { return false }
            guard let lastHomeAwardAt else { return true }
            return date.timeIntervalSince(lastHomeAwardAt) >= Self.homeCooldown
        case .running:
            guard inRunXP < Self.inRunCap, totalXP < Self.combinedCap else { return false }
            guard let lastRunAwardAt else { return true }
            return date.timeIntervalSince(lastRunAwardAt) >= Self.runCooldown
        }
    }

    mutating func applyAward(_ awardedXP: Int, source: WatchInteractionAwardSource, at date: Date) -> WatchInteractionAwardFeedback? {
        guard awardedXP > 0 else { return nil }

        switch source {
        case .home:
            let remaining = min(Self.pendingHomeCap - pendingHomeXP, Self.combinedCap - totalXP)
            let applied = min(awardedXP, remaining)
            guard applied > 0 else { return nil }
            pendingHomeXP += applied
            lastHomeAwardAt = date
            return WatchInteractionAwardFeedback(
                source: source,
                awardedXP: applied,
                totalXP: pendingHomeXP,
                cap: Self.pendingHomeCap
            )
        case .running:
            let remaining = min(Self.inRunCap - inRunXP, Self.combinedCap - totalXP)
            let applied = min(awardedXP, remaining)
            guard applied > 0 else { return nil }
            inRunXP += applied
            lastRunAwardAt = date
            return WatchInteractionAwardFeedback(
                source: source,
                awardedXP: applied,
                totalXP: inRunXP,
                cap: Self.inRunCap
            )
        }
    }

    mutating func prepareForRun() {
        inRunXP = 0
        lastRunAwardAt = nil
    }

    mutating func consumeForCompletedRun() -> (homeXP: Int, runXP: Int, totalXP: Int) {
        let homeXP = min(pendingHomeXP, Self.pendingHomeCap)
        let runXP = min(inRunXP, Self.inRunCap)
        let totalXP = min(homeXP + runXP, Self.combinedCap)
        pendingHomeXP = 0
        inRunXP = 0
        lastRunAwardAt = nil
        return (homeXP, runXP, totalXP)
    }

    mutating func resetForCapture(pendingHomeXP: Int, inRunXP: Int) {
        self.pendingHomeXP = min(max(pendingHomeXP, 0), Self.pendingHomeCap)
        self.inRunXP = min(max(inRunXP, 0), Self.inRunCap)
        lastHomeAwardAt = nil
        lastRunAwardAt = nil
    }
}
