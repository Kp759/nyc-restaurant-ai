import SwiftUI

/// Circular logomark: bold sans-serif **B** with a scalloped bite on the right side.
/// Orange circle + black letter, matching the Bite brand reference.
struct BiteLogoMark: View {
    var size: CGFloat = 120
    var showRing: Bool = false

    private var logoOrange: Color {
        Color(red: 1.00, green: 0.46, blue: 0.10)
    }

    var body: some View {
        ZStack {
            if showRing {
                Circle()
                    .stroke(Color.black.opacity(0.18), lineWidth: max(2, size * 0.014))
                    .frame(width: size * 1.14, height: size * 1.14)
            }

            ZStack {
                Circle()
                    .fill(logoOrange)

                Circle()
                    .strokeBorder(Color.black.opacity(0.14), lineWidth: max(1.5, size * 0.012))

                ZStack {
                    Text("B")
                        .font(.system(size: size * 0.58, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .offset(x: -size * 0.02)

                    biteNotches
                }
            }
            .frame(width: size, height: size)
            .shadow(color: logoOrange.opacity(0.55), radius: size * 0.10, y: size * 0.05)
            .shadow(color: .black.opacity(0.18), radius: size * 0.06, y: size * 0.03)
        }
        .frame(width: size, height: size)
    }

    /// Three scalloped notches eating into the right side of the **B** (teeth-mark style).
    private var biteNotches: some View {
        let notch = size * 0.115
        return ZStack {
            Circle()
                .fill(logoOrange)
                .frame(width: notch, height: notch)
                .offset(x: size * 0.19, y: -size * 0.13)

            Circle()
                .fill(logoOrange)
                .frame(width: notch * 0.96, height: notch * 0.96)
                .offset(x: size * 0.235, y: -size * 0.025)

            Circle()
                .fill(logoOrange)
                .frame(width: notch * 0.92, height: notch * 0.92)
                .offset(x: size * 0.19, y: size * 0.075)
        }
    }
}

#Preview {
    VStack(spacing: 32) {
        BiteLogoMark(size: 160, showRing: true)
            .padding(40)
            .background(Color.black)

        BiteLogoMark(size: 72)
            .padding(24)
            .background(Color(.systemBackground))
    }
}
