import RunimalCore
import SwiftUI
import ImageIO
import UniformTypeIdentifiers

struct WatchDashboardView: View {
    let captureScenario: WatchUICaptureScenario?
    @State private var runSessionManager = WatchRunSessionManager()
    @State private var connectivityManager = WatchConnectivityManager.shared
    @State private var displayedMainCompanionContext: WatchMainCompanionContext?
    @State private var offlineMapCatalog = WatchOfflineMapPackCatalog()
    @State private var hatchBurstScale: CGFloat = 0.9
    @State private var countdownValue: Int?
    @State private var selectedPage = 0
    @State private var captureViewportProfile = WatchViewportProfile.resolve(containerSize: CGSize(width: 211, height: 257))

    init(captureScenario: WatchUICaptureScenario? = nil) {
        self.captureScenario = captureScenario
    }

    private var mainCompanionContext: WatchMainCompanionContext? {
        connectivityManager.mainCompanionContext ?? displayedMainCompanionContext
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

    var body: some View {
        GeometryReader { proxy in
            WatchDashboardPages(
                runtimeAlert: runSessionManager.runtimeAlert,
                mainCompanionContext: mainCompanionContext,
                stageAccent: stageAccent,
                sessionStateLabel: runSessionManager.sessionStateLabel,
                heartResonance: heartResonance,
                growthRatio: growthRatio,
                latestSnapshot: runSessionManager.latestSnapshot,
                latestGPSAccuracyMeters: runSessionManager.latestGPSAccuracyMeters,
                gpsLastUpdatedAt: runSessionManager.gpsLastUpdatedAt,
                locationStatusLabel: runSessionManager.locationStatusLabel,
                liveFeedback: liveFeedback,
                mutationReaction: runSessionManager.mutationReaction,
                liveInteractionPreview: runSessionManager.liveInteractionPreview,
                stageBadges: stageBadges,
                offlineMapPacks: offlineMapCatalog.packs,
                selectedOfflineMapPackID: offlineMapCatalog.selectedPackID,
                storedOfflineMapPackIDs: connectivityManager.offlineMapStorage.storedPackIDs,
                offlineMapStorage: connectivityManager.offlineMapStorage,
                routePreview: runSessionManager.liveRoutePreview,
                reward: runSessionManager.lastReward,
                interactionSummaryLabel: runSessionManager.liveInteractionBonusLabel,
                pendingHomeBonusLabel: runSessionManager.pendingHomeBonusLabel,
                hatchBurstScale: hatchBurstScale,
                countdownValue: countdownValue,
                showsAuxiliaryPages: captureScenario == nil,
                selectedPage: $selectedPage,
                onRefreshCompanion: captureScenario == nil ? connectivityManager.refreshMainCompanionContext : {},
                onStartRun: startRunWithCountdown,
                onEndRun: endRun,
                onCompanionInteraction: runSessionManager.registerCompanionInteraction
            )
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .ignoresSafeArea()
        .task {
            if let captureScenario {
                applyCaptureScenario(captureScenario)
                exportCaptureIfRequested()
                return
            }

            runSessionManager.setAutoPauseEnabled(connectivityManager.autoPauseEnabled)
            runSessionManager.prepareGPSPreview()
            displayedMainCompanionContext = connectivityManager.resolvedMainCompanionContext()
            runSessionManager.applyMainCompanionContext(mainCompanionContext)
            offlineMapCatalog.replace(
                with: connectivityManager.offlineMapPacks,
                selectedPackID: connectivityManager.selectedOfflineMapPackID
            )
            connectivityManager.offlineMapStorage.reloadFromDisk()
            runSessionManager.autoplayDemoIfNeeded()
        }
        .onChange(of: connectivityManager.claimedRewardIDs) { _, rewardIDs in
            let context = CompanionEffectContext(
                claimedRewardIDs: Array(rewardIDs).sorted(),
                activeEffects: connectivityManager.activeEffects
            )
            runSessionManager.applyCompanionContext(context)
        }
        .onChange(of: connectivityManager.mainCompanionContext) { _, context in
            guard let context else { return }
            displayedMainCompanionContext = context
        }
        .onChange(of: mainCompanionContext) { _, context in
            runSessionManager.applyMainCompanionContext(context)
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
    let heartResonance: Double
    let growthRatio: Double
    let latestSnapshot: LiveRunSnapshot
    let latestGPSAccuracyMeters: Double?
    let gpsLastUpdatedAt: Date?
    let locationStatusLabel: String
    let liveFeedback: LiveRunFeedback
    let mutationReaction: MutationRuntimeReactionSnapshot?
    let liveInteractionPreview: LiveCompanionInteractionPreview
    let stageBadges: [String]
    let offlineMapPacks: [OfflineMapPackSummary]
    let selectedOfflineMapPackID: String?
    let storedOfflineMapPackIDs: Set<String>
    let offlineMapStorage: WatchOfflineMapPackStorage
    let routePreview: [RoutePoint]
    let reward: RunRewardSummary?
    let interactionSummaryLabel: String?
    let pendingHomeBonusLabel: String?
    let hatchBurstScale: CGFloat
    let countdownValue: Int?
    let showsAuxiliaryPages: Bool
    @Binding var selectedPage: Int
    let onRefreshCompanion: () -> Void
    let onStartRun: () -> Void
    let onEndRun: () -> Void
    let onCompanionInteraction: (WatchCompanionInteractionStyle) -> WatchInteractionAwardFeedback?

    var body: some View {
        WatchPager(
            pages: pageViews,
            selectedPage: $selectedPage
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onChange(of: pageViews.count) { _, count in
            guard count > 0 else { return }
            selectedPage = min(max(selectedPage, 0), count - 1)
        }
    }

    private var pageViews: [AnyView] {
        var pages: [AnyView] = [
            AnyView(
                WatchSingleCardPage(runtimePageIndex: 0) {
                ZStack(alignment: .top) {
                    WatchLaunchPageCard(
                        companion: mainCompanionContext,
                        accent: stageAccent,
                        sessionStateLabel: sessionStateLabel,
                        heartResonance: heartResonance,
                        gpsAccuracyMeters: latestGPSAccuracyMeters,
                        lastGPSUpdateAt: gpsLastUpdatedAt,
                        locationStatusLabel: locationStatusLabel,
                        mutationReaction: mutationReaction,
                        countdownValue: countdownValue,
                        interactionSummaryLabel: interactionSummaryLabel,
                        pendingHomeBonusLabel: pendingHomeBonusLabel,
                        onPrimaryAction: sessionStateLabel == "running" ? onEndRun : onStartRun,
                        onRefreshCompanion: onRefreshCompanion,
                        onCompanionInteraction: onCompanionInteraction
                    )
                    .padding(.top, runtimeAlert == nil ? 0 : 24)

                    if let runtimeAlert {
                        WatchRuntimeAlertBanner(alert: runtimeAlert)
                            .padding(.horizontal, 4)
                    }
                }
            }
            ),
            AnyView(
                WatchSingleCardPage(runtimePageIndex: 1) {
                WatchRunStatsPanel(
                    snapshot: latestSnapshot,
                    gpsAccuracyMeters: latestGPSAccuracyMeters,
                    lastGPSUpdateAt: gpsLastUpdatedAt,
                    locationStatusLabel: locationStatusLabel,
                    interactionPreview: liveInteractionPreview,
                    companion: mainCompanionContext,
                    accent: stageAccent
                )
            }
            ),
            AnyView(
                WatchSingleCardPage(runtimePageIndex: 2) {
                WatchRunPulseCard(
                    feedback: liveFeedback,
                    accent: stageAccent,
                    interactionPreview: liveInteractionPreview,
                    companion: mainCompanionContext,
                    badges: Array(stageBadges.prefix(2)),
                    reaction: mutationReaction,
                    interactionBonusLabel: interactionSummaryLabel
                )
            }
            )
        ]

        if showsAuxiliaryPages, let reward {
            pages.append(
                AnyView(
                    WatchSingleCardPage(runtimePageIndex: 3) {
                        WatchRewardSection(
                            reward: reward,
                            hatchBurstScale: hatchBurstScale
                        )
                    }
                )
            )
        }

        return pages
    }

    private var selectedOfflineMapPack: OfflineMapPackSummary? {
        guard let selectedOfflineMapPackID else { return offlineMapPacks.first }
        return offlineMapPacks.first(where: { $0.id == selectedOfflineMapPackID }) ?? offlineMapPacks.first
    }
}

private struct WatchPager: View {
    let pages: [AnyView]
    @Binding var selectedPage: Int

    var body: some View {
        GeometryReader { proxy in
            let count = max(pages.count, 1)
            let clampedSelection = min(max(selectedPage, 0), count - 1)
            let currentPage = pages[clampedSelection]

            ZStack {
                currentPage
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .id(clampedSelection)
                    .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                    .animation(.spring(response: 0.28, dampingFraction: 0.88), value: clampedSelection)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 3, coordinateSpace: .local)
                    .onEnded { value in
                        guard abs(value.translation.width) > abs(value.translation.height) else { return }
                        let width = max(proxy.size.width, 1)
                        let projectedProgress = -value.predictedEndTranslation.width / width
                        let translationProgress = -value.translation.width / width
                        let progress = abs(projectedProgress) > abs(translationProgress) ? projectedProgress : translationProgress
                        let threshold: CGFloat = 0.07

                        if progress > threshold {
                            selectedPage = min(clampedSelection + 1, count - 1)
                        } else if progress < -threshold {
                            selectedPage = max(clampedSelection - 1, 0)
                        }
                    },
                including: .all
            )
        }
    }

}

private extension WatchDashboardView {
    func applyCaptureScenario(_ scenario: WatchUICaptureScenario) {
        captureViewportProfile = WatchViewportProfile.resolve(
            containerSize: CGSize(width: 211, height: 257),
            captureDeviceName: ProcessInfo.processInfo.environment["RUNIMAL_WATCH_CAPTURE_DEVICE_NAME"]
        )
        let companionContext = WatchUICaptureFixtures.companionContext
        displayedMainCompanionContext = companionContext
        connectivityManager.mainCompanionContext = companionContext
        connectivityManager.activeEffects = WatchUICaptureFixtures.activeEffects
        connectivityManager.claimedRewardIDs = ["weekly-badge", "growth-feed"]
        connectivityManager.autoPauseEnabled = true

        runSessionManager.applyCompanionContext(
            CompanionEffectContext(
                claimedRewardIDs: Array(connectivityManager.claimedRewardIDs).sorted(),
                activeEffects: WatchUICaptureFixtures.activeEffects
            )
        )
        runSessionManager.applyMainCompanionContext(companionContext)

        switch scenario {
        case .dashboard:
            selectedPage = 0
        case .runningCompanion:
            selectedPage = 0
        case .runningMetrics:
            selectedPage = 1
        case .runningPulse:
            selectedPage = 2
        }

        runSessionManager.applyCaptureScenario(scenario)
    }

    func exportCaptureIfRequested() {
        guard let outputPath = ProcessInfo.processInfo.environment["RUNIMAL_WATCH_UI_CAPTURE_OUTPUT_PATH"],
              outputPath.isEmpty == false else {
            return
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))

            let renderView = WatchDashboardCaptureRootView(
                runtimeAlert: runSessionManager.runtimeAlert,
                mainCompanionContext: mainCompanionContext,
                stageAccent: stageAccent,
                sessionStateLabel: runSessionManager.sessionStateLabel,
                heartResonance: heartResonance,
                growthRatio: growthRatio,
                latestSnapshot: runSessionManager.latestSnapshot,
                latestGPSAccuracyMeters: runSessionManager.latestGPSAccuracyMeters,
                gpsLastUpdatedAt: runSessionManager.gpsLastUpdatedAt,
                locationStatusLabel: runSessionManager.locationStatusLabel,
                liveFeedback: liveFeedback,
                mutationReaction: runSessionManager.mutationReaction,
                liveInteractionPreview: runSessionManager.liveInteractionPreview,
                stageBadges: stageBadges,
                reward: runSessionManager.lastReward,
                interactionSummaryLabel: runSessionManager.liveInteractionBonusLabel,
                pendingHomeBonusLabel: runSessionManager.pendingHomeBonusLabel,
                hatchBurstScale: hatchBurstScale,
                countdownValue: countdownValue,
                selectedPage: selectedPage,
                captureProfile: captureViewportProfile
            )
            .frame(
                width: captureViewportProfile.captureCanvasSize.width,
                height: captureViewportProfile.captureCanvasSize.height
            )

            let renderer = ImageRenderer(content: renderView)
            renderer.scale = 2

            guard let cgImage = renderer.cgImage else { return }

            let url = URL(fileURLWithPath: outputPath)
            try? FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true,
                attributes: nil
            )

            guard let destination = CGImageDestinationCreateWithURL(
                url as CFURL,
                UTType.png.identifier as CFString,
                1,
                nil
            ) else {
                return
            }

            CGImageDestinationAddImage(destination, cgImage, nil)
            CGImageDestinationFinalize(destination)
        }
    }
}

private struct WatchDashboardCaptureRootView: View {
    let runtimeAlert: WatchRuntimeAlert?
    let mainCompanionContext: WatchMainCompanionContext?
    let stageAccent: Color
    let sessionStateLabel: String
    let heartResonance: Double
    let growthRatio: Double
    let latestSnapshot: LiveRunSnapshot
    let latestGPSAccuracyMeters: Double?
    let gpsLastUpdatedAt: Date?
    let locationStatusLabel: String
    let liveFeedback: LiveRunFeedback
    let mutationReaction: MutationRuntimeReactionSnapshot?
    let liveInteractionPreview: LiveCompanionInteractionPreview
    let stageBadges: [String]
    let reward: RunRewardSummary?
    let interactionSummaryLabel: String?
    let pendingHomeBonusLabel: String?
    let hatchBurstScale: CGFloat
    let countdownValue: Int?
    let selectedPage: Int
    let captureProfile: WatchViewportProfile

    var body: some View {
        WatchSingleCardPage(captureProfile: captureProfile) {
            ZStack(alignment: .top) {
                capturePageContent
                    .padding(.top, selectedPage == 0 && runtimeAlert != nil ? 24 : 0)

                if selectedPage == 0, let runtimeAlert {
                    WatchRuntimeAlertBanner(alert: runtimeAlert)
                        .padding(.horizontal, 4)
                }
            }
        }
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
    }

    @ViewBuilder
    private var capturePageContent: some View {
        switch selectedPage {
        case 0:
            WatchLaunchPageCard(
                companion: mainCompanionContext,
                accent: stageAccent,
                sessionStateLabel: sessionStateLabel,
                heartResonance: heartResonance,
                gpsAccuracyMeters: latestGPSAccuracyMeters,
                lastGPSUpdateAt: gpsLastUpdatedAt,
                locationStatusLabel: locationStatusLabel,
                mutationReaction: mutationReaction,
                countdownValue: countdownValue,
                interactionSummaryLabel: interactionSummaryLabel,
                pendingHomeBonusLabel: pendingHomeBonusLabel,
                onPrimaryAction: {},
                onRefreshCompanion: {},
                onCompanionInteraction: { _ in nil }
            )
        case 1:
            WatchRunStatsPanel(
                snapshot: latestSnapshot,
                gpsAccuracyMeters: latestGPSAccuracyMeters,
                lastGPSUpdateAt: gpsLastUpdatedAt,
                locationStatusLabel: locationStatusLabel,
                interactionPreview: liveInteractionPreview,
                companion: mainCompanionContext,
                accent: stageAccent
            )
        case 2:
            WatchRunPulseCard(
                feedback: liveFeedback,
                accent: stageAccent,
                interactionPreview: liveInteractionPreview,
                companion: mainCompanionContext,
                badges: Array(stageBadges.prefix(2)),
                reaction: mutationReaction,
                interactionBonusLabel: interactionSummaryLabel
            )
        default:
            if let reward {
                WatchRewardSection(
                    reward: reward,
                    hatchBurstScale: hatchBurstScale
                )
            } else {
                WatchLaunchPageCard(
                    companion: mainCompanionContext,
                    accent: stageAccent,
                    sessionStateLabel: sessionStateLabel,
                    heartResonance: heartResonance,
                    gpsAccuracyMeters: latestGPSAccuracyMeters,
                    lastGPSUpdateAt: gpsLastUpdatedAt,
                    locationStatusLabel: locationStatusLabel,
                    mutationReaction: mutationReaction,
                    countdownValue: countdownValue,
                    interactionSummaryLabel: interactionSummaryLabel,
                    pendingHomeBonusLabel: pendingHomeBonusLabel,
                    onPrimaryAction: {},
                    onRefreshCompanion: {},
                    onCompanionInteraction: { _ in nil }
                )
            }
        }
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
    let captureProfile: WatchViewportProfile?
    let runtimePageIndex: Int?
    @ViewBuilder let content: Content

    init(
        captureProfile: WatchViewportProfile? = nil,
        runtimePageIndex: Int? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.captureProfile = captureProfile
        self.runtimePageIndex = runtimePageIndex
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            let isCapture = captureProfile != nil
            let profile = captureProfile ?? WatchViewportProfile.resolve(containerSize: proxy.size)
            let baseRect = isCapture
                ? profile.visibleRect(in: proxy.size)
                : profile.runtimeRect(in: proxy.size)
            let frameRect = adjustedRect(
                from: baseRect,
                in: proxy.size,
                isCapture: isCapture
            )

            ZStack(alignment: .topLeading) {
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .frame(width: frameRect.width, height: frameRect.height, alignment: .topLeading)
                    .offset(x: frameRect.minX, y: frameRect.minY)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private func adjustedRect(from rect: CGRect, in size: CGSize, isCapture: Bool) -> CGRect {
        guard isCapture == false,
              let runtimePageIndex,
              runtimePageIndex > 0 else {
            return rect
        }

        let shiftedX = min(max(rect.minX - 1, 0), max(size.width - rect.width, 0))
        let shiftedY = min(max(rect.minY + 5, 0), max(size.height - rect.height, 0))
        return CGRect(x: shiftedX, y: shiftedY, width: rect.width, height: rect.height)
    }
}

private struct WatchRewardSection: View {
    let reward: RunRewardSummary
    let hatchBurstScale: CGFloat

    var body: some View {
        GameSurface(title: "생성 결과", compact: true, showsFrameChrome: false) {
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
                .frame(width: 6, height: 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(alert.title)
                    .font(.caption2.monospaced().weight(.black))
                    .foregroundStyle(GameBoyPalette.darkest)
                    .lineLimit(1)
                Text(alert.detail)
                    .font(.caption2.monospaced())
                    .foregroundStyle(GameBoyPalette.mediumDark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
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
