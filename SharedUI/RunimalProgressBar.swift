import SwiftUI

struct RunimalProgressBar: View {
    let progress: Double
    let accent: Color
    var height: CGFloat = 10

    @State private var animatedProgress = 0.0
    @State private var pulse = false

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(.white.opacity(0.12))
                .frame(height: height)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.65), accent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: max(18, animatedProgress * 220), height: height)
                .shadow(color: accent.opacity(pulse ? 0.55 : 0.25), radius: pulse ? 12 : 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            animatedProgress = progress
            pulse = true
        }
        .onChange(of: progress) { _, value in
            withAnimation(.spring(response: 0.65, dampingFraction: 0.85)) {
                animatedProgress = value
            }
        }
        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
    }
}
