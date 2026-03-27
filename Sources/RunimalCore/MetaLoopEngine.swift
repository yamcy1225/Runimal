import Foundation

public extension RunimalGameEngine {
    static func weeklyBoard(
        from completedRuns: [CompletedRunRecord],
        journal: [RunJournalEntry],
        codex: [VariantCodexEntry],
        referenceDate: Date = Date()
    ) -> WeeklyBoard {
        let calendar = Calendar.current
        let season = seasonalTheme(for: referenceDate)
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: referenceDate)
        let weekStart = weekInterval?.start ?? referenceDate
        let weekEnd = weekInterval?.end ?? referenceDate

        let weeklyRuns = completedRuns.filter {
            $0.endedAt >= weekStart && $0.endedAt < weekEnd
        }
        let weeklyJournal = journal.filter {
            $0.createdAt >= weekStart && $0.createdAt < weekEnd
        }

        let totalDistanceKm = weeklyRuns.reduce(0) { $0 + ($1.distanceMeters / 1000) }
        let runCount = weeklyRuns.count
        let streakDays = consecutiveRunDays(from: completedRuns, calendar: calendar, referenceDate: referenceDate)
        let discoveredVariants = codex.filter(\.discovered).count

        let missions = [
            makeMission(
                id: "weekly-runs",
                title: "Field Cycle",
                detail: "이번 주 러닝 3회",
                progress: Double(runCount),
                target: 3
            ),
            makeMission(
                id: "weekly-distance",
                title: "Long Arc",
                detail: "이번 주 누적 18km",
                progress: totalDistanceKm,
                target: 18
            ),
            makeMission(
                id: "weekly-variants",
                title: "Rare Study",
                detail: "희귀 변이 3종 발견",
                progress: Double(discoveredVariants),
                target: 3
            ),
            makeMission(
                id: "weekly-growth",
                title: "Growth Feed",
                detail: "성장 로그 4회 누적",
                progress: Double(weeklyJournal.count),
                target: 4
            ),
        ]

        let completedCount = missions.filter(\.completed).count
        let headline: String
        let rewards = [
            WeeklyReward(
                id: "weekly-badge",
                title: "Field Badge",
                detail: "미션 1개 달성 시 주간 배지 확보",
                unlockRequirement: 1
            ),
            WeeklyReward(
                id: "weekly-core-cache",
                title: "Rare Core Cache",
                detail: "미션 2개 달성 시 희귀 코어 보급",
                unlockRequirement: 2
            ),
            WeeklyReward(
                id: "weekly-evo-boost",
                title: "Evolution Boost",
                detail: "미션 4개 달성 시 진화 부스트 해금",
                unlockRequirement: 4
            ),
        ]

        switch completedCount {
        case 4:
            headline = "이번 주 루프가 완성됐습니다. 다음 희귀 변이 연구 구간으로 넘어갈 수 있습니다."
        case 2...3:
            headline = "주간 루프가 안정권에 들어왔습니다. 한 번만 더 뛰면 진화 효율이 크게 오릅니다."
        default:
            headline = "이번 주 보드는 아직 비어 있습니다. 첫 러닝으로 펫 리듬을 다시 깨우는 단계입니다."
        }

        return WeeklyBoard(
            season: season,
            weekLabel: weeklyLabel(start: weekStart, end: weekEnd),
            headline: headline,
            totalDistanceKm: totalDistanceKm,
            runCount: runCount,
            streakDays: streakDays,
            discoveredVariants: discoveredVariants,
            completedMissionCount: completedCount,
            missions: missions,
            rewards: rewards
        )
    }

    private static func seasonalTheme(for date: Date) -> WeeklySeason {
        let month = Calendar.current.component(.month, from: date)

        switch month {
        case 3...5:
            return WeeklySeason(
                title: "Verdant Loop",
                subtitle: "안정 루프와 장거리 리듬을 밀어주는 봄 시즌",
                bonus: "Leaf / Zen Bloom 트랙의 연구 가치가 상승합니다."
            )
        case 6...8:
            return WeeklySeason(
                title: "Ember Circuit",
                subtitle: "고케이던스와 빠른 템포를 밀어주는 여름 시즌",
                bonus: "Flame / Tempo Surge 트랙의 목표 효율이 높아집니다."
            )
        case 9...11:
            return WeeklySeason(
                title: "Crag Harvest",
                subtitle: "언덕과 누적 거리 루프를 밀어주는 가을 시즌",
                bonus: "Earth / Summit Heart 계열의 성장 보상이 커집니다."
            )
        default:
            return WeeklySeason(
                title: "Lunar Drift",
                subtitle: "야간 러닝과 희귀 변이 연구를 밀어주는 겨울 시즌",
                bonus: "Lunar / Eclipse Mark 계열의 희귀 창이 자주 열립니다."
            )
        }
    }

    private static func makeMission(
        id: String,
        title: String,
        detail: String,
        progress: Double,
        target: Double
    ) -> WeeklyMission {
        let ratio = min(max(progress / target, 0), 1)
        let usesIntegerLabel = target.rounded() == target && progress.rounded() == progress
        let progressLabel: String

        if usesIntegerLabel {
            progressLabel = "\(Int(progress))/\(Int(target))"
        } else {
            progressLabel = String(format: "%.1f/%.0f", progress, target)
        }

        return WeeklyMission(
            id: id,
            title: title,
            detail: detail,
            progressLabel: progressLabel,
            progressRatio: ratio,
            completed: progress >= target
        )
    }

    private static func consecutiveRunDays(
        from completedRuns: [CompletedRunRecord],
        calendar: Calendar,
        referenceDate: Date
    ) -> Int {
        let runDays = Set(completedRuns.map { calendar.startOfDay(for: $0.endedAt) })
        var streak = 0

        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: referenceDate)) else {
                break
            }

            if runDays.contains(day) {
                streak += 1
            } else if offset > 0 {
                break
            }
        }

        return streak
    }

    private static func weeklyLabel(start: Date, end: Date) -> String {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: start, to: end.addingTimeInterval(-1))
    }
}
