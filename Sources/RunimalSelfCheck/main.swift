import Foundation
import RunimalCore

@inline(__always)
func assert(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("Self-check failed: \(message)\n", stderr)
        exit(1)
    }
}

let sampleRun = RunSummary(
    distanceKm: 10.02,
    averagePaceSeconds: 318,
    cadence: 174,
    elevationGainM: 0,
    variability: 0.06,
    aura: .day,
    shape: .outAndBack
)

let samplePet = RunimalGameEngine.generatePet(from: sampleRun)
assert(samplePet.species == .windrunner, "expected windrunner species")
assert(samplePet.rareVariant == .zenBloom, "expected zen-bloom rare variant")
assert(samplePet.palette == "Sky Teal Zen", "expected Sky Teal Zen palette")

let tempoRun = RunSummary(
    distanceKm: 5.5,
    averagePaceSeconds: 300,
    cadence: 176,
    elevationGainM: 24,
    variability: 0.11,
    aura: .dawn,
    shape: .loop
)

let quests = RunimalGameEngine.evaluateRunQuests(for: tempoRun)
assert(quests.contains(where: { $0.label == "Tempo Check" && $0.completed }), "expected Tempo Check quest completion")
assert(quests.contains(where: { $0.label == "Mutation Spark" && $0.completed }), "expected Mutation Spark quest completion")

print("RunimalSelfCheck passed")
