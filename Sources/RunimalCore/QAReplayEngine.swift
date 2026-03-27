import Foundation

public enum RunimalQAReplayEngine {
    public static let scenarios: [QAReplayScenario] = [
        QAReplayScenario(
            id: "offline-link",
            title: "Offline Link",
            trigger: "러닝 종료 직후 폰 연결이 끊긴 상태",
            recoveryExpectation: "reward/completed run이 userInfo 큐로 넘어가고, 재연결 후 자동 반영되어야 합니다."
        ),
        QAReplayScenario(
            id: "route-save-failure",
            title: "Route Save Failure",
            trigger: "워크아웃 저장은 되었지만 route 저장이 빠진 상태",
            recoveryExpectation: "저장 실패 로그가 남고, completed run 자체는 보존되어야 합니다."
        ),
        QAReplayScenario(
            id: "duplicate-replay",
            title: "Duplicate Replay",
            trigger: "같은 completed run이 두 번 들어오는 상태",
            recoveryExpectation: "중복 수신이 걸러지고 journal/run archive가 불어나지 않아야 합니다."
        ),
    ]

    public static func report(for scenario: QAReplayScenario) -> QAReplayReport {
        switch scenario.id {
        case "offline-link":
            return QAReplayReport(
                title: "Queued Sync Recovery",
                severity: "high",
                checkpoints: [
                    "Watch에서 queue count가 증가하는지 확인",
                    "Phone diagnostics에서 queued payload가 도착하는지 확인",
                    "lastReward / completedRun이 최종적으로 1회만 반영되는지 확인",
                ]
            )
        case "route-save-failure":
            return QAReplayReport(
                title: "Partial Save Tolerance",
                severity: "high",
                checkpoints: [
                    "lastSavedWorkoutLabel이 실패 문구로 남는지 확인",
                    "reward reveal과 growth core 생성은 유지되는지 확인",
                    "diagnostics에 save failure 원인이 남는지 확인",
                ]
            )
        default:
            return QAReplayReport(
                title: "Duplicate Guard",
                severity: "medium",
                checkpoints: [
                    "completedRuns 중복 ID가 추가되지 않는지 확인",
                    "journal 최신 항목이 복제되지 않는지 확인",
                    "queue가 비워진 뒤에도 state가 흔들리지 않는지 확인",
                ]
            )
        }
    }
}
