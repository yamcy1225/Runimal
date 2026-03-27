import Foundation

#if os(iOS)
import AudioToolbox
#elseif os(watchOS)
import WatchKit
#endif

enum RunimalCuePlayer {
    static func playHatchCue() {
        #if os(iOS)
        AudioServicesPlaySystemSound(1117)
        #elseif os(watchOS)
        WKInterfaceDevice.current().play(.success)
        #endif
    }

    static func playEvolutionCue() {
        #if os(iOS)
        AudioServicesPlaySystemSound(1108)
        #elseif os(watchOS)
        WKInterfaceDevice.current().play(.directionUp)
        #endif
    }
}
