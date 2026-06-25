import SwiftUI

/// Animated launch screen shown once on cold start. The logomark fades + scales
/// in, a shimmer sweeps the wordmark, then the whole view hands off to the app.
struct SplashView: View {
    var onFinished: () -> Void

    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var wordmarkOffset: CGFloat = 12
    @State private var wordmarkOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.4
    @State private var ringOpacity: Double = 0.6

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.45, blue: 0.20),
                    Color(red: 1.0, green: 0.27, blue: 0.30)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                        .frame(width: 180, height: 180)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    Image("AppLogo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(.white.opacity(0.9), lineWidth: 3))
                        .shadow(color: .black.opacity(0.18), radius: 14, y: 8)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }

                VStack(spacing: 6) {
                    Text("BiteNYC")
                        .font(.system(.largeTitle, design: .serif).weight(.bold))
                        .foregroundStyle(.white)
                        .offset(y: wordmarkOffset)
                        .opacity(wordmarkOpacity)

                    Text("Your NYC dining concierge")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
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
