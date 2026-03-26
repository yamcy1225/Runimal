import Foundation
import RunimalCore

let sampleRun = RunSummary(
    distanceKm: 10.02,
    averagePaceSeconds: 318,
    cadence: 174,
    elevationGainM: 0,
    variability: 0.06,
    aura: .day,
    shape: .outAndBack
)

let pet = RunimalGameEngine.generatePet(from: sampleRun)
let quests = RunimalGameEngine.evaluateRunQuests(for: sampleRun)

print("Runimal Apple CLI")
print("species:", pet.species.rawValue)
print("element:", pet.element.rawValue)
print("palette:", pet.palette)
print("rareVariant:", pet.rareVariant?.rawValue ?? "none")
print("quests:")

for quest in quests {
    print("-", quest.label, quest.completed ? "complete" : "pending", "->", quest.reward)
}
