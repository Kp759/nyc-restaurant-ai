import SwiftUI

extension BookingLink {
    var icon: String {
        switch provider {
        case "resy", "opentable", "tock", "sevenrooms": return "calendar.badge.plus"
        case "phone": return "phone.fill"
        default: return "link"
        }
    }

    var tint: Color {
        switch provider {
        case "resy": return Color(red: 0.9, green: 0.1, blue: 0.2)
        case "opentable": return Color(red: 0.85, green: 0.2, blue: 0.15)
        case "tock": return Color(red: 0.2, green: 0.5, blue: 0.9)
        default: return Theme.accent
        }
    }
}

struct BookingButton: View {
    let link: BookingLink

    var body: some View {
        if let url = URL(string: link.url) {
            Link(destination: url) {
                Label(link.label, systemImage: link.icon)
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(link.tint)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
