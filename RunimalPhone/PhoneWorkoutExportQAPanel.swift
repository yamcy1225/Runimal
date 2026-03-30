import RunimalCore
import SwiftUI

struct PhoneWorkoutExportQAPanel: View {
    let archive: WorkoutSessionArchive
    let timeBasis: WorkoutExportTimeBasis
    let accent: Color

    private var exportDuration: Int {
        exportDurationSeconds(for: archive, timeBasis: timeBasis)
    }

    private var exportPace: Int? {
        exportAveragePaceSeconds(for: archive, timeBasis: timeBasis)
    }

    private var formatSummaries: [WorkoutExportFormatSummary] {
        WorkoutExportFormat.allCases.map { workoutExportFormatSummary(for: archive, format: $0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("내보내기 점검")
                .font(.caption.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.darkest)

            HStack(spacing: 8) {
                summaryChip("시간 \(durationLabel(exportDuration))")
                summaryChip("페이스 \(paceLabel(exportPace))")
                summaryChip("랩 \(archive.laps.count)개")
            }

            ForEach(formatSummaries, id: \.format) { summary in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(summary.format.displayName)
                            .font(.caption.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.darkest)
                        Spacer()
                        Text(pointLabel(for: summary))
                            .font(.caption2.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.mediumDark)
                    }

                    HStack(spacing: 8) {
                        summaryChip("거리 \(distanceLabel(summary.segmentDistanceMeters))")
                        summaryChip(summary.includesPausedSamples ? "pause 표식 유지" : "pause 구간 제외")
                        summaryChip(summary.containerLabel)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GameBoyPalette.mediumLight.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(summary.format == .fit ? accent.opacity(0.4) : GameBoyPalette.darkest.opacity(0.18), lineWidth: 1)
                )
            }
        }
    }

    private func pointLabel(for summary: WorkoutExportFormatSummary) -> String {
        switch summary.format {
        case .gpx:
            return "트랙 \(summary.pointCount)개"
        case .tcx:
            return "트랙포인트 \(summary.pointCount)개"
        case .fit:
            return "레코드 \(summary.pointCount)개"
        }
    }

    private func summaryChip(_ label: String) -> some View {
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

    private func paceLabel(_ seconds: Int?) -> String {
        guard let seconds else { return "--/km" }
        return "\(seconds / 60):\(String(format: "%02d", seconds % 60))/km"
    }

    private func distanceLabel(_ meters: Double) -> String {
        String(format: "%.2fkm", meters / 1000)
    }
}
