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

    static func playLiveCue(label: String, intensity: Double) {
        #if os(iOS)
        let soundID: SystemSoundID

        switch label {
        case "Rare Window":
            soundID = 1117
        case "Surge":
            soundID = 1104
        case "Recover":
            soundID = 1153
        default:
            soundID = intensity >= 0.7 ? 1108 : 1519
        }

        AudioServicesPlaySystemSound(soundID)
        #elseif os(watchOS)
        let cue: WKHapticType

        switch label {
        case "Rare Window":
            cue = .success
        case "Surge":
            cue = .directionUp
        case "Recover":
            cue = .retry
        default:
            cue = intensity >= 0.7 ? .click : .start
        }

        WKInterfaceDevice.current().play(cue)
        #endif
    }

    static func playAlertCue(kind: AlertCueKind) {
        #if os(iOS)
        let soundID: SystemSoundID

        switch kind {
        case .goal:
            soundID = 1104
        case .reward:
            soundID = 1117
        case .rare:
            soundID = 1153
        }

        AudioServicesPlaySystemSound(soundID)
        #elseif os(watchOS)
        let cue: WKHapticType

        switch kind {
        case .goal:
            cue = .directionUp
        case .reward:
            cue = .success
        case .rare:
            cue = .notification
        }

        WKInterfaceDevice.current().play(cue)
        #endif
    }

    static func playMetronomeTick(shell: EggShellType, isStrongBeat: Bool = false) {
        #if os(iOS)
        let soundID: SystemSoundID

        switch shell {
        case .ember:
            soundID = isStrongBeat ? 1104 : 1519
        case .gale:
            soundID = isStrongBeat ? 1157 : 1156
        case .moss:
            soundID = isStrongBeat ? 1117 : 1108
        case .dusk:
            soundID = isStrongBeat ? 1153 : 1110
        case .stone:
            soundID = isStrongBeat ? 1151 : 1123
        }

        AudioServicesPlaySystemSound(soundID)
        #elseif os(watchOS)
        let cue: WKHapticType

        switch shell {
        case .ember:
            cue = isStrongBeat ? .directionUp : .click
        case .gale:
            cue = isStrongBeat ? .start : .click
        case .moss:
            cue = isStrongBeat ? .success : .click
        case .dusk:
            cue = isStrongBeat ? .notification : .click
        case .stone:
            cue = isStrongBeat ? .retry : .click
        }

        WKInterfaceDevice.current().play(cue)
        #endif
    }

    static func playCompanionTouchCue(isDelighted: Bool = false) {
        #if os(iOS)
        AudioServicesPlaySystemSound(isDelighted ? 1117 : 1519)
        #elseif os(watchOS)
        WKInterfaceDevice.current().play(isDelighted ? .success : .click)
        #endif
    }

    enum AlertCueKind {
        case goal
        case reward
        case rare
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
