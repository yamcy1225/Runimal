import SwiftUI

struct RunimalProgressBar: View {
    let progress: Double
    let accent: Color
    var height: CGFloat = 10

    @State private var animatedProgress = 0.0
    @State private var pulse = false
    @State private var sweep = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.10))
                    .frame(height: height)
                    .overlay {
                        ZStack(alignment: .leading) {
                            ForEach(1..<5, id: \.self) { marker in
                                Capsule()
                                    .fill(.white.opacity(0.12))
                                    .frame(width: 2, height: height - 2)
                                    .offset(x: geometry.size.width * CGFloat(marker) / 5)
                            }
                        }
                        .clipShape(Capsule())
                    }

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.55), accent, .white.opacity(0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(18, animatedProgress * geometry.size.width), height: height)
                    .shadow(color: accent.opacity(pulse ? 0.55 : 0.25), radius: pulse ? 12 : 4)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.34))
                            .frame(width: min(54, geometry.size.width * 0.28), height: height - 2)
                            .blur(radius: 5)
                            .offset(x: sweep ? max(0, animatedProgress * geometry.size.width - 34) : -28)
                    }

                if animatedProgress > 0.01 {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(.white.opacity(pulse ? 0.9 : 0.45))
                            .frame(width: height + CGFloat(index), height: height + CGFloat(index))
                            .blur(radius: CGFloat(index) * 1.5)
                            .offset(x: max(0, animatedProgress * geometry.size.width - CGFloat(8 - index * 2)))
                            .opacity(index == 0 ? 1 : 0.55)
                    }
                }
            }
            .frame(height: height)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: height)
        .onAppear {
            animatedProgress = progress
            pulse = true
            sweep = true
        }
        .onChange(of: progress) { _, value in
            withAnimation(.spring(response: 0.65, dampingFraction: 0.85)) {
                animatedProgress = value
            }
        }
        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
        .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: false), value: sweep)
    }
}
