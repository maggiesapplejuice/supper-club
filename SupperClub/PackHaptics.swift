import CoreHaptics

/// All pack-opening haptics. Does nothing on hardware without a haptic engine, including the Simulator.
@MainActor
final class PackHaptics {
    private let engine: CHHapticEngine? = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        ? try? CHHapticEngine()
        : nil

    func prepare() {
        try? engine?.start()
    }

    /// One tick of foil tearing. Gets stronger as the tear gets closer to finishing.
    func tearTick(progress: Double) {
        play([transient(at: 0, intensity: 0.35 + 0.55 * progress, sharpness: 0.85)])
    }

    /// The pack bursting open: a sharp crack over a low rumble that fades out.
    func packBurst() {
        play([
            transient(at: 0, intensity: 1, sharpness: 1),
            transient(at: 0.06, intensity: 0.8, sharpness: 0.5),
            rumble(at: 0.04, duration: 0.5, intensity: 0.8, sharpness: 0.2),
        ])
    }

    /// Stronger and longer for rarer cards.
    func cardReveal(_ tier: RarityTier) {
        let strength = 0.4 + 0.15 * Double(tier.rawValue)
        var events = [transient(at: 0, intensity: strength, sharpness: 0.6)]
        if tier >= .rare {
            events.append(rumble(at: 0.02, duration: 0.12 * Double(tier.rawValue), intensity: strength, sharpness: 0.35))
        }
        play(events)
    }

    /// A heartbeat that speeds up and builds while the holo card shakes.
    func legendaryBuildUp(duration: Double) {
        var events: [CHHapticEvent] = []
        var time = 0.0
        var gap = 0.28
        while time < duration {
            let progress = time / duration
            events.append(transient(at: time, intensity: 0.3 + 0.7 * progress, sharpness: 0.3 + 0.4 * progress))
            time += gap
            gap = max(0.06, gap * 0.82)
        }
        events.append(rumble(at: 0, duration: duration, intensity: 0.35, sharpness: 0.15))
        play(events)
    }

    /// The big hit when the holo card flips, followed by shimmering sparkle ticks.
    func legendaryHit() {
        var events = [
            transient(at: 0, intensity: 1, sharpness: 1),
            rumble(at: 0, duration: 0.7, intensity: 1, sharpness: 0.3),
        ]
        for index in 0..<10 {
            events.append(transient(
                at: 0.45 + Double(index) * 0.07,
                intensity: 0.55 - Double(index) * 0.04,
                sharpness: 1
            ))
        }
        play(events)
    }

    private func play(_ events: [CHHapticEvent]) {
        guard let engine else { return }
        do {
            try engine.start()
            let pattern = try CHHapticPattern(events: events, parameters: [])
            try engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
        } catch {
            // Haptics are a bonus, so a failure should never interrupt opening the pack.
        }
    }

    private func transient(at time: Double, intensity: Double, sharpness: Double) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticTransient,
            parameters: parameters(intensity: intensity, sharpness: sharpness),
            relativeTime: time
        )
    }

    private func rumble(at time: Double, duration: Double, intensity: Double, sharpness: Double) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: parameters(intensity: intensity, sharpness: sharpness),
            relativeTime: time,
            duration: duration
        )
    }

    private func parameters(intensity: Double, sharpness: Double) -> [CHHapticEventParameter] {
        [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(min(1, intensity))),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(min(1, sharpness))),
        ]
    }
}

extension RarityTier: Comparable {
    static func < (lhs: RarityTier, rhs: RarityTier) -> Bool { lhs.rawValue < rhs.rawValue }
}
