import CoreLocation
import Foundation
import Observation

@MainActor
@Observable
final class PhoneCurrentLocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var pendingHandler: ((CLLocation?) -> Void)?

    var statusLabel = "현재 위치 대기"
    var lastError: String?
    var lastKnownLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestCurrentLocation(_ handler: @escaping (CLLocation?) -> Void) {
        pendingHandler = handler
        lastError = nil

        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            statusLabel = "현재 위치 확인 중"
            manager.requestLocation()
        case .notDetermined:
            statusLabel = "위치 권한 요청"
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            statusLabel = "위치 권한 필요"
            lastError = "현재 위치 팩을 만들려면 iPhone 위치 권한이 필요합니다."
            finish(with: nil)
        @unknown default:
            statusLabel = "위치 상태 미확인"
            finish(with: nil)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                self.statusLabel = "현재 위치 확인 중"
                self.manager.requestLocation()
            case .restricted, .denied:
                self.statusLabel = "위치 권한 필요"
                self.lastError = "현재 위치 팩을 만들려면 iPhone 위치 권한이 필요합니다."
                self.finish(with: nil)
            case .notDetermined:
                break
            @unknown default:
                self.finish(with: nil)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else {
                self.statusLabel = "위치 없음"
                self.finish(with: nil)
                return
            }
            self.lastKnownLocation = location
            self.statusLabel = "현재 위치 확인 완료"
            self.finish(with: location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.statusLabel = "위치 확인 실패"
            self.lastError = error.localizedDescription
            self.finish(with: nil)
        }
    }

    private func finish(with location: CLLocation?) {
        let handler = pendingHandler
        pendingHandler = nil
        handler?(location)
    }
}
