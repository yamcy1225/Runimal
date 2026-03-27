import RunimalCore
import SwiftUI

struct PhoneHomeView: View {
    let store: PhoneDashboardStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                heroCard
                PhoneRewardStagePanel(
                    pet: store.pet,
                    progress: store.evolutionProgress,
                    activeEffects: store.activeWeeklyEffects,
                    season: store.weeklyBoard.season,
                    claimableReward: store.claimableWeeklyReward,
                    onClaim: store.claimableWeeklyReward == nil ? nil : { store.claimWeeklyReward() }
                )
                PhoneWeeklyBoardPanel(
                    board: store.weeklyBoard,
                    accent: store.pet.accentColor,
                    claimedRewardIDs: store.claimedWeeklyRewardIDs,
                    activeEffects: store.activeWeeklyEffects
                )
                PhoneVaultPanel(
                    statusLabel: store.vault.statusLabel,
                    lastSyncedAt: store.vault.lastSyncedAt
                )
                PhoneSeasonEconomyPanel(
                    board: store.seasonEconomyBoard,
                    onClaim: store.claimSeasonReward
                )
                questCard
                workoutCard
                syncCard
                PhoneDiagnosticsPanel(
                    events: store.connectivity.recentEvents,
                    reachabilityLabel: store.connectivity.reachabilityLabel,
                    activationStateLabel: store.connectivity.activationStateLabel,
                    queuedTransferCount: store.connectivity.queuedTransferCount
                )
                if !store.hatchInsights.isEmpty {
                    PhoneHatchInsightPanel(
                        insights: store.hatchInsights,
                        target: store.evolutionTarget,
                        accent: store.pet.accentColor
                    )
                }
                if let latestCompletedRun = store.latestCompletedRun {
                    recentRunCard(latestCompletedRun)
                }
            }
            .padding(20)
        }
    }

    private var heroCard: some View {
        GameSurface {
            VStack(alignment: .leading, spacing: 14) {
                Text("Today’s Hatch")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.75))

                HStack(alignment: .center, spacing: 16) {
                    PixelPetView(pet: store.pet, pixelSize: 12)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(store.pet.displayName)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                        Text(store.pet.subtitle)
                            .foregroundStyle(.white.opacity(0.76))

                        HStack {
                            TraitChip(label: "\(store.summary.distanceKm.formatted(.number.precision(.fractionLength(1)))) km", accent: store.pet.accentColor)
                            TraitChip(label: "\(store.summary.cadence) spm", accent: .white.opacity(0.3))
                            TraitChip(label: store.evolutionProgress.stageLabel, accent: .white.opacity(0.22))
                        }

                        RunimalProgressBar(progress: store.evolutionProgress.progressRatio, accent: store.pet.accentColor, height: 8)

                        Text(store.pet.explanation.first ?? "")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }
            }
        }
    }

    private var questCard: some View {
        GameSurface(title: "Growth Route") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(store.quests, id: \.label) { quest in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(quest.label)
                                .foregroundStyle(.white)
                            Text(quest.detail)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        Spacer()
                        TraitChip(
                            label: quest.completed ? "CLEAR" : "PENDING",
                            accent: quest.completed ? .green : .orange
                        )
                    }
                }
            }
        }
    }

    private var workoutCard: some View {
        GameSurface(title: "Suggested Run") {
            VStack(alignment: .leading, spacing: 10) {
                Text(store.suggestedWorkout.title.capitalized)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(store.suggestedWorkout.summary)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
                HStack {
                    TraitChip(label: "\(store.suggestedWorkout.scheduledDistanceKm.formatted()) km", accent: store.pet.accentColor)
                    TraitChip(label: store.suggestedWorkout.targetPaceBand, accent: .white.opacity(0.25))
                }

                HStack {
                    Button("Authorize HealthKit") {
                        Task { await store.requestHealthAuthorization() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(store.pet.accentColor)

                    Button("Send To Watch") {
                        Task { await store.syncWorkoutPlan() }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var syncCard: some View {
        GameSurface(title: "Companion Link") {
            VStack(alignment: .leading, spacing: 8) {
                Text("HealthKit \(store.healthKit.authorizationStatus)")
                    .foregroundStyle(.white)
                Text("WatchConnectivity \(store.connectivity.activationStateLabel) · \(store.connectivity.reachabilityLabel)")
                    .foregroundStyle(.white.opacity(0.76))

                if let snapshot = store.connectivity.lastSnapshot {
                    Text("Latest watch trace: \(Int(snapshot.distanceMeters))m · \(snapshot.cadence ?? 0) spm")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.72))
                } else {
                    Text(store.connectivity.lastMessage)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.72))
                }

                if let reward = store.connectivity.lastReward {
                    Divider()
                        .overlay(.white.opacity(0.14))

                    HStack(alignment: .center, spacing: 12) {
                        PixelPetView(pet: reward.pet, pixelSize: 6)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Latest Hatch Reward")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.78))
                            Text("\(reward.pet.displayName) · \(reward.coreLabel)")
                                .foregroundStyle(.white)
                            Text(reward.flavorText)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.68))
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.7, dampingFraction: 0.85), value: store.connectivity.lastReward != nil)
    }

    private func recentRunCard(_ run: CompletedRunRecord) -> some View {
        GameSurface(title: "Latest Synced Run") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 12) {
                    PixelPetView(pet: run.reward.pet, pixelSize: 7)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(run.reward.pet.displayName)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("\(run.distanceMeters / 1000, format: .number.precision(.fractionLength(2))) km · \(paceLabel(run.averagePaceSeconds))")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.76))
                        Text("\(run.source) · \(run.startedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.62))
                    }
                }

                if !run.route.isEmpty {
                    RoutePreviewShape(points: run.route)
                        .stroke(run.reward.pet.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .frame(height: 94)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                HStack {
                    TraitChip(label: "+\(run.reward.experience) XP", accent: .green)
                    if let cadence = run.cadence {
                        TraitChip(label: "\(cadence) spm", accent: .white.opacity(0.18))
                    }
                    if let averageHeartRate = run.averageHeartRate {
                        TraitChip(label: "\(Int(averageHeartRate)) bpm", accent: .red.opacity(0.4))
                    }
                }
            }
        }
    }

    private func paceLabel(_ seconds: Int?) -> String {
        guard let seconds else { return "pace --" }
        let minutes = seconds / 60
        return "\(minutes):\(String(format: "%02d", seconds % 60))/km"
    }
}

private struct RoutePreviewShape: Shape {
    let points: [RoutePoint]

    func path(in rect: CGRect) -> Path {
        guard points.count > 1 else { return Path() }

        let latitudes = points.map(\.latitude)
        let longitudes = points.map(\.longitude)

        guard let minLat = latitudes.min(),
              let maxLat = latitudes.max(),
              let minLon = longitudes.min(),
              let maxLon = longitudes.max() else {
            return Path()
        }

        let latSpan = max(maxLat - minLat, 0.0001)
        let lonSpan = max(maxLon - minLon, 0.0001)
        let insetRect = rect.insetBy(dx: 12, dy: 10)

        func normalizedPoint(_ point: RoutePoint) -> CGPoint {
            let xRatio = (point.longitude - minLon) / lonSpan
            let yRatio = (point.latitude - minLat) / latSpan

            return CGPoint(
                x: insetRect.minX + insetRect.width * xRatio,
                y: insetRect.maxY - insetRect.height * yRatio
            )
        }

        var path = Path()
        path.move(to: normalizedPoint(points[0]))

        for point in points.dropFirst() {
            path.addLine(to: normalizedPoint(point))
        }

        return path
    }
}
