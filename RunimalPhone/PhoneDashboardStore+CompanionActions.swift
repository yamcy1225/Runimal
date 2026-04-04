import RunimalCore

@MainActor
extension PhoneDashboardStore {
    func claimWeeklyReward() {
        guard let reward = claimableWeeklyReward else { return }
        progress.claimWeeklyReward(id: reward.id)
        syncCompanionEffects()
        persistVault()
        telemetry.log(
            "weekly_reward_claimed",
            detail: reward.id,
            properties: [
                "reward_id": reward.id,
                "season_id": weeklyBoard.season.id
            ]
        )
    }

    func activateCompanion(_ companionID: String) {
        progress.activateCompanion(id: companionID)
        syncMainCompanionSelection()
        persistVault()
        telemetry.log("activate_companion", detail: companionID)
    }

    func activateEgg(_ eggID: String) {
        progress.activateEgg(id: eggID)
        syncMainCompanionSelection()
        persistVault()
        telemetry.log("activate_egg", detail: eggID)
    }

    @discardableResult
    func feedActiveCompanion(with runID: String) -> CompanionFeedOutcome? {
        guard let run = completedRuns.first(where: { $0.id == runID }) else { return nil }
        let wasFirstStageUp = hasUnlockedNonTraceStage == false
        latestFeedOutcome = progress.feed(
            run: run,
            to: featuredCompanion,
            activeEffects: activeWeeklyEffects,
            season: weeklyBoard.season
        )
        persistVault()
        if let outcome = latestFeedOutcome {
            if outcome.bonusLabels.contains("단계 맞춤") {
                telemetry.log("signal_lock_applied", detail: "\(run.id):\(outcome.afterProgress.stageLabel)")
            }
            if outcome.stageAdvanced, wasFirstStageUp {
                telemetry.log(
                    "first_stage_up",
                    detail: outcome.afterProgress.stageLabel,
                    properties: [
                        "run_id": run.id,
                        "stage_label": outcome.afterProgress.stageLabel,
                        "companion_id": featuredCompanion.id
                    ]
                )
            }
        }
        syncMainCompanionSelection()
        telemetry.log("feed_companion", detail: run.id)
        return latestFeedOutcome
    }

    @discardableResult
    func forgeEgg(from runID: String) -> EggInventoryEntry? {
        guard let run = completedRuns.first(where: { $0.id == runID }) else { return nil }
        guard progress.eggOpportunity(for: run).eligible else { return nil }
        let wasFirstEgg = eggInventory.isEmpty
        let forgedEgg = progress.forgeEgg(from: run)
        persistVault()
        if let forgedEgg {
            let firstFlag = wasFirstEgg ? "first" : "repeat"
            telemetry.log(
                "egg_created",
                detail: "\(forgedEgg.shell.rawValue):\(firstFlag)",
                properties: [
                    "shell": forgedEgg.shell.rawValue,
                    "creation_kind": firstFlag,
                    "source_run_id": run.id
                ]
            )
        }
        telemetry.log("forge_egg", detail: run.id)
        return forgedEgg
    }

    @discardableResult
    func incubateMainEgg(with runID: String) -> EggInventoryEntry? {
        guard let run = completedRuns.first(where: { $0.id == runID }) else { return nil }
        guard let eggBefore = mainEgg else { return nil }
        let proposedExperience = RunimalEggEngine.incubationExperienceGain(for: run, egg: eggBefore)
        let updatedEgg = progress.incubateMainEgg(with: run)
        persistVault()
        if let updatedEgg, updatedEgg.storedExperience > eggBefore.storedExperience + proposedExperience {
            telemetry.log("decode_lock_applied", detail: "\(updatedEgg.id):\(updatedEgg.shell.rawValue)")
        }
        telemetry.log("incubate_egg", detail: run.id)
        return updatedEgg
    }

    @discardableResult
    func hatchEgg(_ eggID: String) -> PetCollectionEntry? {
        let isFirstHatch = progress.ownedCompanions.contains(where: { $0.id.hasPrefix("hatched-") }) == false
        let companion = progress.hatchEgg(eggID)
        syncMainCompanionSelection()
        persistVault()
        if let companion {
            let hatchDetail = isFirstHatch ? "first:\(companion.pet.species.rawValue)" : companion.pet.species.rawValue
            telemetry.log(
                "egg_hatched",
                detail: hatchDetail,
                properties: [
                    "species": companion.pet.species.rawValue,
                    "is_first_hatch": isFirstHatch ? "true" : "false",
                    "egg_id": eggID
                ]
            )
            if let rareVariant = companion.pet.rareVariant {
                let rareLabel = RareVariantMeta.labels[rareVariant] ?? rareVariant.rawValue
                telemetry.log(
                    "rare_variant_obtained",
                    detail: "\(rareLabel):\(companion.pet.species.rawValue)",
                    properties: [
                        "variant": rareVariant.rawValue,
                        "species": companion.pet.species.rawValue
                    ]
                )
            }
        }
        telemetry.log("hatch_egg", detail: eggID)
        return companion
    }

    func resetProgress() {
        vault.clearSnapshot()
        cloudMirror.clearSnapshot()
        progress.resetProgress(from: runArchive)
        latestFeedOutcome = nil
        persistVault()
        syncCompanionEffects()
        syncMainCompanionSelection()
        telemetry.log("reset_progress", detail: "starter-egg")
    }

    func clearFeedOutcome() {
        latestFeedOutcome = nil
    }

    func retireCompanion(_ companionID: String) {
        guard let offer = retirableOffers.first(where: { $0.companion.id == companionID }) else { return }
        _ = progress.retireCompanion(companionID, essenceReward: offer.essenceReward)
        persistVault()
        telemetry.log("retire_companion", detail: companionID)
    }

    func forgeOption(_ optionID: String) {
        guard let option = forgeOptions.first(where: { $0.id == optionID }) else { return }
        _ = progress.purchaseForgeOption(option)
        persistVault()
        telemetry.log("forge_option", detail: option.id)
    }

    func selectRole(_ role: CompanionRole) {
        progress.selectRole(role, for: featuredCompanion.id)
        persistVault()
        telemetry.log("select_role", detail: role.rawValue)
    }

    func unlockBuildNode(_ nodeID: String) {
        guard let node = buildNodes.first(where: { $0.id == nodeID }) else { return }
        _ = progress.unlockSkillNode(nodeID, for: featuredCompanion.id, cost: node.cost)
        persistVault()
        telemetry.log("unlock_build_node", detail: nodeID)
    }

    func claimSeasonReward() {
        _ = progress.claimSeasonReward(id: seasonEconomyBoard.seasonID)
        persistVault()
        telemetry.log("claim_season_reward", detail: seasonEconomyBoard.seasonID)
    }

    func claimRaidReward(_ encounterID: String) {
        guard let encounter = raidEncounters.first(where: { $0.id == encounterID }) else { return }
        _ = progress.claimRaidReward(
            id: encounter.id,
            title: encounter.title,
            readinessScore: encounter.readinessScore,
            threshold: encounter.claimThreshold,
            branchReward: seasonalRaidBranchReward
        )
        persistVault()
        syncMainCompanionSelection()
        telemetry.log("claim_raid_reward", detail: encounter.id)
    }

    var hasUnlockedNonTraceStage: Bool {
        progress.growthRecords.contains { record in
            let species = collection.first(where: { $0.id == record.companionID })?.pet.species
            return RunimalCompanionGrowthEngine.evolutionProgress(for: record, species: species).stageLabel != RunimalBalanceConfig.eggStageLabel
        }
    }
}
