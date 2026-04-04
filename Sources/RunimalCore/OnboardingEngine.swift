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
                id: "run-1",
                title: "Run 1 · 첫 ??? 알 확보",
                detail: "빈 슬롯 상태의 첫 성공 러닝은 스타터 알로 고정되어 첫 생명 신호를 남깁니다.",
                completed: hasStarterEgg
            ),
            StarterLoopStep(
                id: "run-2",
                title: "Run 2 · 첫 부화 보장",
                detail: "둘째 러닝은 스타터 알의 부화선을 넘기도록 설계되어 첫 동행이 반드시 깨어납니다.",
                completed: hasFirstHatch
            ),
            StarterLoopStep(
                id: "run-3",
                title: "Run 3 · 첫 단계 상승",
                detail: "첫 의미 있는 먹이 주기는 유아기 진입을 보장해 성장의 손맛을 바로 보여 줍니다.",
                completed: hasStageAdvance
            ),
        ]
    }
}
