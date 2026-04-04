import Foundation

public enum RunimalOnboardingEngine {
    public static func starterLoop(
        completedRuns: [CompletedRunRecord],
        collection: [PetCollectionEntry],
        eggInventory: [EggInventoryEntry],
        hasStageAdvance: Bool
    ) -> [StarterLoopStep] {
        let hasStarterEgg = !eggInventory.isEmpty || !collection.isEmpty
        let hasFirstHatch = !collection.isEmpty

        return [
            StarterLoopStep(
                id: "day-1",
                title: "Step 1 · 첫 ??? 알 획득",
                detail: "빈 슬롯 상태의 첫 성공 러닝으로 숨겨진 알을 확보합니다.",
                completed: hasStarterEgg
            ),
            StarterLoopStep(
                id: "day-2",
                title: "Step 2 · 첫 부화 완료",
                detail: "둘째 러닝으로 알을 부화시켜 첫 동행을 대표로 세웁니다.",
                completed: hasFirstHatch
            ),
            StarterLoopStep(
                id: "day-3",
                title: "Step 3 · 첫 단계 상승",
                detail: "셋째 운동 기록을 먹여 첫 성장 단계를 넘깁니다.",
                completed: hasStageAdvance
            ),
        ]
    }
}
