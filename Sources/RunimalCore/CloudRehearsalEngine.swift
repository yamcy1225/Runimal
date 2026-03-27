import Foundation

public enum RunimalCloudRehearsalEngine {
    public static func steps(
        hasIdentity: Bool,
        mirrorStatus: String,
        hasConflict: Bool
    ) -> [CloudRehearsalStep] {
        [
            CloudRehearsalStep(
                id: "account",
                title: "Signed Account",
                detail: hasIdentity ? "Account token is visible in runtime." : "로그인된 iCloud 계정으로 실기기 확인이 필요합니다.",
                ready: hasIdentity
            ),
            CloudRehearsalStep(
                id: "mirror",
                title: "Mirror Roundtrip",
                detail: mirrorStatus,
                ready: !mirrorStatus.localizedCaseInsensitiveContains("failed")
            ),
            CloudRehearsalStep(
                id: "conflict",
                title: "Conflict Recovery",
                detail: hasConflict ? "다른 디바이스 스냅샷과 diff를 확인하고 정책 적용 테스트를 권장합니다." : "현재 충돌 없음. 정책 적용 리허설만 진행하면 됩니다.",
                ready: !hasConflict
            ),
        ]
    }
}
