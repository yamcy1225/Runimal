import RunimalCore
import SwiftUI

struct PhoneEggForgeEffectView: View {
    let egg: EggInventoryEntry

    @State private var outerRingScale: CGFloat = 0.72
    @State private var outerRingOpacity = 0.0
    @State private var glow = false
    @State private var shellScale: CGFloat = 0.88
    @State private var badgeVisible = false

    var body: some View {
        ZStack {
            Circle()
                .fill(egg.shell.accentColor.opacity(glow ? 0.22 : 0.12))
                .frame(width: 108, height: 108)
                .blur(radius: glow ? 18 : 10)

            Circle()
                .stroke(egg.shell.accentColor.opacity(0.36), lineWidth: 2)
                .frame(width: 92 * outerRingScale, height: 92 * outerRingScale)
                .opacity(outerRingOpacity)

            Circle()
                .stroke(.white.opacity(0.08), lineWidth: 1)
                .frame(width: 92, height: 92)

            TraceEggView(
                accent: egg.shell.accentColor,
                shell: egg.shell,
                pixelSize: 7,
                resonance: 0.46
            )
            .frame(width: 88, height: 88)
            .scaleEffect(shellScale)

            VStack(spacing: 4) {
                Text("EGG FORGED")
                    .font(.caption2.weight(.black))
                    .tracking(1.6)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(.white.opacity(0.96)))

                Text(egg.shell.rawValue.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(egg.shell.accentColor.opacity(0.94))
            }
            .offset(y: -62)
            .opacity(badgeVisible ? 1 : 0)
            .scaleEffect(badgeVisible ? 1 : 0.92)
        }
        .frame(width: 120, height: 132)
        .onAppear {
            playSequence()
        }
    }

    private func playSequence() {
        outerRingScale = 0.72
        outerRingOpacity = 0.0
        glow = false
        shellScale = 0.88
        badgeVisible = false

        Task {
            await MainActor.run {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.68)) {
                    shellScale = 1.02
                    glow = true
                    badgeVisible = true
                }
                withAnimation(.easeOut(duration: 1.1)) {
                    outerRingScale = 1.18
                    outerRingOpacity = 1
                }
            }

            try? await Task.sleep(for: .milliseconds(1100))

            await MainActor.run {
                withAnimation(.easeOut(duration: 0.9)) {
                    outerRingScale = 1.36
                    outerRingOpacity = 0
                    shellScale = 0.98
                }
            }

            try? await Task.sleep(for: .milliseconds(900))

            await MainActor.run {
                withAnimation(.easeInOut(duration: 1.0)) {
                    glow = false
                    shellScale = 1
                }
            }
        }
    }
}
