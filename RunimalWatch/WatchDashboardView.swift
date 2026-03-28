import RunimalCore
import SwiftUI

struct WatchDashboardView: View {
    @State private var runSessionManager = WatchRunSessionManager()
    @State private var connectivityManager = WatchConnectivityManager()
    @State private var hatchBurstScale: CGFloat = 0.9
    @State private var countdownValue: Int?

    private var livePet: GeneratedPet {
        runSessionManager.livePet
    }

    private var stageAccent: Color {
        switch liveFeedback.label {
        case "Rare Window":
            return .mint
        case "Surge":
            return .orange
        case "Stable":
            return livePet.accentColor
        case "Recover":
            return .yellow
        default:
            return livePet.accentColor.opacity(0.82)
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
            livePet: livePet,
            sessionShell: runSessionManager.sessionShell,
            stageAccent: stageAccent,
            sessionStateLabel: runSessionManager.sessionStateLabel,
            syncStatusLabel: connectivityManager.syncStatusLabel,
            heartResonance: heartResonance,
            growthRatio: growthRatio,
            latestSnapshot: runSessionManager.latestSnapshot,
            liveFeedback: liveFeedback,
            stageBadges: stageBadges,
            liveGoals: liveGoals,
            primaryGoalDetail: primaryGoal?.detail ?? liveFeedback.detail,
            lastSyncedWorkoutTitle: connectivityManager.lastSyncedWorkoutTitle,
            activationStateLabel: connectivityManager.activationStateLabel,
            authorizationStatus: runSessionManager.authorizationStatus,
            locationStatusLabel: runSessionManager.locationStatusLabel,
            lastSavedWorkoutLabel: runSessionManager.lastSavedWorkoutLabel,
            queuedTransferCount: connectivityManager.queuedTransferCount,
            recentEvents: Array((runSessionManager.recentSessionEvents + connectivityManager.recentEvents).prefix(4)),
            reward: runSessionManager.lastReward,
            hatchBurstScale: hatchBurstScale,
            countdownValue: countdownValue,
            onStartRun: startRunWithCountdown,
            onEndRun: endRun,
            onRequestAuthorization: requestAuthorization
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
            LinearGradient(
                colors: [.black, stageAccent.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .task {
            connectivityManager.activate()
            runSessionManager.autoplayDemoIfNeeded()
        }
        .onChange(of: connectivityManager.claimedRewardIDs) { _, rewardIDs in
            let context = CompanionEffectContext(
                claimedRewardIDs: Array(rewardIDs).sorted(),
                activeEffects: connectivityManager.activeEffects
            )
            runSessionManager.applyCompanionContext(context)
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

    private func requestAuthorization() {
        Task {
            await runSessionManager.requestAuthorization()
        }
    }
}

private struct WatchDashboardPages: View {
    let runtimeAlert: WatchRuntimeAlert?
    let livePet: GeneratedPet
    let sessionShell: EggShellType
    let stageAccent: Color
    let sessionStateLabel: String
    let syncStatusLabel: String
    let heartResonance: Double
    let growthRatio: Double
    let latestSnapshot: LiveRunSnapshot
    let liveFeedback: LiveRunFeedback
    let stageBadges: [String]
    let liveGoals: [LiveGoalTarget]
    let primaryGoalDetail: String
    let lastSyncedWorkoutTitle: String
    let activationStateLabel: String
    let authorizationStatus: String
    let locationStatusLabel: String
    let lastSavedWorkoutLabel: String
    let queuedTransferCount: Int
    let recentEvents: [SyncDiagnosticEvent]
    let reward: RunRewardSummary?
    let hatchBurstScale: CGFloat
    let countdownValue: Int?
    let onStartRun: () -> Void
    let onEndRun: () -> Void
    let onRequestAuthorization: () -> Void

    var body: some View {
        TabView {
            WatchSingleCardPage {
                VStack(spacing: 10) {
                    if let runtimeAlert {
                        WatchRuntimeAlertBanner(alert: runtimeAlert)
                    }

                    WatchCompanionHeroCard(
                        pet: livePet,
                        sessionShell: sessionShell,
                        accent: stageAccent,
                        sessionStateLabel: sessionStateLabel,
                        syncStatusLabel: syncStatusLabel,
                        heartResonance: heartResonance,
                        progress: growthRatio
                    )
                }
            }
            .tag(0)

            WatchSingleCardPage {
                WatchRunStatsPanel(
                    snapshot: latestSnapshot,
                    accent: stageAccent
                )
            }
            .tag(1)

            WatchSingleCardPage {
                VStack(spacing: 10) {
                    Button(sessionStateLabel == "running" ? "운동 끝내기" : "러닝 시작하기") {
                        if sessionStateLabel == "running" {
                            onEndRun()
                        } else {
                            onStartRun()
                        }
                    }
                        .buttonStyle(.borderedProminent)
                        .tint(stageAccent)
                        .disabled(countdownValue != nil)

                    if authorizationStatus != "authorized" {
                        Button("센서 연결", action: onRequestAuthorization)
                            .buttonStyle(.bordered)
                        }
                }
            }
            .tag(2)

            WatchSingleCardPage {
                WatchRunPulseCard(
                    feedback: liveFeedback,
                    accent: stageAccent,
                    badges: Array(stageBadges.prefix(2))
                )
            }
            .tag(3)

            WatchSingleCardPage {
                WatchGoalTrackCard(
                    goals: liveGoals,
                    accent: stageAccent
                )
            }
            .tag(4)

            if sessionStateLabel == "running" {
                WatchSingleCardPage {
                    WatchRunningGoalSection(
                        lastSyncedWorkoutTitle: lastSyncedWorkoutTitle,
                        detail: primaryGoalDetail
                    )
                }
                .tag(5)
            }

            WatchSingleCardPage {
                WatchConnectivitySection(
                    activationStateLabel: activationStateLabel,
                    authorizationStatus: authorizationStatus,
                    locationStatusLabel: locationStatusLabel,
                    lastSavedWorkoutLabel: lastSavedWorkoutLabel,
                    stageBadges: stageBadges,
                    stageAccent: stageAccent
                )
            }
            .tag(6)

            WatchSingleCardPage {
                WatchDiagnosticsSection(
                    activationStateLabel: activationStateLabel,
                    queuedTransferCount: queuedTransferCount,
                    lastSavedWorkoutLabel: lastSavedWorkoutLabel,
                    recentEvents: recentEvents
                )
            }
            .tag(7)

            if let reward {
                WatchSingleCardPage {
                    WatchRewardSection(
                        reward: reward,
                        hatchBurstScale: hatchBurstScale
                    )
                }
                .tag(8)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
    }
}

private struct WatchRunCountdownOverlay: View {
    let value: Int
    let accent: Color

    var body: some View {
        ZStack {
            Color.black.opacity(0.78)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Text("\(value)")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("러닝 시작")
                    .font(.caption.weight(.black))
                    .foregroundStyle(accent)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(accent.opacity(0.44), lineWidth: 1.5)
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
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.68))
            }
        }
    }
}

private struct WatchConnectivitySection: View {
    let activationStateLabel: String
    let authorizationStatus: String
    let locationStatusLabel: String
    let lastSavedWorkoutLabel: String
    let stageBadges: [String]
    let stageAccent: Color

    var body: some View {
        GameSurface(title: "연결 정보", compact: true) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Sync \(activationStateLabel) · HealthKit \(authorizationStatus)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.72))
                Text("Route \(locationStatusLabel) · \(lastSavedWorkoutLabel)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.65))
                if stageBadges.isEmpty == false {
                    Text(stageBadges.joined(separator: " · "))
                        .font(.caption2)
                        .foregroundStyle(stageAccent.opacity(0.9))
                }
            }
        }
    }
}

private struct WatchDiagnosticsSection: View {
    let activationStateLabel: String
    let queuedTransferCount: Int
    let lastSavedWorkoutLabel: String
    let recentEvents: [SyncDiagnosticEvent]

    var body: some View {
        GameSurface(title: "진단", compact: true) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Link \(activationStateLabel) · Queue \(queuedTransferCount) · Save \(lastSavedWorkoutLabel)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(2)

                ForEach(recentEvents.prefix(3)) { event in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.title)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text(event.detail)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.62))
                            .lineLimit(2)
                    }
                }
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
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text(reward.flavorText)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.72))
                            .lineLimit(2)
                    }
                }

                HStack {
                    TraitChip(label: reward.coreLabel, accent: reward.pet.accentColor)
                    TraitChip(label: "+\(reward.experience) XP", accent: .green)
                }

                Text("Completed quests \(reward.completedQuestCount)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.72))
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
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white)
                Text(alert.detail)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(accent.opacity(0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(accent.opacity(0.32), lineWidth: 1)
                )
        )
    }
}

#Preview {
    WatchDashboardView()
}
