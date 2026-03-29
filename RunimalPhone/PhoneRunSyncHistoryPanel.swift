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
    let onSelectRun: (CompletedRunRecord) -> Void

    var body: some View {
        GameSurface(title: title, accent: accent, eyebrow: eyebrow) {
            VStack(alignment: .leading, spacing: 12) {
                Text(description)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.68))

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
                    .fill(.white.opacity(0.05))
                    .frame(width: 72, height: 72)

                if !run.route.isEmpty {
                    RoutePreviewShape(points: run.route)
                        .stroke(accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .padding(12)
                        .frame(width: 72, height: 72)
                } else {
                    Image(systemName: "point.bottomleft.forward.to.point.topright.scurvepath")
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(accent.opacity(0.85))
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(run.sourceLabel ?? "외부 러닝")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(.white)
                    Spacer()
                    TraitChip(
                        label: canUseRunCore(run) ? "사용 가능" : "사용 완료",
                        accent: canUseRunCore(run) ? .green : .white.opacity(0.18)
                    )
                }

                Text(run.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.62))

                Text(summaryLine(for: run))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    RunimalSignalBadge(icon: "flame.fill", label: "+\(run.reward.experience) XP", accent: .green)
                    if let cadence = run.cadence {
                        RunimalSignalBadge(icon: "waveform.path.ecg", label: "\(cadence) spm", accent: accent)
                    }
                    if let usageSummary = usageSummary(run), canUseRunCore(run) == false {
                        RunimalSignalBadge(icon: "arrow.triangle.branch", label: usageSummary.title, accent: usageSummary.accent)
                    }
                }
            }

            VStack(spacing: 6) {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white.opacity(0.36))
                Spacer(minLength: 0)
            }
        }
        .padding(12)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func summaryLine(for run: CompletedRunRecord) -> String {
        "\(distanceLabel(run.distanceMeters)) · \(durationLabel(run.durationSeconds)) · \(paceLabel(run.averagePaceSeconds))"
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
