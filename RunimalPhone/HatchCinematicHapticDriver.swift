import CoreHaptics
import Foundation

@MainActor
final class HatchCinematicHapticDriver {
    private var engine: CHHapticEngine?

    init() {
        prepare()
    }

    func playDecodingPulse() {
        playTransient(intensity: 0.22, sharpness: 0.42)
    }

    func playInterferenceRamp() {
        let events: [CHHapticEvent] = [
            .init(eventType: .hapticTransient, parameters: [
                .init(parameterID: .hapticIntensity, value: 0.24),
                .init(parameterID: .hapticSharpness, value: 0.35),
            ], relativeTime: 0),
            .init(eventType: .hapticTransient, parameters: [
                .init(parameterID: .hapticIntensity, value: 0.42),
                .init(parameterID: .hapticSharpness, value: 0.44),
            ], relativeTime: 0.18),
            .init(eventType: .hapticTransient, parameters: [
                .init(parameterID: .hapticIntensity, value: 0.68),
                .init(parameterID: .hapticSharpness, value: 0.58),
            ], relativeTime: 0.34),
        ]

        play(events: events)
    }

    func playCompletionBurst() {
        let events: [CHHapticEvent] = [
            .init(eventType: .hapticTransient, parameters: [
                .init(parameterID: .hapticIntensity, value: 1.0),
                .init(parameterID: .hapticSharpness, value: 0.82),
            ], relativeTime: 0),
            .init(eventType: .hapticContinuous, parameters: [
                .init(parameterID: .hapticIntensity, value: 0.36),
                .init(parameterID: .hapticSharpness, value: 0.28),
            ], relativeTime: 0.03, duration: 0.16),
        ]

        play(events: events)
    }

    private func prepare() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            let engine = try CHHapticEngine()
            try engine.start()
            engine.resetHandler = { [weak self] in
                self?.prepare()
            }
            self.engine = engine
        } catch {
            engine = nil
        }
    }

    private func playTransient(intensity: Float, sharpness: Float) {
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [
            .init(parameterID: .hapticIntensity, value: intensity),
            .init(parameterID: .hapticSharpness, value: sharpness),
        ], relativeTime: 0)

        play(events: [event])
    }

    private func play(events: [CHHapticEvent]) {
        guard let engine else { return }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try engine.start()
            try player.start(atTime: 0)
        } catch {
            prepare()
        }
    }
}
