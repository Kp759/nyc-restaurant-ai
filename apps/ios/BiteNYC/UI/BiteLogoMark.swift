import SwiftUI

enum BiteLogoStyle {
    /// Orange circle with black **B** (auth, light backgrounds).
    case circle
    /// Orange **B** with bite notches — matches the app icon on black.
    case icon
}

/// BiteNYC logomark: bold rounded **B** with scalloped bite notches on the right.
struct BiteLogoMark: View {
    var size: CGFloat = 120
    var showRing: Bool = false
    var style: BiteLogoStyle = .circle

    static let brandOrange = Color(red: 1.0, green: 0.46, blue: 0.10)

    var body: some View {
        switch style {
        case .circle: circleMark
        case .icon: iconMark
        }
    }

    // MARK: - App icon style (black bg + orange B)

    private var iconMark: some View {
        ZStack {
            if showRing {
                Circle()
                    .stroke(Self.brandOrange.opacity(0.35), lineWidth: max(2, size * 0.014))
                    .frame(width: size * 1.18, height: size * 1.18)
            }

            ZStack {
                Text("B")
                    .font(.system(size: size * 0.56, weight: .black, design: .rounded))
                    .foregroundStyle(Self.brandOrange)
                    .offset(x: -size * 0.02)

                biteNotches(fill: .black)
            }
            .shadow(color: Self.brandOrange.opacity(0.35), radius: size * 0.04)
        }
        .frame(width: size, height: size)
    }

    // MARK: - Circle badge (orange disc + black B)

    private var circleMark: some View {
        ZStack {
            if showRing {
                Circle()
                    .stroke(Color.black.opacity(0.18), lineWidth: max(2, size * 0.014))
                    .frame(width: size * 1.14, height: size * 1.14)
            }

            ZStack {
                Circle()
                    .fill(Self.brandOrange)

                Circle()
                    .strokeBorder(Color.black.opacity(0.14), lineWidth: max(1.5, size * 0.012))

                ZStack {
                    Text("B")
                        .font(.system(size: size * 0.58, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .offset(x: -size * 0.02)

                    biteNotches(fill: Self.brandOrange)
                }
            }
            .frame(width: size, height: size)
            .shadow(color: Self.brandOrange.opacity(0.55), radius: size * 0.10, y: size * 0.05)
            .shadow(color: .black.opacity(0.18), radius: size * 0.06, y: size * 0.03)
        }
        .frame(width: size, height: size)
    }

    /// Three scalloped notches on the right side of the **B**.
    private func biteNotches(fill: Color) -> some View {
        let notch = size * 0.11
        return ZStack {
            Circle()
                .fill(fill)
                .frame(width: notch, height: notch)
                .offset(x: size * 0.19, y: -size * 0.13)

            Circle()
                .fill(fill)
                .frame(width: notch * 0.96, height: notch * 0.96)
                .offset(x: size * 0.235, y: -size * 0.025)

            Circle()
                .fill(fill)
                .frame(width: notch * 0.92, height: notch * 0.92)
                .offset(x: size * 0.19, y: size * 0.075)
        }
    }
}

#Preview("Icon on black") {
    BiteLogoMark(size: 160, showRing: true, style: .icon)
        .padding(48)
        .background(Color.black)
}

#Preview("Circle badge") {
    BiteLogoMark(size: 72, style: .circle)
        .padding(24)
        .background(Color(.systemBackground))
}
