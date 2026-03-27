import RunimalCore
import SwiftUI

struct WatchDashboardView: View {
    @State private var runSessionManager = WatchRunSessionManager()
    @State private var connectivityManager = WatchConnectivityManager()
    @State private var hatchBurstScale: CGFloat = 0.9

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

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                WatchRunPulseCard(
                    feedback: liveFeedback,
                    accent: stageAccent,
                    badges: Array(stageBadges.prefix(2))
                )

                WatchGoalTrackCard(
                    goals: liveGoals,
                    accent: stageAccent
                )

                GameSurface {
                    VStack(spacing: 10) {
                        Text(runSessionManager.sessionStateLabel == "running" ? "Run Live" : "Trace Egg")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.7))

                        ZStack {
                            Circle()
                                .fill(stageAccent.opacity(0.20))
                                .frame(width: 94, height: 94)
                                .blur(radius: 10)

                            Circle()
                                .stroke(stageAccent.opacity(liveFeedback.intensity > 0.8 ? 0.9 : 0.45), lineWidth: 3)
                                .frame(width: 80, height: 80)
                                .scaleEffect(liveFeedback.intensity > 0.8 ? 1.08 : 1)

                            Circle()
                                .stroke(.white.opacity(0.16), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                                .frame(width: 92, height: 92)

                            PixelPetView(pet: livePet, pixelSize: 8)
                        }

                        VStack(spacing: 4) {
                            Text(livePet.displayName)
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                            Text(livePet.subtitle)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.75))
                        }

                        RunimalProgressBar(progress: growthRatio, accent: stageAccent, height: 8)

                        Text(runSessionManager.sessionStateLabel == "running" ? liveFeedback.headline : "러닝을 시작하면 펫이 깨어납니다")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.72))
                            .multilineTextAlignment(.center)

                        if stageBadges.isEmpty == false {
                            HStack(spacing: 6) {
                                ForEach(Array(stageBadges.prefix(2).enumerated()), id: \.offset) { _, badge in
                                    TraitChip(label: badge, accent: stageAccent.opacity(0.82))
                                }
                            }
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [stageAccent.opacity(0.22), .clear],
                                center: .center,
                                startRadius: 8,
                                endRadius: 120
                            )
                        )
                )

                GameSurface(title: "Live Metrics") {
                    HStack {
                        metric("m", "\(Int(runSessionManager.latestSnapshot.distanceMeters))")
                        metric("spm", "\(runSessionManager.latestSnapshot.cadence ?? 0)")
                        metric("hr", "\(Int(runSessionManager.latestSnapshot.currentHeartRate ?? 0))")
                    }
                }

                GameSurface(title: "Run Plan") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(connectivityManager.lastSyncedWorkoutTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Sync \(connectivityManager.activationStateLabel) · HealthKit \(runSessionManager.authorizationStatus)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.72))
                        Text("Route \(runSessionManager.locationStatusLabel) · \(runSessionManager.lastSavedWorkoutLabel)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.65))
                        Text(liveFeedback.detail)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.62))
                        if stageBadges.isEmpty == false {
                            Text(stageBadges.joined(separator: " · "))
                                .font(.caption2)
                                .foregroundStyle(stageAccent.opacity(0.9))
                        }
                    }
                }

                GameSurface(title: "Diagnostics") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Link \(connectivityManager.activationStateLabel) · Queue \(connectivityManager.queuedTransferCount) · Save \(runSessionManager.lastSavedWorkoutLabel)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.72))

                        ForEach(Array((runSessionManager.recentSessionEvents + connectivityManager.recentEvents).prefix(4))) { event in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.title)
                                    .foregroundStyle(.white)
                                Text(event.detail)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.62))
                            }
                        }
                    }
                }

                if let reward = runSessionManager.lastReward {
                    GameSurface(title: "Hatch Result") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                ZStack {
                                    HatchBurstView(accent: reward.pet.accentColor, pet: reward.pet, scale: hatchBurstScale)
                                    PixelPetView(pet: reward.pet, pixelSize: 6)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(reward.pet.displayName)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    Text(reward.flavorText)
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.72))
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
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
                }

                Button(runSessionManager.sessionStateLabel == "running" ? "Finish Run" : "Start Run") {
                    Task {
                        if runSessionManager.sessionStateLabel == "running" {
                            await runSessionManager.endRun()
                        } else {
                            await runSessionManager.startRun()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(stageAccent)

                Button("Authorize HealthKit") {
                    Task {
                        await runSessionManager.requestAuthorization()
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
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

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    WatchDashboardView()
}
