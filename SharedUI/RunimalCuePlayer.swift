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
        switch pet?.species {
        case .sparkfang: return 1113
        case .stoneback: return 1123
        case .shadebit: return 1117
        default: return 1108
        }
    }

    private static func evolutionSoundID(for pet: GeneratedPet?) -> SystemSoundID {
        guard let rareVariant = pet?.rareVariant else { return 1104 }

        switch rareVariant {
        case .tempoSurge: return 1113
        case .zenBloom: return 1117
        case .summitHeart: return 1123
        case .eclipseMark: return 1108
        case .loopSigil: return 1110
        }
    }
    #endif
}
