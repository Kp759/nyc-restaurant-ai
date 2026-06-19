import SwiftUI

extension Restaurant {
    /// Best image to use as a hero/thumbnail.
    var heroImageURL: String? {
        if let photo = media?.first(where: { $0.mediaType == "photo" }) {
            return photo.thumbnailUrl ?? photo.url
        }
        if let thumb = media?.compactMap(\.thumbnailUrl).first {
            return thumb
        }
        return dishes?.compactMap(\.photoUrl).first
    }
}

struct RestaurantCard: View {
    let restaurant: Restaurant
    var whyItFits: String?

    @EnvironmentObject private var saved: SavedListsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                RemoteImage(url: restaurant.heroImageURL)
                    .frame(height: 160)
                    .frame(maxWidth: .infinity)
                    .clipped()

                Button {
                    saved.toggleQuickSave(restaurant)
                } label: {
                    Image(systemName: saved.isSaved(restaurant) ? "bookmark.fill" : "bookmark")
                        .font(.subheadline.weight(.semibold))
                        .padding(8)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .padding(8)
                .tint(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(restaurant.name).font(.headline).lineLimit(1)
                    Spacer()
                    HealthGradeBadge(grade: restaurant.healthGrade)
                }

                HStack(spacing: 8) {
                    Text("\(restaurant.neighborhood) · \(restaurant.borough)")
                        .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    if !restaurant.priceLabel.isEmpty {
                        Text(restaurant.priceLabel).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    RatingLabel(rating: restaurant.rating, reviewCount: restaurant.reviewCount)
                }

                if let whyItFits, !whyItFits.isEmpty {
                    Text(whyItFits).font(.caption).foregroundStyle(Theme.accent).lineLimit(2)
                } else if let summary = restaurant.editorialSummary ?? restaurant.description {
                    Text(summary).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }

                if !restaurant.vibeTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(restaurant.vibeTags.prefix(4), id: \.self) { tag in
                                TagChip(text: prettyTag(tag))
                            }
                        }
                    }
                }
            }
            .padding(12)
        }
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
