import CoreLocation
import RunimalCore
import SwiftUI

struct PhoneWorkoutArchiveSummaryPanel: View {
    let archive: WorkoutSessionArchive
    let accent: Color
    @State private var selectedLap: WorkoutLap?

    var body: some View {
        GameSurface(title: "세션 분석", accent: accent, eyebrow: "시간 · 랩") {
            VStack(alignment: .leading, spacing: 12) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    RunimalMetricTile(icon: "clock", title: "전체", value: durationLabel(archive.elapsedTimeSeconds), accent: accent)
                    RunimalMetricTile(icon: "timer", title: "운동", value: durationLabel(archive.timerTimeSeconds), accent: .green)
                    RunimalMetricTile(icon: "figure.walk.motion", title: "이동", value: durationLabel(archive.movingTimeSeconds), accent: .orange)
                }

                HStack(spacing: 8) {
                    compactChip("자동 pause \(autoPauseCount)회")
                    compactChip("수동 pause \(manualPauseCount)회")
                    compactChip("랩 \(archive.laps.count)개")
                }

                if let distanceAudit {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("거리 점검")
                            .font(.caption.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.darkest)

                        HStack(spacing: 8) {
                            compactChip("저장 \(distanceLabel(distanceAudit.storedMeters))")
                            compactChip("경로 \(distanceLabel(distanceAudit.routeMeters))")
                            compactChip("차이 \(distanceDeltaLabel(distanceAudit.deltaMeters))")
                        }
                    }
                }

                if !archive.laps.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("랩 로그")
                            .font(.caption.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.darkest)

                        ForEach(archive.laps.prefix(5)) { lap in
                            Button {
                                selectedLap = lap
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(alignment: .firstTextBaseline) {
                                        Text("LAP \(lap.index)")
                                            .font(.caption.monospaced().weight(.black))
                                            .foregroundStyle(GameBoyPalette.darkest)
                                        Spacer()
                                        Text("\(distanceLabel(lap.distanceMeters)) · \(durationLabel(lap.timerTimeSeconds))")
                                            .font(.caption.monospaced().weight(.black))
                                            .foregroundStyle(GameBoyPalette.mediumDark)
                                    }

                                    HStack(spacing: 8) {
                                        compactChip("페이스 \(paceLabel(lap.averagePaceSeconds))")
                                        compactChip("심박 \(heartRateLabel(lap.averageHeartRate))")
                                        compactChip("케이던스 \(cadenceLabel(lap.averageCadence))")
                                    }
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(GameBoyPalette.mediumLight.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(GameBoyPalette.darkest.opacity(0.18), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        if archive.laps.count > 5 {
                            Text("추가 랩 \(archive.laps.count - 5)개")
                                .font(.caption.monospaced())
                                .foregroundStyle(GameBoyPalette.mediumDark)
                        }
                    }
                }

                if !timelineEvents.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("이벤트 타임라인")
                            .font(.caption.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.darkest)

                        ForEach(timelineEvents) { event in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(eventLabel(event))
                                    .font(.caption.monospaced().weight(.black))
                                    .foregroundStyle(GameBoyPalette.darkest)
                                    .frame(width: 64, alignment: .leading)

                                Text(eventOffsetLabel(event.timestamp))
                                    .font(.caption.monospaced().weight(.black))
                                    .foregroundStyle(GameBoyPalette.mediumDark)

                                Spacer()

                                if let detail = eventDetail(event) {
                                    Text(detail)
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(GameBoyPalette.mediumDark)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedLap) { lap in
            NavigationStack {
                ZStack {
                    LinearGradient(
                        colors: [GameBoyPalette.mediumLight, GameBoyPalette.lightest, GameBoyPalette.mediumLight.opacity(0.88)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    GameBoyLCDOverlay()
                        .ignoresSafeArea()

                    ScrollView {
                        GameSurface(title: "LAP \(lap.index)", accent: accent, eyebrow: "세부 기록") {
                            VStack(alignment: .leading, spacing: 12) {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                    RunimalMetricTile(icon: "map", title: "거리", value: distanceLabel(lap.distanceMeters), accent: accent)
                                    RunimalMetricTile(icon: "timer", title: "시간", value: durationLabel(lap.timerTimeSeconds), accent: .green)
                                    RunimalMetricTile(icon: "speedometer", title: "페이스", value: paceLabel(lap.averagePaceSeconds), accent: .orange)
                                    RunimalMetricTile(icon: "waveform.path.ecg", title: "심박", value: "\(heartRateLabel(lap.averageHeartRate)) bpm", accent: .pink)
                                    RunimalMetricTile(icon: "figure.run", title: "케이던스", value: "\(cadenceLabel(lap.averageCadence)) spm", accent: .mint)
                                    RunimalMetricTile(icon: "mountain.2.fill", title: "상승", value: "\(lap.elevationGainM)m", accent: .yellow)
                                }
                            }
                        }
                        .padding(20)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("닫기") {
                            selectedLap = nil
                        }
                        .font(.caption.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.darkest)
                    }
                }
                .toolbarBackground(GameBoyPalette.lightest, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            }
        }
    }

    private var autoPauseCount: Int {
        archive.events.filter { $0.kind == .pause && $0.detail == "auto" }.count
    }

    private var manualPauseCount: Int {
        archive.events.filter { $0.kind == .pause && ($0.detail == nil || $0.detail == "paused") }.count
    }

    private var timelineEvents: [WorkoutSessionEvent] {
        archive.events
            .filter { $0.kind == .pause || $0.kind == .resume || $0.kind == .lap }
            .sorted { $0.timestamp < $1.timestamp }
            .prefix(8)
            .map { $0 }
    }

    private var distanceAudit: (storedMeters: Double, routeMeters: Double, deltaMeters: Double)? {
        let routeMeters = inferredRouteDistanceMeters(from: archive.trackPoints)
        guard routeMeters > 0 else { return nil }
        let deltaMeters = routeMeters - archive.distanceMeters
        guard abs(deltaMeters) >= 5 else { return nil }
        return (archive.distanceMeters, routeMeters, deltaMeters)
    }

    private func compactChip(_ label: String) -> some View {
        Text(label)
            .font(.caption2.monospaced().weight(.black))
            .foregroundStyle(GameBoyPalette.darkest)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(GameBoyPalette.lightest)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(GameBoyPalette.darkest, lineWidth: 1)
                    )
            )
    }

    private func durationLabel(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60

        if hours > 0 {
            return "\(hours):\(String(format: "%02d", minutes)):\(String(format: "%02d", remainingSeconds))"
        }

        return "\(minutes):\(String(format: "%02d", remainingSeconds))"
    }

    private func distanceLabel(_ meters: Double) -> String {
        String(format: "%.2fkm", meters / 1000)
    }

    private func paceLabel(_ seconds: Int?) -> String {
        guard let seconds else { return "--/km" }
        return "\(seconds / 60):\(String(format: "%02d", seconds % 60))/km"
    }

    private func heartRateLabel(_ heartRate: Double?) -> String {
        guard let heartRate else { return "--" }
        return "\(Int(heartRate.rounded()))"
    }

    private func cadenceLabel(_ cadence: Int?) -> String {
        guard let cadence else { return "--" }
        return "\(cadence)"
    }

    private func distanceDeltaLabel(_ meters: Double) -> String {
        let sign = meters >= 0 ? "+" : "-"
        return "\(sign)\(Int(abs(meters).rounded()))m"
    }

    private func inferredRouteDistanceMeters(from points: [WorkoutTrackPoint]) -> Double {
        guard points.count > 1 else { return 0 }
        var total: Double = 0

        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            guard current.gpsPoor == false else { continue }

            let previousLocation = CLLocation(latitude: previous.latitude, longitude: previous.longitude)
            let currentLocation = CLLocation(latitude: current.latitude, longitude: current.longitude)
            let segmentDistance = currentLocation.distance(from: previousLocation)
            let delta = current.timestamp.timeIntervalSince(previous.timestamp)

            if delta > 0, segmentDistance >= 1, segmentDistance <= 120, (segmentDistance / delta) <= 8.5 {
                total += segmentDistance
            }
        }

        return total
    }

    private func eventLabel(_ event: WorkoutSessionEvent) -> String {
        switch event.kind {
        case .pause: return "PAUSE"
        case .resume: return "RESUME"
        case .lap: return "LAP"
        case .start: return "START"
        case .end: return "END"
        }
    }

    private func eventOffsetLabel(_ timestamp: Date) -> String {
        let offset = max(Int(timestamp.timeIntervalSince(archive.startedAt).rounded()), 0)
        return durationLabel(offset)
    }

    private func eventDetail(_ event: WorkoutSessionEvent) -> String? {
        if event.kind == .pause && event.detail == "auto" {
            return "자동"
        }
        if event.kind == .lap {
            return event.detail?.replacingOccurrences(of: "lap-", with: "#")
        }
        return nil
    }
}
