import Foundation
import Testing
@testable import RunimalCore

struct RunRewardSummaryCodecTests {
    @Test
    func decodesLegacyRewardPayloadWithoutBonusLabels() throws {
        let payload = """
        {
          "pet": {
            "species": "windrunner",
            "element": "light",
            "palette": "windrunner-loop-sigil",
            "rareVariant": "loop-sigil",
            "explanation": ["legacy"],
            "stats": {
              "vitality": 12,
              "agility": 15,
              "dexterity": 11,
              "focus": 13,
              "defense": 9
            }
          },
          "coreLabel": "빛의 코어",
          "experience": 142,
          "completedQuestCount": 2,
          "flavorText": "legacy payload"
        }
        """

        let reward = try JSONDecoder().decode(RunRewardSummary.self, from: Data(payload.utf8))

        #expect(reward.experience == 142)
        #expect(reward.completedQuestCount == 2)
        #expect(reward.bonusLabels.isEmpty)
    }

    @Test
    func preservesBonusLabelsAcrossRoundTrip() throws {
        let reward = RunRewardSummary(
            pet: samplePet(),
            coreLabel: "루프 코어",
            experience: 168,
            completedQuestCount: 3,
            flavorText: "loop reward",
            bonusLabels: ["교감 예열 +2", "실시간 교감 +3"]
        )

        let encoded = try JSONEncoder().encode(reward)
        let decoded = try JSONDecoder().decode(RunRewardSummary.self, from: encoded)

        #expect(decoded.experience == 168)
        #expect(decoded.bonusLabels == ["교감 예열 +2", "실시간 교감 +3"])
    }

    private func samplePet() -> GeneratedPet {
        GeneratedPet(
            species: .windrunner,
            element: .light,
            palette: PetSpecies.windrunner.paletteName(rareVariant: .loopSigil),
            rareVariant: .loopSigil,
            explanation: ["test"],
            stats: PetStats(vitality: 12, agility: 15, dexterity: 11, focus: 13, defense: 9)
        )
    }
}
