import Foundation

public enum RunimalContentRotationEngine {
    public static func entries(for season: WeeklySeason) -> [ContentRotationEntry] {
        [
            ContentRotationEntry(
                id: "\(season.title)-hunt",
                title: "\(season.title) Hunt",
                detail: "\(season.focusSpecies.rawValue) 계열 또는 \(season.focusVariant?.rawValue ?? "standard") 변이를 추적하는 회차입니다.",
                reward: "Season cache progress"
            ),
            ContentRotationEntry(
                id: "\(season.title)-relay",
                title: "Relay Research",
                detail: "이번 주 러닝 3회 이상으로 연구 로그를 채우면 희귀 변이 설명이 강화됩니다.",
                reward: "Codex unlock hint"
            ),
            ContentRotationEntry(
                id: "\(season.title)-forge",
                title: "Forge Window",
                detail: "Essence를 촉매로 바꿔 시즌 정렬 펫에게 몰아주는 권장 구간입니다.",
                reward: "Extra forge value"
            ),
        ]
    }
}
