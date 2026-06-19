import SwiftUI

/// Humanizes snake_case tags for display, e.g. "date_night" -> "Date night".
func prettyTag(_ tag: String) -> String {
    let spaced = tag.replacingOccurrences(of: "_", with: " ")
    return spaced.prefix(1).uppercased() + spaced.dropFirst()
}

struct TagChip: View {
    let text: String
    var systemImage: String?
    var selected: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage { Image(systemName: systemImage).font(.caption2) }
            Text(text).font(.caption).fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(selected ? Theme.accent.opacity(0.25) : Theme.chipBackground)
        .foregroundStyle(selected ? Theme.accent : .secondary)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(selected ? Theme.accent : .clear, lineWidth: 1)
        )
    }
}

struct HealthGradeBadge: View {
    let grade: String?
    var body: some View {
        if let grade, !grade.isEmpty {
            Text(grade.uppercased())
                .font(.caption2).fontWeight(.bold)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(Color.healthGrade(grade).opacity(0.2))
                .foregroundStyle(Color.healthGrade(grade))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.healthGrade(grade), lineWidth: 1))
        }
    }
}

struct RatingLabel: View {
    let rating: Double?
    let reviewCount: Int?
    var body: some View {
        if let rating {
            HStack(spacing: 3) {
                Image(systemName: "star.fill").font(.caption2).foregroundStyle(Theme.warn)
                Text(String(format: "%.1f", rating)).font(.caption).fontWeight(.semibold)
                if let reviewCount, reviewCount > 0 {
                    Text("(\(reviewCount))").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }
}

/// AsyncImage with a graceful gradient placeholder while loading / on failure.
struct RemoteImage: View {
    let url: String?
    var contentMode: ContentMode = .fill

    var body: some View {
        AsyncImage(url: url.flatMap(URL.init(string:))) { phase in
            switch phase {
            case let .success(image):
                image.resizable().aspectRatio(contentMode: contentMode)
            case .failure:
                placeholder.overlay(Image(systemName: "fork.knife").foregroundStyle(.secondary))
            case .empty:
                placeholder.overlay(ProgressView())
            @unknown default:
                placeholder
            }
        }
    }

    private var placeholder: some View {
        LinearGradient(
            colors: [Theme.cardBackground, Theme.chipBackground],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}

struct ErrorBanner: View {
    let message: String
    var retry: (() -> Void)?
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark").font(.largeTitle).foregroundStyle(.secondary)
            Text(message).font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let retry {
                Button("Try again", action: retry).buttonStyle(.borderedProminent).tint(Theme.accent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
