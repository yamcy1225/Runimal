import RunimalCore
import SwiftUI

struct WatchDashboardView: View {
    @State private var runSessionManager = WatchRunSessionManager()
    @State private var connectivityManager = WatchConnectivityManager()

    private var livePet: GeneratedPet {
        runSessionManager.livePet
    }

    private var growthRatio: Double {
        min(max(runSessionManager.latestSnapshot.distanceMeters / 5000, 0.08), 1)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                GameSurface {
                    VStack(spacing: 10) {
                        Text(runSessionManager.sessionStateLabel == "running" ? "Run Live" : "Trace Egg")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.7))

                        PixelPetView(pet: livePet, pixelSize: 8)

                        VStack(spacing: 4) {
                            Text(livePet.displayName)
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                            Text(livePet.subtitle)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.75))
                        }

                        ProgressView(value: growthRatio)
                            .tint(livePet.accentColor)

                        Text(runSessionManager.sessionStateLabel == "running" ? "달릴수록 펫 오라가 바뀝니다" : "러닝을 시작하면 펫이 깨어납니다")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.72))
                            .multilineTextAlignment(.center)
                    }
                }

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
                    }
                }

                if let reward = runSessionManager.lastReward {
                    GameSurface(title: "Hatch Result") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                PixelPetView(pet: reward.pet, pixelSize: 6)

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
                .tint(livePet.accentColor)

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
                colors: [.black, livePet.accentColor.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .task {
            connectivityManager.activate()
        }
        .onChange(of: runSessionManager.latestSnapshot) { _, snapshot in
            connectivityManager.send(snapshot: snapshot)
        }
        .onChange(of: runSessionManager.lastReward) { _, reward in
            guard let reward else { return }
            connectivityManager.send(reward: reward)
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
