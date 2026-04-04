import Foundation

public enum RareVariantMeta {
    public static let labels: [RareVariant: String] = [
        .tempoSurge: "빠른 질주",
        .zenBloom: "편안한 호흡",
        .summitHeart: "언덕 돌파",
        .eclipseMark: "밤의 흔적",
        .loopSigil: "익숙한 길",
    ]

    public static let badges: [RareVariant: String] = [
        .tempoSurge: "질주",
        .zenBloom: "호흡",
        .summitHeart: "언덕",
        .eclipseMark: "야간",
        .loopSigil: "반복",
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
