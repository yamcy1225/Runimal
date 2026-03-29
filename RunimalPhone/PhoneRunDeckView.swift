import RunimalCore
import SwiftUI
import UniformTypeIdentifiers

private struct SelectedRunRecord: Identifiable {
    let id: String
}

extension UTType {
    static let mbtilesFile = UTType(filenameExtension: "mbtiles") ?? .data
}

private enum RunArchiveFilter: String, CaseIterable, Identifiable {
    case all
    case runimal
    case imported

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "전체"
        case .runimal: return "Runimal"
        case .imported: return "가져온 기록"
        }
    }
}

struct PhoneRunDeckView: View {
    let store: PhoneDashboardStore
    @State private var isImportingFITFile = false
    @State private var importingOfflineMapPackID: String?
    @State private var selectedRun: SelectedRunRecord?
    @State private var archiveFilter: RunArchiveFilter = .all

    var body: some View {
        ZStack {
            ZStack {
                LinearGradient(
                    colors: [GameBoyPalette.mediumLight, GameBoyPalette.lightest, GameBoyPalette.mediumLight.opacity(0.88)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                GameBoyLCDOverlay()
                    .opacity(0.72)
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerDeck
                    workoutCard
                    if let latestWatchSync = store.latestWatchSyncedRun {
                        watchSyncHighlightCard(for: latestWatchSync)
                    }
                    if let diagnostic = store.latestWatchSyncDiagnostic {
                        watchSyncDiagnosticCard(diagnostic)
                    }
                    summaryCard
                    syncCard
                    PhoneOfflineMapPackPanel(
                        packs: store.offlineMapPacks,
                        watchPacks: store.watchOfflineMapPacks,
                        selectedPackID: store.selectedOfflineMapPackID,
                        importStatusLabel: store.offlineMaps.importStatusLabel,
                        lastImportError: store.offlineMaps.lastImportError,
                        accent: store.pet.accentColor,
                        onCreatePack: { store.registerOfflineMapPack($0) },
                        onSelectPack: { store.setSelectedOfflineMapPack(id: $0) },
                        onImportTiles: { importingOfflineMapPackID = $0 },
                        onRenamePack: { id, title in
                            store.renameOfflineMapPack(id: id, title: title)
                        },
                        onDeletePack: { store.deleteOfflineMapPack(id: $0) }
                    )
                    archiveFilterStrip
                    if shouldShowRunimalArchive {
                        PhoneRunSyncHistoryPanel(
                            title: "Runimal 러닝 기록",
                            eyebrow: "워치 시작 기록",
                            description: "워치에서 `러닝 시작하기`를 눌러 측정한 기록은 여기 쌓입니다.",
                            runs: store.runimalRunArchive,
                            accent: store.pet.accentColor,
                            canUseRunCore: { store.canUseRunCore($0) },
                            usageSummary: { store.runCoreUsageSummary(for: $0) },
                            workoutArchive: { store.workoutArchive(for: $0.id) },
                            onSelectRun: { selectedRun = SelectedRunRecord(id: $0.id) }
                        )
                    }
                    if shouldShowImportedArchive {
                        PhoneRunSyncHistoryPanel(
                            title: "가져온 러닝 기록",
                            eyebrow: "최근 5개",
                            description: "HealthKit 또는 FIT로 가져온 외부 러닝 기록입니다.",
                            runs: store.importedRunArchive,
                            accent: store.pet.accentColor,
                            canUseRunCore: { store.canUseRunCore($0) },
                            usageSummary: { store.runCoreUsageSummary(for: $0) },
                            workoutArchive: { store.workoutArchive(for: $0.id) },
                            onSelectRun: { selectedRun = SelectedRunRecord(id: $0.id) }
                        )
                    }
                    if shouldShowArchiveEmptyState {
                        archiveEmptyState
                    }
                    if let latestCompletedRun = store.latestCompletedRun {
                        PhoneRecentRunCard(
                            run: latestCompletedRun,
                            accent: store.pet.accentColor,
                            targetCompanion: store.featuredCompanion,
                            canFeed: store.availableRunCores.contains(where: { $0.id == latestCompletedRun.id }),
                            onFeed: {
                                store.feedActiveCompanion(with: latestCompletedRun.id)
                            }
                        )
                    }
                    PhoneTelemetryPanel(logger: store.telemetry)
                }
                .padding(20)
            }
        }
        .fileImporter(
            isPresented: $isImportingFITFile,
            allowedContentTypes: [.fitFile],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else {
                    store.fitImport.markImportCancelled()
                    return
                }
                Task { await store.importFITRun(from: url) }
            case .failure(let error):
                store.fitImport.markImportFailed(error.localizedDescription)
            }
        }
        .fileImporter(
            isPresented: Binding(
                get: { importingOfflineMapPackID != nil },
                set: { isPresented in
                    if isPresented == false {
                        importingOfflineMapPackID = nil
                    }
                }
            ),
            allowedContentTypes: [.mbtilesFile],
            allowsMultipleSelection: false
        ) { result in
            let packID = importingOfflineMapPackID
            importingOfflineMapPackID = nil

            switch result {
            case .success(let urls):
                guard let packID, let url = urls.first else {
                    store.offlineMaps.markImportFailed("MBTiles 파일을 선택하지 않았습니다.")
                    return
                }
                store.importOfflineMapPackTiles(from: url, for: packID)
            case .failure(let error):
                store.offlineMaps.markImportFailed(error.localizedDescription)
            }
        }
        .sheet(item: $selectedRun) { selectedRun in
            PhoneRunRecordDetailSheet(store: store, runID: selectedRun.id)
        }
    }

    private var shouldShowRunimalArchive: Bool {
        switch archiveFilter {
        case .all, .runimal:
            return !store.runimalRunArchive.isEmpty
        case .imported:
            return false
        }
    }

    private var shouldShowImportedArchive: Bool {
        switch archiveFilter {
        case .all, .imported:
            return !store.importedRunArchive.isEmpty
        case .runimal:
            return false
        }
    }

    private var shouldShowArchiveEmptyState: Bool {
        switch archiveFilter {
        case .all:
            return store.runimalRunArchive.isEmpty && store.importedRunArchive.isEmpty
        case .runimal:
            return store.runimalRunArchive.isEmpty
        case .imported:
            return store.importedRunArchive.isEmpty
        }
    }

    private var archiveFilterStrip: some View {
        GameSurface(title: "러닝 기록 필터", accent: store.pet.accentColor, eyebrow: "탐색") {
            HStack(spacing: 10) {
                ForEach(RunArchiveFilter.allCases) { filter in
                    Button {
                        archiveFilter = filter
                    } label: {
                        Text(filter.label)
                            .font(.caption.monospaced().weight(.black))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(archiveFilter == filter ? GameBoyPalette.mediumDark : GameBoyPalette.lightest)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(GameBoyPalette.darkest, lineWidth: 2)
                            )
                            .overlay(alignment: .topLeading) {
                                Rectangle()
                                    .fill(store.pet.accentColor.opacity(0.82))
                                    .frame(width: archiveFilter == filter ? 12 : 8, height: 4)
                                    .padding(6)
                            }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(archiveFilter == filter ? GameBoyPalette.lightest : GameBoyPalette.darkest)
                }
            }
        }
    }

    private var archiveEmptyState: some View {
        GameSurface(title: "표시할 러닝 기록이 없습니다", accent: store.pet.accentColor, eyebrow: archiveFilter.label) {
            Text(emptyStateDescription)
                .font(.footnote.monospaced())
                .foregroundStyle(GameBoyPalette.mediumDark)
        }
    }

    private var emptyStateDescription: String {
        switch archiveFilter {
        case .all:
            return "워치에서 직접 측정한 러닝 또는 HealthKit/FIT로 가져온 기록이 아직 없습니다."
        case .runimal:
            return "워치에서 `러닝 시작하기`로 직접 측정한 기록이 아직 없습니다."
        case .imported:
            return "HealthKit 또는 FIT로 가져온 외부 러닝 기록이 아직 없습니다."
        }
    }

    private var headerDeck: some View {
        GameSurface(title: "러닝 준비", accent: store.pet.accentColor, eyebrow: "운동 코어 허브") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(store.suggestedWorkout.title.uppercased())
                            .font(.system(size: 26, weight: .black, design: .monospaced))
                            .foregroundStyle(GameBoyPalette.darkest)
                        Text("운동 에너지, 돌발 목표, 최근 동기화 결과를 한 화면에서 확인합니다.")
                            .font(.footnote.monospaced())
                            .foregroundStyle(GameBoyPalette.mediumDark)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 10)

                    TraitChip(label: store.weeklyBoard.season.title, accent: store.pet.accentColor)
                }

                HStack(spacing: 8) {
                    RunimalSignalBadge(icon: "figure.run", label: "RUN CORE", accent: GameBoyPalette.mediumDark)
                    RunimalSignalBadge(icon: "shippingbox.fill", label: archiveFilter.label, accent: GameBoyPalette.mediumLight)
                }
            }
        }
    }

    private var summaryCard: some View {
        GameSurface(title: "주간 요약", accent: store.pet.accentColor, eyebrow: "이번 시즌") {
            VStack(alignment: .leading, spacing: 14) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    RunimalMetricTile(icon: "figure.run", title: "러닝", value: "\(store.weeklyBoard.runCount)", accent: store.pet.accentColor)
                    RunimalMetricTile(icon: "map", title: "거리", value: "\(store.weeklyBoard.totalDistanceKm.formatted(.number.precision(.fractionLength(1)))) km", accent: .green)
                    RunimalMetricTile(icon: "flame.fill", title: "연속", value: "\(store.weeklyBoard.streakDays)d", accent: .orange)
                    RunimalMetricTile(icon: "sparkles", title: "알", value: "\(store.eggInventory.count)", accent: .mint)
                }

                if let primaryMission = store.weeklyBoard.missions.first {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("지금 목표")
                                .font(.headline.monospaced().weight(.black))
                                .foregroundStyle(GameBoyPalette.darkest)
                            Spacer()
                            TraitChip(
                                label: primaryMission.completed ? "완료" : primaryMission.progressLabel,
                                accent: primaryMission.completed ? .green : store.pet.accentColor
                            )
                        }

                        Text(primaryMission.title)
                            .font(.subheadline.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.darkest)

                        RunimalProgressBar(
                            progress: primaryMission.progressRatio,
                            accent: primaryMission.completed ? .green : store.pet.accentColor,
                            height: 8
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("남은 미션")
                            .font(.headline.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.darkest)
                        Spacer()
                        RunimalSignalBadge(
                            icon: "crown.fill",
                            label: "\(store.weeklyBoard.completedMissionCount)/\(store.weeklyBoard.missions.count)",
                            accent: store.pet.accentColor
                        )
                    }

                    ForEach(store.weeklyBoard.missions.dropFirst().prefix(2), id: \.id) { mission in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(mission.title)
                                    .font(.subheadline.monospaced().weight(.black))
                                    .foregroundStyle(GameBoyPalette.darkest)
                                Spacer()
                                TraitChip(
                                    label: mission.completed ? "완료" : mission.progressLabel,
                                    accent: mission.completed ? .green : GameBoyPalette.mediumLight
                                )
                            }

                            RunimalProgressBar(
                                progress: mission.progressRatio,
                                accent: mission.completed ? .green : store.pet.accentColor,
                                height: 7
                            )
                        }
                    }
                }
            }
        }
    }

    private func watchSyncHighlightCard(for run: CompletedRunRecord) -> some View {
        GameSurface(title: "방금 워치 러닝을 받았습니다", accent: .cyan, eyebrow: "Live Sync") {
            VStack(alignment: .leading, spacing: 12) {
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
                            Image(systemName: "applewatch.radiowaves.left.and.right")
                                .font(.system(size: 24, weight: .black))
                                .foregroundStyle(GameBoyPalette.mediumDark)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(run.startedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.mediumDark)

                        Text("워치에서 직접 측정한 러닝이 코어로 정리됐습니다. 아래 기록에서 바로 성장, 알 생성, 인큐베이트에 쓸 수 있습니다.")
                            .font(.footnote.monospaced())
                            .foregroundStyle(GameBoyPalette.mediumDark)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 8) {
                    RunimalSignalBadge(icon: "figure.run", label: distanceLabel(run.distanceMeters), accent: .cyan)
                    RunimalSignalBadge(icon: "timer", label: durationLabel(run.durationSeconds), accent: .white.opacity(0.2))
                    RunimalSignalBadge(icon: "gauge.with.dots.needle.33percent", label: paceLabel(run.averagePaceSeconds), accent: store.pet.accentColor)
                }

                HStack(spacing: 8) {
                    if let heartRate = run.averageHeartRate {
                        RunimalSignalBadge(icon: "heart.fill", label: "\(Int(heartRate.rounded())) bpm", accent: .pink)
                    }
                    if let cadence = run.cadence {
                        RunimalSignalBadge(icon: "waveform.path.ecg", label: "\(cadence) spm", accent: .mint)
                    }
                    TraitChip(label: "Runimal 러닝 기록에서 확인", accent: .white.opacity(0.18))
                }
            }
        }
    }

    private func watchSyncDiagnosticCard(_ diagnostic: WatchRunSyncDiagnostic) -> some View {
        GameSurface(
            title: diagnostic.hasAnyMismatch ? "워치 동기화 값 점검" : "워치 동기화 값 일치",
            accent: diagnostic.hasAnyMismatch ? .orange : .green,
            eyebrow: "Sync QA"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("워치에서 막 들어온 원본값과 iPhone에 저장된 값을 나란히 비교합니다. 실기 QA 때 거리, 평균 심박, 평균 케이던스 차이를 바로 확인할 수 있습니다.")
                    .font(.footnote.monospaced())
                    .foregroundStyle(GameBoyPalette.mediumDark)

                metricDiffRow(
                    title: "거리",
                    inbound: distanceLabel(diagnostic.inbound.distanceMeters),
                    persisted: distanceLabel(diagnostic.persisted.distanceMeters),
                    delta: signedMetersLabel(diagnostic.distanceDeltaMeters)
                )
                metricDiffRow(
                    title: "시간",
                    inbound: durationLabel(diagnostic.inbound.durationSeconds),
                    persisted: durationLabel(diagnostic.persisted.durationSeconds),
                    delta: signedSecondsLabel(diagnostic.durationDeltaSeconds)
                )
                metricDiffRow(
                    title: "평균 페이스",
                    inbound: paceLabel(diagnostic.inbound.averagePaceSeconds),
                    persisted: paceLabel(diagnostic.persisted.averagePaceSeconds),
                    delta: signedPaceLabel(diagnostic.paceDeltaSeconds)
                )
                if let averageHeartRateDelta = diagnostic.averageHeartRateDelta {
                    metricDiffRow(
                        title: "평균 심박",
                        inbound: heartRateLabel(diagnostic.inbound.averageHeartRate),
                        persisted: heartRateLabel(diagnostic.persisted.averageHeartRate),
                        delta: signedHeartRateLabel(averageHeartRateDelta)
                    )
                }
                if let cadenceDelta = diagnostic.cadenceDelta {
                    metricDiffRow(
                        title: "평균 케이던스",
                        inbound: cadenceLabel(diagnostic.inbound.cadence),
                        persisted: cadenceLabel(diagnostic.persisted.cadence),
                        delta: signedCadenceLabel(cadenceDelta)
                    )
                }
            }
        }
    }

    private func metricDiffRow(title: String, inbound: String, persisted: String, delta: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.darkest)
                Spacer()
                TraitChip(label: delta, accent: delta == "일치" ? .green.opacity(0.28) : .orange.opacity(0.32))
            }

            HStack(spacing: 8) {
                RunimalSignalBadge(icon: "applewatch", label: inbound, accent: .cyan)
                RunimalSignalBadge(icon: "iphone", label: persisted, accent: .white.opacity(0.22))
            }
        }
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

    private func heartRateLabel(_ value: Double?) -> String {
        guard let value else { return "-- bpm" }
        return "\(Int(value.rounded())) bpm"
    }

    private func cadenceLabel(_ value: Int?) -> String {
        guard let value else { return "-- spm" }
        return "\(value) spm"
    }

    private func signedMetersLabel(_ meters: Double) -> String {
        abs(meters) < 1 ? "일치" : String(format: "%@%.0fm", meters > 0 ? "+" : "", meters)
    }

    private func signedSecondsLabel(_ seconds: Int) -> String {
        seconds == 0 ? "일치" : "\(seconds > 0 ? "+" : "")\(seconds)s"
    }

    private func signedPaceLabel(_ seconds: Int) -> String {
        seconds == 0 ? "일치" : "\(seconds > 0 ? "+" : "")\(seconds)s/km"
    }

    private func signedHeartRateLabel(_ bpm: Double) -> String {
        abs(bpm) < 0.5 ? "일치" : String(format: "%@%.0f bpm", bpm > 0 ? "+" : "", bpm)
    }

    private func signedCadenceLabel(_ cadence: Int) -> String {
        cadence == 0 ? "일치" : "\(cadence > 0 ? "+" : "")\(cadence) spm"
    }

    private var workoutCard: some View {
        GameSurface(title: "다음 러닝", accent: store.pet.accentColor, eyebrow: "오늘의 추천") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(GameBoyPalette.lightest)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(GameBoyPalette.darkest, lineWidth: 2)
                            )
                            .frame(width: 96, height: 96)

                        Image(systemName: "figure.run.circle.fill")
                            .font(.system(size: 42, weight: .black))
                            .foregroundStyle(GameBoyPalette.mediumDark)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(store.suggestedWorkout.title.capitalized)
                            .font(.title2.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.darkest)

                        HStack(spacing: 8) {
                            TraitChip(label: "\(store.suggestedWorkout.scheduledDistanceKm.formatted()) km", accent: store.pet.accentColor)
                            TraitChip(label: store.suggestedWorkout.targetPaceBand, accent: GameBoyPalette.mediumLight)
                        }

                        Text(store.suggestedWorkout.summary)
                            .font(.subheadline.monospaced())
                            .foregroundStyle(GameBoyPalette.mediumDark)
                            .lineLimit(2)
                    }
                }

                HStack(spacing: 10) {
                    pixelDeckButton(title: "운동 에너지 연결", filled: true) {
                        Task { await store.requestHealthAuthorization() }
                    }

                    pixelDeckButton(title: "워치에 동기화") {
                        Task { await store.syncWorkoutPlan() }
                    }
                }
            }
        }
    }

    private func pixelDeckButton(title: String, filled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(.caption.monospaced().weight(.black))
                .foregroundStyle(filled ? GameBoyPalette.lightest : GameBoyPalette.darkest)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(filled ? GameBoyPalette.mediumDark : GameBoyPalette.lightest)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(GameBoyPalette.darkest, lineWidth: 2)
                        )
                )
                .overlay(alignment: .topLeading) {
                    Rectangle()
                        .fill(store.pet.accentColor.opacity(0.82))
                        .frame(width: filled ? 14 : 9, height: 4)
                        .padding(6)
                }
        }
        .buttonStyle(.plain)
    }

    private var syncCard: some View {
        GameSurface(title: "연결 상태", accent: store.pet.accentColor, eyebrow: "기기 연동") {
            VStack(alignment: .leading, spacing: 14) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    RunimalMetricTile(icon: "doc.badge.plus", title: "파일", value: "FIT", accent: store.pet.accentColor)
                    RunimalMetricTile(icon: "applewatch.watchface", title: "워치", value: store.connectivity.reachabilityLabel, accent: .cyan)
                    RunimalMetricTile(icon: "shippingbox.fill", title: "보관함", value: store.vault.statusLabel, accent: .orange)
                    RunimalMetricTile(icon: "icloud.fill", title: "클라우드", value: store.cloudMirror.statusLabel, accent: .mint)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("FIT 가져오기")
                        .font(.headline.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.darkest)
                    Text(store.fitImport.importStatusLabel)
                        .font(.footnote.monospaced())
                        .foregroundStyle(GameBoyPalette.mediumDark)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("러닝 설정")
                        .font(.headline.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.darkest)
                    Text(store.autoPauseEnabled ? "자동 pause ON · 저속 구간을 자동으로 pause 처리합니다." : "자동 pause OFF · 정지는 수동 종료/재개만 반영합니다.")
                        .font(.footnote.monospaced())
                        .foregroundStyle(GameBoyPalette.mediumDark)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("오프라인 지도")
                        .font(.headline.monospaced().weight(.black))
                        .foregroundStyle(GameBoyPalette.darkest)
                    Text("iPhone 팩 \(store.offlineMapPacks.count)개 · Watch 카탈로그 \(store.watchOfflineMapPacks.count)개")
                        .font(.footnote.monospaced())
                        .foregroundStyle(GameBoyPalette.mediumDark)
                }

                if let reward = store.connectivity.lastReward {
                    HStack(alignment: .center, spacing: 12) {
                        PixelPetView(pet: reward.pet, pixelSize: 6)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("최근 생성")
                                .font(.caption.monospaced().weight(.black))
                                .foregroundStyle(GameBoyPalette.mediumDark)
                            Text(reward.pet.displayName)
                                .font(.headline.monospaced().weight(.black))
                                .foregroundStyle(GameBoyPalette.darkest)
                            Text(reward.coreLabel)
                                .font(.footnote.monospaced())
                                .foregroundStyle(GameBoyPalette.mediumDark)
                        }

                        Spacer()

                        TraitChip(label: "+\(reward.experience) XP", accent: .green)
                    }
                } else if let snapshot = store.connectivity.lastSnapshot {
                    HStack(spacing: 8) {
                        RunimalSignalBadge(icon: "point.topleft.down.curvedto.point.bottomright.up.fill", label: "\(Int(snapshot.distanceMeters))m", accent: .cyan)
                        RunimalSignalBadge(icon: "waveform.path.ecg", label: "\(snapshot.cadence ?? 0) spm", accent: store.pet.accentColor)
                    }
                }

                HStack(spacing: 10) {
                    RunimalMetricTile(icon: "waveform.path.ecg", title: "케이던스", value: "\(store.summary.cadence) spm", accent: .cyan)
                    RunimalMetricTile(icon: "timer", title: "페이스", value: "\(store.summary.averagePaceSeconds / 60):\(String(format: "%02d", store.summary.averagePaceSeconds % 60))", accent: store.pet.accentColor)
                }

                HStack(spacing: 10) {
                    pixelDeckButton(title: store.autoPauseEnabled ? "자동 Pause ON" : "자동 Pause OFF", filled: store.autoPauseEnabled) {
                        store.setAutoPauseEnabled(!store.autoPauseEnabled)
                    }

                    Spacer(minLength: 0)
                }

                HStack(spacing: 10) {
                    pixelDeckButton(title: "가져오기", filled: true) {
                        isImportingFITFile = true
                    }

                    Button {
                        store.clearImportedExternalRuns()
                    } label: {
                        Text("지우기")
                            .font(.caption.monospaced().weight(.black))
                            .foregroundStyle(GameBoyPalette.darkest)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(GameBoyPalette.lightest)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(GameBoyPalette.darkest, lineWidth: 2)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

}
