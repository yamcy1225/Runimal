import Foundation

public enum RunimalOnboardingEngine {
    public static func starterLoop(
        completedRuns: [CompletedRunRecord],
        collection: [PetCollectionEntry],
        activeEffects: [WeeklyRewardEffect]
    ) -> [StarterLoopStep] {
        let runCount = completedRuns.count
        let hasCollectionDepth = collection.count >= 2
        let hasEffects = !activeEffects.isEmpty

        return [
            StarterLoopStep(
                id: "day-1",
                title: "Day 1 · 첫 러닝 저장",
                detail: "워치 러닝을 끝내고 첫 보상 펫을 받아 루프를 여는 단계입니다.",
                completed: runCount >= 1
            ),
            StarterLoopStep(
                id: "day-2",
                title: "Day 2 · 컬렉션 분화",
                detail: "두 번째 펫을 만들고 주력 펫을 선택해 성장 방향을 나누는 단계입니다.",
                completed: hasCollectionDepth
            ),
            StarterLoopStep(
                id: "day-3",
                title: "Day 3 · 효과 체인 연결",
                detail: "주간 보상이나 시즌 캐시를 받아 성장 효과 체인을 체험하는 단계입니다.",
                completed: hasEffects
            ),
        ]
    }
}
