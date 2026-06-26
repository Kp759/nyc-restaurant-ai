import SwiftUI

/// Animated launch screen — bright gradient, bitten **B** logomark, wordmark fade-in.
struct SplashView: View {
    var onFinished: () -> Void

    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var wordmarkOffset: CGFloat = 12
    @State private var wordmarkOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.4
    @State private var ringOpacity: Double = 0.6

    private var splashGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.00, green: 0.55, blue: 0.18),
                Color(red: 1.00, green: 0.32, blue: 0.34),
                Color(red: 0.96, green: 0.18, blue: 0.58),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            splashGradient.ignoresSafeArea()

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.55), lineWidth: 2)
                        .frame(width: 190, height: 190)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    BiteLogoMark(size: 156, showRing: false)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }

                VStack(spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("Bite")
                            .font(.system(.largeTitle, design: .serif).weight(.bold))
                            .foregroundStyle(.white)
                        Text("NYC")
                            .font(.system(.largeTitle, design: .serif).weight(.bold))
                            .foregroundStyle(.white.opacity(0.92))
                    }
                    .offset(y: wordmarkOffset)
                    .opacity(wordmarkOpacity)

                    Text("Your NYC dining concierge")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.88))
                        .opacity(taglineOpacity)
                }
            }
        }
        .onAppear(perform: runAnimation)
    }

    private func runAnimation() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 1.1)) {
            ringScale = 1.25
            ringOpacity = 0
        }
        withAnimation(.easeOut(duration: 0.6).delay(0.35)) {
            wordmarkOffset = 0
            wordmarkOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
            taglineOpacity = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            onFinished()
        }
    }
}

#Preview {
    SplashView(onFinished: {})
}
