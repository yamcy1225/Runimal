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
    let canDeleteRun: (CompletedRunRecord) -> Bool
    let onExportRun: (CompletedRunRecord) -> Void
    let onDeleteRun: (CompletedRunRecord) -> Void
    let onSelectRun: (CompletedRunRecord) -> Void

    @State private var focusedRunID: String?
    @State private var pendingDeleteRunID: String?

    var body: some View {
        GameSurface(title: title, accent: accent, eyebrow: eyebrow) {
            VStack(alignment: .leading, spacing: 12) {
                Text(description)
                    .font(.footnote.monospaced())
                    .foregroundStyle(GameBoyPalette.mediumDark)

                if runs.isEmpty {
                    Text("아직 쌓인 기록이 없습니다.")
                        .font(.footnote.monospaced())
                        .foregroundStyle(GameBoyPalette.mediumDark)
                } else {
                    headerStrip

                    GeometryReader { geometry in
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 14) {
                                ForEach(runs) { run in
                                    row(for: run)
                                        .frame(height: cardHeight(in: geometry))
                                        .id(run.id)
                                }
                            }
                            .scrollTargetLayout()
                        }
                        .scrollTargetBehavior(.paging)
                        .scrollPosition(id: $focusedRunID)
                    }
                    .frame(height: 260)
                }
            }
        }
        .onAppear {
            if focusedRunID == nil {
                focusedRunID = runs.first?.id
            }
        }
        .onChange(of: runs.map(\.id)) { _, ids in
            if ids.contains(focusedRunID ?? "") == false {
                focusedRunID = ids.first
            }
        }
        .alert("이 러닝 기록을 삭제할까요?", isPresented: deleteAlertBinding) {
            Button("삭제", role: .destructive) {
                guard let run = runs.first(where: { $0.id == pendingDeleteRunID }) else { return }
                onDeleteRun(run)
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("아직 성장이나 알 생성에 쓰이지 않은 기록만 삭제할 수 있습니다.")
        }
    }

    private var headerStrip: some View {
        HStack {
            Text("위아래로 넘겨서 다음 기록 보기")
                .font(.caption.monospaced())
                .foregroundStyle(GameBoyPalette.mediumDark)
            Spacer()
            Text(pageLabel)
                .font(.caption.monospaced().weight(.black))
                .foregroundStyle(GameBoyPalette.darkest)
        }
    }

    private var pageLabel: String {
        guard let focusedRunID,
              let index = runs.firstIndex(where: { $0.id == focusedRunID }) else {
            return "1 / \(max(runs.count, 1))"
        }
        return "\(index + 1) / \(runs.count)"
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingDeleteRunID != nil },
            set: { isPresented in
                if isPresented == false {
                    pendingDeleteRunID = nil
                }
            }
        )
    }

    private func row(for run: CompletedRunRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                onSelectRun(run)
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    previewBox(for: run)

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
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                compactActionButton(
                    title: "내보내기",
                    accent: workoutArchive(run) == nil ? GameBoyPalette.mediumLight : .mint,
                    disabled: workoutArchive(run) == nil
                ) {
                    onExportRun(run)
                }

                compactActionButton(
                    title: "삭제",
                    accent: canDeleteRun(run) ? .red : GameBoyPalette.mediumLight,
                    disabled: !canDeleteRun(run)
                ) {
                    pendingDeleteRunID = run.id
                }
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

    private func previewBox(for run: CompletedRunRecord) -> some View {
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
    }

    private func compactActionButton(
        title: String,
        accent: Color,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.monospaced().weight(.black))
                .foregroundStyle(disabled ? GameBoyPalette.mediumDark : (title == "삭제" ? Color.white : GameBoyPalette.darkest))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(disabled ? GameBoyPalette.lightest : accent)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(GameBoyPalette.darkest, lineWidth: 2)
                        )
                )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private func cardHeight(in geometry: GeometryProxy) -> CGFloat {
        max(236, geometry.size.height)
    }

    private func summaryLine(for run: CompletedRunRecord) -> String {
        "\(distanceLabel(run.distanceMeters)) · \(durationLabel(run.durationSeconds)) · \(paceLabel(run.averagePaceSeconds))"
    }

    private func secondaryLine(for run: CompletedRunRecord) -> String {
        let cadenceText = run.cadence.map { "\($0) spm" } ?? "-- spm"
        if let usage = usageSummary(run), canUseRunCore(run) == false {
            return "\(cadenceText) · \(usage.detail)"
        }
        return "\(cadenceText) · 기록 대기 중"
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
