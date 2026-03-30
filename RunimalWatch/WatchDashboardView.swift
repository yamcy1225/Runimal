import RunimalCore
import SwiftUI

struct WatchDashboardView: View {
    @State private var runSessionManager = WatchRunSessionManager()
    @State private var connectivityManager = WatchConnectivityManager.shared
    @State private var displayedMainCompanionContext: WatchMainCompanionContext?
    @State private var offlineMapCatalog = WatchOfflineMapPackCatalog()
    @State private var hatchBurstScale: CGFloat = 0.9
    @State private var countdownValue: Int?

    private var mainCompanionContext: WatchMainCompanionContext? {
        displayedMainCompanionContext ?? connectivityManager.mainCompanionContext
    }

    private var livePet: GeneratedPet {
        runSessionManager.livePet
    }

    private var stageAccent: Color {
        let baseAccent = mainCompanionAccent
        switch liveFeedback.label {
        case "Rare Window":
            return .mint
        case "Surge":
            return .orange
        case "Stable":
            return baseAccent
        case "Recover":
            return .yellow
        default:
            return baseAccent.opacity(0.82)
        }
    }

    private var mainCompanionAccent: Color {
        guard let mainCompanionContext else {
            return livePet.accentColor
        }

        switch mainCompanionContext.selection.kind {
        case .pet:
            return mainCompanionContext.pet?.accentColor ?? livePet.accentColor
        case .egg:
            return mainCompanionContext.eggShell?.accentColor ?? runSessionManager.sessionShell.accentColor
        }
    }

    private var stageBadges: [String] {
        connectivityManager.activeEffects.map(\.title)
    }

    private var growthRatio: Double {
        min(max(runSessionManager.latestSnapshot.distanceMeters / 5000, 0.08), 1)
    }

    private var heartResonance: Double {
        guard let bpm = runSessionManager.latestSnapshot.currentHeartRate else { return 0.28 }
        return min(max((bpm - 90) / 80, 0.18), 1)
    }

    private var liveFeedback: LiveRunFeedback {
        RunimalGameEngine.evaluateLiveFeedback(
            for: runSessionManager.latestSnapshot,
            claimedRewardIDs: runSessionManager.claimedWeeklyRewardIDs
        )
    }

    private var liveGoals: [LiveGoalTarget] {
        RunimalGameEngine.liveGoals(
            for: runSessionManager.latestSnapshot,
            claimedRewardIDs: runSessionManager.claimedWeeklyRewardIDs
        )
    }

    private var primaryGoal: LiveGoalTarget? {
        liveGoals.max(by: { $0.progress < $1.progress })
    }

    var body: some View {
        WatchDashboardPages(
            runtimeAlert: runSessionManager.runtimeAlert,
            mainCompanionContext: mainCompanionContext,
            stageAccent: stageAccent,
            sessionStateLabel: runSessionManager.sessionStateLabel,
            syncStatusLabel: connectivityManager.syncStatusLabel,
            heartResonance: heartResonance,
            growthRatio: growthRatio,
            latestSnapshot: runSessionManager.latestSnapshot,
            latestGPSAccuracyMeters: runSessionManager.latestGPSAccuracyMeters,
            gpsLastUpdatedAt: runSessionManager.gpsLastUpdatedAt,
            locationStatusLabel: runSessionManager.locationStatusLabel,
            liveFeedback: liveFeedback,
            stageBadges: stageBadges,
            liveGoals: liveGoals,
            primaryGoalDetail: primaryGoal?.detail ?? liveFeedback.detail,
            lastSyncedWorkoutTitle: connectivityManager.lastSyncedWorkoutTitle,
            offlineMapPacks: offlineMapCatalog.packs,
            selectedOfflineMapPackID: offlineMapCatalog.selectedPackID,
            storedOfflineMapPackIDs: connectivityManager.offlineMapStorage.storedPackIDs,
            offlineMapStorage: connectivityManager.offlineMapStorage,
            routePreview: runSessionManager.liveRoutePreview,
            reward: runSessionManager.lastReward,
            hatchBurstScale: hatchBurstScale,
            countdownValue: countdownValue,
            onRefreshCompanion: connectivityManager.refreshMainCompanionContext,
            onStartRun: startRunWithCountdown,
            onEndRun: endRun
        )
        .overlay {
            if let countdownValue {
                WatchRunCountdownOverlay(
                    value: countdownValue,
                    accent: stageAccent
                )
            }
        }
        .background(
            ZStack {
                LinearGradient(
                    colors: [GameBoyPalette.mediumLight, GameBoyPalette.lightest, GameBoyPalette.mediumLight.opacity(0.88)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                GameBoyLCDOverlay()
                    .opacity(0.7)
            }
            .ignoresSafeArea()
        )
        .task {
            runSessionManager.setAutoPauseEnabled(connectivityManager.autoPauseEnabled)
            runSessionManager.prepareGPSPreview()
            offlineMapCatalog.replace(
                with: connectivityManager.offlineMapPacks,
                selectedPackID: connectivityManager.selectedOfflineMapPackID
            )
            connectivityManager.offlineMapStorage.reloadFromDisk()
            runSessionManager.autoplayDemoIfNeeded()
        }
        .task {
            while Task.isCancelled == false {
                displayedMainCompanionContext = connectivityManager.resolvedMainCompanionContext()
                try? await Task.sleep(for: .seconds(1))
            }
        }
        .onChange(of: connectivityManager.claimedRewardIDs) { _, rewardIDs in
            let context = CompanionEffectContext(
                claimedRewardIDs: Array(rewardIDs).sorted(),
                activeEffects: connectivityManager.activeEffects
            )
            runSessionManager.applyCompanionContext(context)
        }
        .onChange(of: connectivityManager.autoPauseEnabled) { _, enabled in
            runSessionManager.setAutoPauseEnabled(enabled)
        }
        .onChange(of: connectivityManager.offlineMapPacks) { _, packs in
            offlineMapCatalog.replace(
                with: packs,
                selectedPackID: connectivityManager.selectedOfflineMapPackID
            )
        }
        .onChange(of: connectivityManager.selectedOfflineMapPackID) { _, selectedPackID in
            offlineMapCatalog.replace(
                with: connectivityManager.offlineMapPacks,
                selectedPackID: selectedPackID
            )
        }
        .onChange(of: runSessionManager.latestSnapshot) { _, snapshot in
            connectivityManager.send(snapshot: snapshot)
        }
        .onChange(of: runSessionManager.lastReward) { _, reward in
            guard let reward else { return }
            connectivityManager.send(reward: reward)
        }
        .onChange(of: liveFeedback.label) { _, _ in
            RunimalCuePlayer.playLiveCue(label: liveFeedback.label, intensity: liveFeedback.intensity)
        }
        .onChange(of: runSessionManager.lastCompletedRun) { _, record in
            guard let record else { return }
            connectivityManager.send(completedRun: record)
        }
        .onChange(of: runSessionManager.lastWorkoutArchive) { _, archive in
            guard let archive else { return }
            connectivityManager.send(workoutArchive: archive)
        }
        .onChange(of: runSessionManager.lastReward) { _, reward in
            guard reward != nil else { return }
            animateHatchBurst()
            RunimalCuePlayer.playHatchCue(for: reward?.pet)
        }
        .animation(.spring(response: 0.7, dampingFraction: 0.84), value: runSessionManager.lastReward != nil)
        .animation(.easeInOut(duration: 0.9), value: liveFeedback.label)
    }

    private func animateHatchBurst() {
        hatchBurstScale = 0.82
        withAnimation(.spring(response: 0.6, dampingFraction: 0.66)) {
            hatchBurstScale = 1.05
        }
    }

    private func startRunWithCountdown() {
        guard countdownValue == nil else { return }
        Task {
            if runSessionManager.authorizationStatus != "authorized", runSessionManager.isDemoMode == false {
                await runSessionManager.requestAuthorization()
            }

            for value in stride(from: 3, through: 1, by: -1) {
                await MainActor.run {
                    countdownValue = value
                }
                WKInterfaceDevice.current().play(.start)
                try? await Task.sleep(for: .seconds(1))
            }

            await MainActor.run {
                countdownValue = nil
            }

            await runSessionManager.startRun()
        }
    }

    private func endRun() {
        Task {
            await runSessionManager.endRun()
        }
    }
}

private struct WatchDashboardPages: View {
    let runtimeAlert: WatchRuntimeAlert?
    let mainCompanionContext: WatchMainCompanionContext?
    let stageAccent: Color
    let sessionStateLabel: String
    let syncStatusLabel: String
    let heartResonance: Double
    let growthRatio: Double
    let latestSnapshot: LiveRunSnapshot
    let latestGPSAccuracyMeters: Double?
    let gpsLastUpdatedAt: Date?
    let locationStatusLabel: String
    let liveFeedback: LiveRunFeedback
    let stageBadges: [String]
    let liveGoals: [LiveGoalTarget]
    let primaryGoalDetail: String
    let lastSyncedWorkoutTitle: String
    let offlineMapPacks: [OfflineMapPackSummary]
    let selectedOfflineMapPackID: String?
    let storedOfflineMapPackIDs: Set<String>
    let offlineMapStorage: WatchOfflineMapPackStorage
    let routePreview: [RoutePoint]
    let reward: RunRewardSummary?
    let hatchBurstScale: CGFloat
    let countdownValue: Int?
    let onRefreshCompanion: () -> Void
    let onStartRun: () -> Void
    let onEndRun: () -> Void

    var body: some View {
        TabView {
            WatchSingleCardPage {
                VStack(spacing: 10) {
                    if let runtimeAlert {
                        WatchRuntimeAlertBanner(alert: runtimeAlert)
                    }

                    WatchLaunchPageCard(
                        companion: mainCompanionContext,
                        accent: stageAccent,
                        sessionStateLabel: sessionStateLabel,
                        heartResonance: heartResonance,
                        gpsAccuracyMeters: latestGPSAccuracyMeters,
                        lastGPSUpdateAt: gpsLastUpdatedAt,
                        locationStatusLabel: locationStatusLabel,
                        countdownValue: countdownValue,
                        onPrimaryAction: sessionStateLabel == "running" ? onEndRun : onStartRun,
                        onRefreshCompanion: onRefreshCompanion
                    )
                }
            }
            .tag(0)

            WatchSingleCardPage {
                WatchRunStatsPanel(
                    snapshot: latestSnapshot,
                    gpsAccuracyMeters: latestGPSAccuracyMeters,
                    lastGPSUpdateAt: gpsLastUpdatedAt,
                    locationStatusLabel: locationStatusLabel,
                    accent: stageAccent
                )
            }
            .tag(1)

            WatchSingleCardPage {
                WatchRunPulseCard(
                    feedback: liveFeedback,
                    accent: stageAccent,
                    badges: Array(stageBadges.prefix(2))
                )
            }
            .tag(2)

            WatchSingleCardPage {
                WatchGoalTrackCard(
                    goals: liveGoals,
                    accent: stageAccent
                )
            }
            .tag(3)

            WatchSingleCardPage {
                WatchOfflineMapPreviewCard(
                    selectedPack: selectedOfflineMapPack,
                    isStoredLocally: selectedOfflineMapPack.map { storedOfflineMapPackIDs.contains($0.id) } ?? false,
                    storage: offlineMapStorage,
                    route: routePreview,
                    accent: stageAccent
                )
            }
            .tag(4)

            WatchSingleCardPage {
                WatchOfflineMapPackCard(
                    packs: offlineMapPacks,
                    selectedPackID: selectedOfflineMapPackID,
                    storedPackIDs: storedOfflineMapPackIDs,
                    storage: offlineMapStorage,
                    accent: stageAccent
                )
            }
            .tag(5)

            if sessionStateLabel == "running" {
                WatchSingleCardPage {
                    WatchRunningGoalSection(
                        lastSyncedWorkoutTitle: lastSyncedWorkoutTitle,
                        detail: primaryGoalDetail
                    )
                }
                .tag(6)
            }

            if let reward {
                WatchSingleCardPage {
                    WatchRewardSection(
                        reward: reward,
                        hatchBurstScale: hatchBurstScale
                    )
                }
                .tag(7)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
    }

    private var selectedOfflineMapPack: OfflineMapPackSummary? {
        guard let selectedOfflineMapPackID else { return offlineMapPacks.first }
        return offlineMapPacks.first(where: { $0.id == selectedOfflineMapPackID }) ?? offlineMapPacks.first
    }
}

private struct WatchRunCountdownOverlay: View {
    let value: Int
    let accent: Color

    var body: some View {
        ZStack {
            GameBoyPalette.mediumLight.opacity(0.94)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Text("\(value)")
                    .font(.system(size: 44, weight: .black, design: .monospaced))
                    .foregroundStyle(GameBoyPalette.darkest)
                Text("러닝 시작")
                    .font(.caption.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.mediumDark)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(GameBoyPalette.lightest)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(GameBoyPalette.darkest, lineWidth: 2)
                    )
            )
        }
        .transition(.opacity)
    }
}

private struct WatchSingleCardPage<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { proxy in
            VStack {
                Spacer(minLength: 6)
                content
                    .frame(maxWidth: proxy.size.width - 2)
                Spacer(minLength: 18)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .padding(.horizontal, 2)
        .padding(.top, 6)
        .padding(.bottom, 14)
    }
}

private struct WatchRunningGoalSection: View {
    let lastSyncedWorkoutTitle: String
    let detail: String

    var body: some View {
        GameSurface(title: "러닝 목표") {
            VStack(alignment: .leading, spacing: 8) {
                Text(lastSyncedWorkoutTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(GameBoyPalette.darkest)
                Text(detail)
                    .font(.caption2.monospaced())
                    .foregroundStyle(GameBoyPalette.mediumDark)
            }
        }
    }
}

private struct WatchRewardSection: View {
    let reward: RunRewardSummary
    let hatchBurstScale: CGFloat

    var body: some View {
        GameSurface(title: "생성 결과", compact: true) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    ZStack {
                        HatchBurstView(accent: reward.pet.accentColor, pet: reward.pet, scale: hatchBurstScale)
                        PixelPetView(pet: reward.pet, pixelSize: 5)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(reward.pet.displayName)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(GameBoyPalette.darkest)
                            .lineLimit(1)
                        Text(reward.flavorText)
                            .font(.caption2.monospaced())
                            .foregroundStyle(GameBoyPalette.mediumDark)
                            .lineLimit(2)
                    }
                }

                HStack {
                    TraitChip(label: reward.coreLabel, accent: reward.pet.accentColor)
                    TraitChip(label: "+\(reward.experience) XP", accent: .green)
                }

                Text("Completed quests \(reward.completedQuestCount)")
                    .font(.caption2.monospaced())
                    .foregroundStyle(GameBoyPalette.mediumDark)
            }
        }
    }
}

private struct WatchRuntimeAlertBanner: View {
    let alert: WatchRuntimeAlert

    private var accent: Color {
        switch alert.kind {
        case .goal:
            .orange
        case .reward:
            .green
        case .rare:
            .mint
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(accent)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(alert.title)
                    .font(.caption2.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.darkest)
                Text(alert.detail)
                    .font(.caption2.monospaced())
                    .foregroundStyle(GameBoyPalette.mediumDark)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(GameBoyPalette.lightest)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(GameBoyPalette.darkest, lineWidth: 1)
                )
        )
    }
}

#Preview {
    WatchDashboardView()
}
