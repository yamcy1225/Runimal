import Foundation

public enum RunimalDeviceQAEngine {
    public static let checklist: [DeviceQACheckItem] = [
        DeviceQACheckItem(
            id: "watch-run-save",
            title: "Watch workout + route save",
            detail: "실기기 워치 러닝 종료 후 HealthKit workout과 route가 동시에 남는지 확인"
        ),
        DeviceQACheckItem(
            id: "offline-recovery",
            title: "Offline recovery replay",
            detail: "폰 연결이 끊긴 상태에서 queue가 쌓이고, 재연결 후 completed run이 자동 반영되는지 확인"
        ),
        DeviceQACheckItem(
            id: "duplicate-guard",
            title: "Duplicate guard",
            detail: "같은 completed run이 중복으로 들어와도 journal과 growth slot이 불어나지 않는지 확인"
        ),
        DeviceQACheckItem(
            id: "season-reward",
            title: "Season reward persistence",
            detail: "시즌 캐시 수령 후 앱 재실행과 금고 복구 뒤에도 재화가 유지되는지 확인"
        ),
    ]
}
