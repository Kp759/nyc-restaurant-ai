import SwiftUI

/// Circular logomark: serif **B** with a bite taken out of the top-right edge.
struct BiteLogoMark: View {
    var size: CGFloat = 120
    var showRing: Bool = false

    private var biteGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.00, green: 0.48, blue: 0.26),
                Color(red: 1.00, green: 0.28, blue: 0.38),
                Color(red: 0.96, green: 0.20, blue: 0.58),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            if showRing {
                Circle()
                    .stroke(Color.white.opacity(0.45), lineWidth: max(2, size * 0.014))
                    .frame(width: size * 1.12, height: size * 1.12)
            }

            ZStack {
                Circle()
                    .fill(biteGradient)

                Text("B")
                    .font(.system(size: size * 0.52, weight: .heavy, design: .serif))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
            }
            .frame(width: size, height: size)
            .mask(biteMask)
            .overlay(
                Circle()
                    .strokeBorder(.white.opacity(0.88), lineWidth: max(2.5, size * 0.022))
            )
            .shadow(color: Color(red: 1.0, green: 0.25, blue: 0.35).opacity(0.45), radius: size * 0.12, y: size * 0.06)
        }
        .frame(width: size, height: size)
    }

    private var biteMask: some View {
        ZStack {
            Circle()
            Circle()
                .frame(width: size * 0.34, height: size * 0.34)
                .offset(x: size * 0.30, y: -size * 0.30)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.52, blue: 0.22),
                Color(red: 0.98, green: 0.18, blue: 0.55),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        BiteLogoMark(size: 160, showRing: true)
    }
}
