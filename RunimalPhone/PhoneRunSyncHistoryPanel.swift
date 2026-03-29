import RunimalCore
import SwiftUI

struct PhoneRunSyncHistoryPanel: View {
    let title: String
    let eyebrow: String
    let description: String
    let runs: [CompletedRunRecord]
    let accent: Color
    let canUseRunCore: (CompletedRunRecord) -> Bool
    let usageSummary: (CompletedRunRecord) -> PhoneRunCoreUsageSummary?
    let workoutArchive: (CompletedRunRecord) -> WorkoutSessionArchive?
    let onSelectRun: (CompletedRunRecord) -> Void

    var body: some View {
        GameSurface(title: title, accent: accent, eyebrow: eyebrow) {
            VStack(alignment: .leading, spacing: 12) {
                Text(description)
                    .font(.footnote.monospaced())
                    .foregroundStyle(GameBoyPalette.mediumDark)

                ForEach(Array(runs.prefix(5))) { run in
                    Button {
                        onSelectRun(run)
                    } label: {
                        row(for: run)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func row(for run: CompletedRunRecord) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(GameBoyPalette.lightest)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(GameBoyPalette.darkest, lineWidth: 2)
                    )
                    .frame(width: 72, height: 72)

                if !run.route.isEmpty {
                    RoutePreviewShape(points: run.route)
                        .stroke(GameBoyPalette.mediumDark, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .padding(12)
                        .frame(width: 72, height: 72)
                } else {
                    Image(systemName: "point.bottomleft.forward.to.point.topright.scurvepath")
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(GameBoyPalette.mediumDark)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(compactSourceLabel(for: run))
                        .font(.subheadline.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.darkest)
                    Spacer()
                    TraitChip(
                        label: canUseRunCore(run) ? "사용 가능" : "사용 완료",
                        accent: canUseRunCore(run) ? .green : .white.opacity(0.18)
                    )
                }

                Text(run.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption.monospaced())
                    .foregroundStyle(GameBoyPalette.mediumDark)

                Text(summaryLine(for: run))
                    .font(.caption.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.mediumDark)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    RunimalSignalBadge(icon: "flame.fill", label: "+\(run.reward.experience) XP", accent: .green)
                    if let autoPauseBadge = autoPauseBadgeLabel(for: run) {
                        TraitChip(label: autoPauseBadge, accent: .orange.opacity(0.82))
                    }
                    TraitChip(
                        label: canUseRunCore(run) ? "사용 가능" : compactUsageLabel(for: run),
                        accent: canUseRunCore(run) ? .green : (usageSummary(run)?.accent ?? GameBoyPalette.mediumDark)
                    )
                }

                Text(secondaryLine(for: run))
                    .font(.caption2.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.mediumDark.opacity(0.9))
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)
            }

            VStack(spacing: 6) {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.black))
                    .foregroundStyle(GameBoyPalette.mediumDark)
                Spacer(minLength: 0)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(GameBoyPalette.mediumLight.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(GameBoyPalette.darkest.opacity(0.28), lineWidth: 1)
                )
        )
    }

    private func summaryLine(for run: CompletedRunRecord) -> String {
        "\(distanceLabel(run.distanceMeters)) · \(durationLabel(run.durationSeconds)) · \(paceLabel(run.averagePaceSeconds))"
    }

    private func secondaryLine(for run: CompletedRunRecord) -> String {
        let cadenceText = run.cadence.map { "\($0) spm" } ?? "-- spm"
        if let usage = usageSummary(run), canUseRunCore(run) == false {
            return "\(cadenceText) · \(usage.detail)"
        }
        return "\(cadenceText) · 코어 대기 중"
    }

    private func compactUsageLabel(for run: CompletedRunRecord) -> String {
        guard let usage = usageSummary(run), canUseRunCore(run) == false else {
            return "사용 완료"
        }
        return usage.title
    }

    private func autoPauseBadgeLabel(for run: CompletedRunRecord) -> String? {
        guard let archive = workoutArchive(run) else { return nil }
        let count = archive.events.filter { $0.kind == .pause && $0.detail == "auto" }.count
        return "AUTO \(count)회"
    }

    private func compactSourceLabel(for run: CompletedRunRecord) -> String {
        if run.source == "watch-healthkit" {
            return "Runimal"
        }

        if run.source.hasPrefix("fit:") {
            return "FIT"
        }

        if let sourceLabel = run.sourceLabel, !sourceLabel.isEmpty {
            return sourceLabel
        }

        return "외부"
    }

    private func distanceLabel(_ meters: Double) -> String {
        String(format: "%.2f km", meters / 1000)
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
        guard let seconds else { return "페이스 --" }
        let minutes = seconds / 60
        return "\(minutes):\(String(format: "%02d", seconds % 60))/km"
    }
}
