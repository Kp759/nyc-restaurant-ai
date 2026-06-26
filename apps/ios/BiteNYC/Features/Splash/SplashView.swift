import SwiftUI

/// Animated launch screen — black background, orange **B** icon, wordmark + tagline.
struct SplashView: View {
    var onFinished: () -> Void

    @State private var logoScale: CGFloat = 0.72
    @State private var logoOpacity: Double = 0
    @State private var wordmarkOffset: CGFloat = 14
    @State private var wordmarkOpacity: Double = 0
    @State private var taglineOffset: CGFloat = 10
    @State private var taglineOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 0.5

    private let tagline = "Your NYC dining concierge"

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .stroke(BiteLogoMark.brandOrange.opacity(0.4), lineWidth: 2)
                        .frame(width: 210, height: 210)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    BiteLogoMark(size: 168, showRing: true, style: .icon)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }

                VStack(spacing: 10) {
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("Bite")
                            .font(.system(.largeTitle, design: .rounded).weight(.black))
                            .foregroundStyle(.white)
                        Text("NYC")
                            .font(.system(.largeTitle, design: .rounded).weight(.black))
                            .foregroundStyle(BiteLogoMark.brandOrange)
                    }
                    .offset(y: wordmarkOffset)
                    .opacity(wordmarkOpacity)

                    Text(tagline)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white.opacity(0.78))
                        .multilineTextAlignment(.center)
                        .offset(y: taglineOffset)
                        .opacity(taglineOpacity)
                }
                .padding(.horizontal, 32)
            }
        }
        .onAppear(perform: runAnimation)
    }

    private func runAnimation() {
        withAnimation(.spring(response: 0.62, dampingFraction: 0.62)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 1.2)) {
            ringScale = 1.3
            ringOpacity = 0
        }
        withAnimation(.easeOut(duration: 0.55).delay(0.3)) {
            wordmarkOffset = 0
            wordmarkOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.55).delay(0.55)) {
            taglineOffset = 0
            taglineOpacity = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
            onFinished()
        }
    }
}

#Preview {
    SplashView(onFinished: {})
}
