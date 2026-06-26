import SwiftUI

/// Animated launch screen — black + orange brand, bitten **B** logomark.
struct SplashView: View {
    var onFinished: () -> Void

    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var wordmarkOffset: CGFloat = 12
    @State private var wordmarkOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.4
    @State private var ringOpacity: Double = 0.6

    private var brandOrange: Color {
        Color(red: 1.00, green: 0.46, blue: 0.10)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.10, green: 0.08, blue: 0.07),
                    Color(red: 0.18, green: 0.09, blue: 0.04),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(brandOrange.opacity(0.45), lineWidth: 2)
                        .frame(width: 196, height: 196)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    BiteLogoMark(size: 160, showRing: true)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }

                VStack(spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("Bite")
                            .font(.system(.largeTitle, design: .rounded).weight(.black))
                            .foregroundStyle(.white)
                        Text("NYC")
                            .font(.system(.largeTitle, design: .rounded).weight(.black))
                            .foregroundStyle(brandOrange)
                    }
                    .offset(y: wordmarkOffset)
                    .opacity(wordmarkOpacity)

                    Text("Your NYC dining concierge")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.72))
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
