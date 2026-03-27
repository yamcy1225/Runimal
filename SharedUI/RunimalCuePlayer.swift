import Foundation
import RunimalCore

#if os(iOS)
import AudioToolbox
#elseif os(watchOS)
import WatchKit
#endif

enum RunimalCuePlayer {
    static func playHatchCue(for pet: GeneratedPet? = nil) {
        #if os(iOS)
        AudioServicesPlaySystemSound(hatchSoundID(for: pet))
        #elseif os(watchOS)
        WKInterfaceDevice.current().play(.success)
        #endif
    }

    static func playEvolutionCue(for pet: GeneratedPet? = nil) {
        #if os(iOS)
        AudioServicesPlaySystemSound(evolutionSoundID(for: pet))
        #elseif os(watchOS)
        WKInterfaceDevice.current().play(.directionUp)
        #endif
    }

    #if os(iOS)
    private static func hatchSoundID(for pet: GeneratedPet?) -> SystemSoundID {
        guard let pet,
              let profile = RunimalFeedbackProfileLoader.speciesProfile(for: pet.species) else {
            return 1108
        }
        return profile.hatchSound
    }

    private static func evolutionSoundID(for pet: GeneratedPet?) -> SystemSoundID {
        if let variantSound = RunimalFeedbackProfileLoader.variantEvolutionSound(for: pet?.rareVariant) {
            return variantSound
        }
        guard let pet,
              let profile = RunimalFeedbackProfileLoader.speciesProfile(for: pet.species) else {
            return 1104
        }
        return profile.evolutionSound
    }
    #endif
}
