import Foundation

public enum SpeciesMutationNamingEngine {
    public static func displayTitle(for snapshot: MutationFormSnapshot) -> String {
        let prefix = prefix(for: snapshot)
        let suffix = suffix(for: snapshot)
        return "\(prefix) \(suffix)"
    }

    public static func lineageSummary(for snapshot: MutationFormSnapshot) -> String {
        snapshot.shortLabel
    }

    private static func prefix(for snapshot: MutationFormSnapshot) -> String {
        switch snapshot.speciesID {
        case "windrunner":
            return windrunnerPrefix(for: snapshot.bodyBranchID)
        case "stoneback":
            return stonebackPrefix(for: snapshot.bodyBranchID)
        case "sparkfang":
            return sparkfangPrefix(for: snapshot.bodyBranchID)
        case "mosshop":
            return mosshopPrefix(for: snapshot.ecologyBranchID)
        case "seedle":
            return seedlePrefix(for: snapshot.ecologyBranchID)
        default:
            return fallbackPrefix(for: snapshot.bodyBranchID)
        }
    }

    private static func suffix(for snapshot: MutationFormSnapshot) -> String {
        switch snapshot.speciesID {
        case "windrunner", "stoneback":
            return routeSuffix(for: snapshot.ecologyBranchID)
        case "sparkfang":
            return rhythmSuffix(for: snapshot.rhythmBranchID)
        case "mosshop":
            return rhythmSuffix(for: snapshot.rhythmBranchID)
        case "seedle":
            return seedleSuffix(for: snapshot.rhythmBranchID)
        default:
            return rhythmSuffix(for: snapshot.rhythmBranchID)
        }
    }

    private static func windrunnerPrefix(for branchID: String) -> String {
        switch branchID {
        case "aero-swift":
            return "Zephyr"
        case "crest-guard":
            return "Galecrest"
        case "roam-wild":
            return "Waywing"
        default:
            return "Zephyr"
        }
    }

    private static func stonebackPrefix(for branchID: String) -> String {
        switch branchID {
        case "ridge-guard":
            return "Talus"
        case "summit-core":
            return "Summit"
        case "basalt-bulwark":
            return "Basalt"
        default:
            return "Talus"
        }
    }

    private static func sparkfangPrefix(for branchID: String) -> String {
        switch branchID {
        case "burst-swift":
            return "Volt"
        case "arc-raider":
            return "Arc"
        case "flare-hunter":
            return "Flare"
        default:
            return "Volt"
        }
    }

    private static func mosshopPrefix(for branchID: String) -> String {
        switch branchID {
        case "rain-wildland":
            return "Verdant"
        case "park-moss":
            return "Canopy"
        case "grove-rest":
            return "Grove"
        default:
            return "Canopy"
        }
    }

    private static func seedlePrefix(for branchID: String) -> String {
        switch branchID {
        case "garden-core":
            return "Sprout"
        case "everywhere-seed":
            return "Germin"
        case "twilight-bud":
            return "Twilight"
        default:
            return "Sprout"
        }
    }

    private static func routeSuffix(for branchID: String) -> String {
        switch branchID {
        case "sky-urban":
            return "Skyline"
        case "river-open":
            return "Riverside"
        case "ridge-frontier":
            return "Frontier"
        case "fault-rock":
            return "Fault"
        case "cold-ridge":
            return "Ridgeline"
        case "storm-slope":
            return "Storm"
        default:
            return "Route"
        }
    }

    private static func rhythmSuffix(for branchID: String) -> String {
        switch branchID {
        case "cruise-loop":
            return "Loop"
        case "draft-route":
            return "Draft"
        case "tailwind-pulse":
            return "Pulse"
        case "climb-pulse":
            return "Climb"
        case "hold-line":
            return "Line"
        case "anchor-step":
            return "Step"
        case "tempo-rush":
            return "Tempo"
        case "surge-fang":
            return "Surge"
        case "shock-beat":
            return "Beat"
        case "bloom-pulse":
            return "Bloom"
        case "calm-loop":
            return "Calm"
        case "drift-heal":
            return "Heal"
        default:
            return "Rhythm"
        }
    }

    private static func seedleSuffix(for branchID: String) -> String {
        switch branchID {
        case "first-step":
            return "Step"
        case "steady-root":
            return "Root"
        case "grow-loop":
            return "Bloom"
        default:
            return "Seed"
        }
    }

    private static func fallbackPrefix(for branchID: String) -> String {
        switch branchID {
        case let id where id.contains("twilight"):
            return "Twilight"
        case let id where id.contains("storm"):
            return "Storm"
        case let id where id.contains("bloom"):
            return "Bloom"
        default:
            return "Runimal"
        }
    }
}

public extension MutationFormSnapshot {
    var displayTitle: String {
        SpeciesMutationNamingEngine.displayTitle(for: self)
    }

    var lineageSummary: String {
        SpeciesMutationNamingEngine.lineageSummary(for: self)
    }
}
