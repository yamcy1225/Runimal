import RunimalCore
import SwiftUI
import UniformTypeIdentifiers

struct PhoneRunDeckView: View {
    let store: PhoneDashboardStore
    @State private var isImportingFITFile = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.05, blue: 0.08),
                    Color(red: 0.02, green: 0.03, blue: 0.05),
                    .cyan.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerDeck
                    workoutCard
                    summaryCard
                    syncCard
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
    }

    private var headerDeck: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("러닝 준비")
                .font(.caption.weight(.black))
                .tracking(1.4)
                .foregroundStyle(.cyan.opacity(0.9))

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.suggestedWorkout.title.capitalized)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("운동 에너지, 돌발 목표, 최근 동기화 결과를 한 화면에서 확인합니다.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.68))
                }

                Spacer()

                TraitChip(label: store.weeklyBoard.season.title, accent: store.pet.accentColor)
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
                                .font(.headline.weight(.black))
                                .foregroundStyle(.white)
                            Spacer()
                            TraitChip(
                                label: primaryMission.completed ? "완료" : primaryMission.progressLabel,
                                accent: primaryMission.completed ? .green : store.pet.accentColor
                            )
                        }

                        Text(primaryMission.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)

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
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)
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
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.white)
                                Spacer()
                                TraitChip(
                                    label: mission.completed ? "완료" : mission.progressLabel,
                                    accent: mission.completed ? .green : .white.opacity(0.18)
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

    private var workoutCard: some View {
        GameSurface(title: "다음 러닝", accent: store.pet.accentColor, eyebrow: "오늘의 추천") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(store.pet.accentColor.opacity(0.14))
                            .frame(width: 96, height: 96)

                        Image(systemName: "figure.run.circle.fill")
                            .font(.system(size: 42, weight: .black))
                            .foregroundStyle(store.pet.accentColor)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(store.suggestedWorkout.title.capitalized)
                            .font(.title2.weight(.black))
                            .foregroundStyle(.white)

                        HStack(spacing: 8) {
                            TraitChip(label: "\(store.suggestedWorkout.scheduledDistanceKm.formatted()) km", accent: store.pet.accentColor)
                            TraitChip(label: store.suggestedWorkout.targetPaceBand, accent: .white.opacity(0.22))
                        }

                        Text(store.suggestedWorkout.summary)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(2)
                    }
                }

                HStack(spacing: 10) {
                    Button("운동 에너지 연결") {
                        Task { await store.requestHealthAuthorization() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(store.pet.accentColor)
                    .fontWeight(.black)

                    Button("워치에 동기화") {
                        Task { await store.syncWorkoutPlan() }
                    }
                    .buttonStyle(.bordered)
                    .tint(.white.opacity(0.3))
                }
            }
        }
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
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                    Text(store.fitImport.importStatusLabel)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                }

                if let reward = store.connectivity.lastReward {
                    HStack(alignment: .center, spacing: 12) {
                        PixelPetView(pet: reward.pet, pixelSize: 6)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("최근 생성")
                                .font(.caption.weight(.black))
                                .foregroundStyle(reward.pet.accentColor)
                            Text(reward.pet.displayName)
                                .font(.headline.weight(.black))
                                .foregroundStyle(.white)
                            Text(reward.coreLabel)
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.68))
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
                    Button("가져오기") {
                        isImportingFITFile = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(store.pet.accentColor)
                    .fontWeight(.black)

                    Button("지우기") {
                        store.clearImportedExternalRuns()
                    }
                    .buttonStyle(.bordered)
                    .tint(.white.opacity(0.32))
                    .fontWeight(.black)
                }
            }
        }
    }

}
