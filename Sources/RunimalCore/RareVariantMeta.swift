import Foundation

public enum RareVariantMeta {
    public static let labels: [RareVariant: String] = [
        .tempoSurge: "Tempo Surge",
        .zenBloom: "Zen Bloom",
        .summitHeart: "Summit Heart",
        .eclipseMark: "Eclipse Mark",
        .loopSigil: "Loop Sigil",
    ]

    public static let badges: [RareVariant: String] = [
        .tempoSurge: "TEMPO",
        .zenBloom: "ZEN",
        .summitHeart: "SUMMIT",
        .eclipseMark: "ECLIPSE",
        .loopSigil: "LOOP",
    ]

    public static let passives: [RareVariant: String] = [
        .tempoSurge: "빠른 러닝일수록 경험치가 더 오르고 기동·리듬 성장이 강화됩니다.",
        .zenBloom: "안정적인 페이스일수록 경험치가 더 오르고 체력·집중 성장이 강화됩니다.",
        .summitHeart: "언덕 러닝일수록 경험치가 더 오르고 방어 성장이 크게 강화됩니다.",
        .eclipseMark: "야간 러닝일수록 경험치가 더 오르고 기동·집중 성장이 강화됩니다.",
        .loopSigil: "루프 경로일수록 경험치가 더 오르고 리듬·집중 성장이 강화됩니다.",
    ]

    public static let triggerHints: [RareVariant: String] = [
        .tempoSurge: "고케이던스 · 빠른 페이스",
        .zenBloom: "안정 페이스 · 균형 리듬",
        .summitHeart: "언덕 · 상승 고도",
        .eclipseMark: "야간 러닝 · 그림자 구간",
        .loopSigil: "루프 경로 · 반복 패턴",
    ]
}
