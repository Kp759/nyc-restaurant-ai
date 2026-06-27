import SwiftUI
import MapKit

struct RestaurantDetailView: View {
    let slug: String

    @EnvironmentObject private var saved: SavedListsStore
    @EnvironmentObject private var account: AccountStore
    @EnvironmentObject private var router: AppRouter
    @Environment(\.openURL) private var openURL
    @State private var restaurant: Restaurant?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showSaveSheet = false
    @State private var showReport = false
    @State private var showReview = false
    @State private var galleryPhotoIndex: Int?

    private var photoItems: [MediaItem] {
        restaurant?.media?.filter { $0.mediaType == "photo" } ?? []
    }

    var body: some View {
        Group {
            if isLoading {
                FoodPunLoadingView(quotes: LoadingQuotes.detail, minHeight: 300)
            } else if let restaurant {
                content(restaurant)
            } else {
                ErrorBanner(message: errorMessage ?? "Could not load this place.") {
                    Task { await load() }
                }
            }
        }
        .navigationTitle(restaurant?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let restaurant {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { showSaveSheet = true } label: { Label("Save to list", systemImage: "bookmark") }
                        Button(role: .destructive) { showReport = true } label: { Label("Report", systemImage: "flag") }
                    } label: { Image(systemName: "ellipsis.circle") }
                }
            }
        }
        .sheet(isPresented: $showSaveSheet) {
            if let restaurant { AddToListSheet(restaurant: restaurant) }
        }
        .sheet(isPresented: $showReview) {
            if let restaurant { WriteReviewSheet(restaurant: restaurant) }
        }
        .confirmationDialog("Report this listing?", isPresented: $showReport, titleVisibility: .visible) {
            if let restaurant {
                ForEach(["inaccurate", "spam", "nsfw", "copyright", "other"], id: \.self) { reason in
                    Button(prettyTag(reason)) { Task { await report(restaurant, reason: reason) } }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .task(id: slug) { await load() }
        .fullScreenCover(isPresented: Binding(
            get: { galleryPhotoIndex != nil },
            set: { if !$0 { galleryPhotoIndex = nil } }
        )) {
            if galleryPhotoIndex != nil, !photoItems.isEmpty {
                PhotoGalleryViewer(photos: photoItems, selectedIndex: $galleryPhotoIndex)
            }
        }
    }

    @ViewBuilder
    private func content(_ r: Restaurant) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero(r)
                header(r)
                actionsSection(r)
                if !(r.effectiveBookingLinks).isEmpty { bookingSection(r) }
                if !r.displayTags.isEmpty { tagsSection(r) }
                if let summary = r.editorialSummary ?? r.description { summarySection(summary) }
                socialSection(r)
                if let clips = r.media?.filter({ $0.mediaType != "photo" }), !clips.isEmpty { clipsSection(clips) }
                if !r.mustTryDishes.isEmpty { mustTrySection(r) }
                if !r.allMenuDishes.isEmpty { menuLinkSection(r) }
                if let photos = r.media?.filter({ $0.mediaType == "photo" }), !photos.isEmpty { gallerySection(photos) }
                mapSection(r)
                if let similar = r.similar, !similar.isEmpty { similarSection(similar) }
            }
            .padding(.bottom, 32)
        }
    }

    private func hero(_ r: Restaurant) -> some View {
        ZStack(alignment: .bottomLeading) {
            Button {
                openPhotoGallery(at: 0)
            } label: {
                RemoteImage(url: r.heroImageURL)
                    .frame(height: 240)
                    .frame(maxWidth: .infinity)
                    .clipped()
            }
            .buttonStyle(.plain)
            .disabled(photoItems.isEmpty)

            LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .center, endPoint: .bottom)
                .frame(height: 240)
                .allowsHitTesting(false)

            Button { saved.toggleQuickSave(r) } label: {
                Image(systemName: saved.isSaved(r) ? "bookmark.fill" : "bookmark")
                    .padding(10).background(.ultraThinMaterial, in: Circle())
            }
            .tint(.white)
            .padding()
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private func header(_ r: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(r.name).font(.display(.title2, weight: .bold))
                Spacer()
                HealthGradeBadge(grade: r.healthGrade)
            }
            HStack(spacing: 10) {
                Text("\(r.neighborhood) · \(r.borough)").font(.subheadline).foregroundStyle(.secondary)
                if !r.priceLabel.isEmpty { Text(r.priceLabel).font(.subheadline).foregroundStyle(.secondary) }
                RatingLabel(rating: r.rating, reviewCount: r.reviewCount)
            }
            if !r.cuisineTags.isEmpty {
                Text(r.cuisineTags.map(prettyTag).joined(separator: " · "))
                    .font(.caption).foregroundStyle(Theme.accent)
            }
        }
        .padding(.horizontal)
    }

    private func actionsSection(_ r: Restaurant) -> some View {
        VStack(spacing: 10) {
            Button { router.reserve(r) } label: {
                Label("Reserve a table", systemImage: "calendar.badge.plus")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity).padding(.vertical, 13)
                    .background(Theme.accent).foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack(spacing: 10) {
                if r.hasCallAction, let callURL = r.callURL {
                    Button {
                        openURL(callURL)
                    } label: {
                        callButtonContent(r)
                    }
                }

                secondaryAction(
                    title: account.hasVisited(r) ? "Been here" : "Mark visited",
                    icon: account.hasVisited(r) ? "checkmark.seal.fill" : "checkmark.seal",
                    active: account.hasVisited(r)
                ) { account.toggleVisited(r) }

                secondaryAction(
                    title: account.review(for: r) == nil ? "Review" : "Edit review",
                    icon: "star.bubble",
                    active: account.review(for: r) != nil
                ) { showReview = true }
            }
        }
        .padding(.horizontal)
    }

    private func callButtonContent(_ r: Restaurant) -> some View {
        VStack(spacing: 2) {
            Label("Call", systemImage: "phone.fill")
                .font(.subheadline.weight(.semibold))
            if let phone = r.dialPhoneNumber, !phone.isEmpty {
                Text(phone)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            } else if r.usesMapsCallFallback {
                Text("via Google Maps")
                    .font(.caption2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .background(Theme.good.opacity(0.16))
        .foregroundStyle(Theme.good)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func secondaryAction(
        title: String, icon: String, active: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity).padding(.vertical, 11)
                .background(active ? Theme.accent.opacity(0.16) : Theme.cardBackground)
                .foregroundStyle(active ? Theme.accent : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func bookingSection(_ r: Restaurant) -> some View {
        VStack(spacing: 8) {
            ForEach(r.effectiveBookingLinks.filter { $0.provider != "phone" }) { BookingButton(link: $0) }
        }
        .padding(.horizontal)
    }

    private func tagsSection(_ r: Restaurant) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(r.displayTags, id: \.self) { TagChip(text: prettyTag($0)) }
        }
        .padding(.horizontal)
    }

    private func summarySection(_ text: String) -> some View {
        Text(text)
            .font(.system(.body, design: .serif))
            .lineSpacing(3)
            .foregroundStyle(.primary.opacity(0.9))
            .padding(.horizontal)
    }

    private func socialSection(_ r: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Follow").sectionHeaderStyle().padding(.horizontal)
            HStack(spacing: 10) {
                ForEach(r.socialLinks) { link in
                    if let url = URL(string: link.url) {
                        Link(destination: url) {
                            HStack(spacing: 6) {
                                Image(systemName: socialIcon(link.platform))
                                Text(socialLabel(link.platform)).fontWeight(.semibold)
                            }
                            .font(.caption)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(socialColor(link.platform).opacity(0.14))
                            .foregroundStyle(socialColor(link.platform))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func socialIcon(_ platform: String) -> String {
        switch platform {
        case "instagram": return "camera"
        case "x": return "bird"
        case "facebook": return "person.2"
        default: return "link"
        }
    }

    private func socialLabel(_ platform: String) -> String {
        switch platform {
        case "instagram": return "Instagram"
        case "x": return "X"
        case "facebook": return "Facebook"
        default: return platform
        }
    }

    private func socialColor(_ platform: String) -> Color {
        switch platform {
        case "instagram": return Color(red: 0.84, green: 0.18, blue: 0.55)
        case "x": return .primary
        case "facebook": return Color(red: 0.09, green: 0.47, blue: 0.95)
        default: return Theme.accent
        }
    }

    private func mustTrySection(_ r: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Must try").sectionHeaderStyle().padding(.horizontal)

            if !r.mustTryFood.isEmpty {
                mustTryGroup(title: "Dishes", icon: "fork.knife", dishes: r.mustTryFood)
            }
            if !r.mustTryDrinks.isEmpty {
                mustTryGroup(title: "Drinks", icon: "wineglass", dishes: r.mustTryDrinks)
            }
        }
    }

    private func mustTryGroup(title: String, icon: String, dishes: [Dish]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.accent)
                .padding(.horizontal)

            ForEach(dishes) { dish in
                HStack(alignment: .top, spacing: 12) {
                    RemoteImage(url: dish.photoUrl)
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dish.name).font(.subheadline).fontWeight(.semibold)
                        if let why = dish.whyTry ?? dish.description {
                            Text(why).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
    }

    private func menuLinkSection(_ r: Restaurant) -> some View {
        NavigationLink {
            FullMenuView(restaurantName: r.name, dishes: r.allMenuDishes)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.title3)
                    .foregroundStyle(Theme.accent)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Menu")
                        .font(.subheadline.weight(.semibold))
                    Text("\(r.allMenuDishes.count) items · full list")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }

    private func clipsSection(_ clips: [MediaItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Reels & clips").sectionHeaderStyle().padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(clips) { clip in
                        if let url = URL(string: clip.url) {
                            Link(destination: url) {
                                ZStack {
                                    RemoteImage(url: clip.thumbnailUrl ?? clip.url)
                                        .frame(width: 130, height: 200).clipped()
                                    Image(systemName: "play.circle.fill")
                                        .font(.largeTitle).foregroundStyle(.white.opacity(0.9))
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func gallerySection(_ photos: [MediaItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Photos").sectionHeaderStyle().padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                        Button {
                            openPhotoGallery(at: index)
                        } label: {
                            RemoteImage(url: photo.thumbnailUrl ?? photo.url)
                                .frame(width: 200, height: 140)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func openPhotoGallery(at index: Int) {
        guard !photoItems.isEmpty else { return }
        galleryPhotoIndex = min(max(index, 0), photoItems.count - 1)
    }

    private func mapSection(_ r: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location").sectionHeaderStyle().padding(.horizontal)
            Map(initialPosition: .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: r.latitude, longitude: r.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))) {
                Marker(r.name, coordinate: CLLocationCoordinate2D(latitude: r.latitude, longitude: r.longitude))
                    .tint(Theme.accent)
            }
            .frame(height: 180).clipShape(RoundedRectangle(cornerRadius: 12)).padding(.horizontal)
            Label(r.address, systemImage: "mappin.circle").font(.caption).foregroundStyle(.secondary).padding(.horizontal)
            Label("Check nearby subway lines before you go.", systemImage: "tram.fill")
                .font(.caption).foregroundStyle(.secondary).padding(.horizontal)
        }
    }

    private func similarSection(_ similar: [SimilarRestaurant]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Similar places").sectionHeaderStyle().padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(similar) { s in
                        NavigationLink(value: RestaurantRoute(slug: s.slug)) {
                            VStack(alignment: .leading, spacing: 0) {
                                RemoteImage(url: s.heroImageUrl)
                                    .frame(width: 190, height: 120)
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(s.name)
                                        .font(.display(.subheadline, weight: .semibold))
                                        .lineLimit(1)
                                    HStack(spacing: 6) {
                                        Text(s.neighborhood ?? "")
                                            .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                                        RatingLabel(rating: s.rating, reviewCount: nil)
                                    }
                                    if !s.previewTags.isEmpty {
                                        FlowLayout(spacing: 5) {
                                            ForEach(s.previewTags, id: \.self) { tag in
                                                TagChip(text: prettyTag(tag))
                                            }
                                        }
                                    }
                                }
                                .padding(10)
                            }
                            .frame(width: 190, alignment: .leading)
                            .background(Theme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            restaurant = try await APIClient.shared.restaurant(slug: slug)
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    private func report(_ r: Restaurant, reason: String) async {
        try? await APIClient.shared.report(targetType: "restaurant", targetId: r.id, reason: reason, details: nil)
    }
}

/// Buckets the AI dish types (appetizer | small_plate | main | dessert | drink)
/// into ordered, human-friendly menu courses.
enum MenuCourse: Int, CaseIterable, Identifiable {
    case starters, mains, desserts, drinks, other
    var id: Int { rawValue }

    var title: String {
        switch self {
        case .starters: return "Starters & small plates"
        case .mains: return "Mains"
        case .desserts: return "Desserts"
        case .drinks: return "Drinks"
        case .other: return "More"
        }
    }

    var icon: String {
        switch self {
        case .starters: return "leaf"
        case .mains: return "fork.knife"
        case .desserts: return "birthday.cake"
        case .drinks: return "wineglass"
        case .other: return "square.grid.2x2"
        }
    }

    static func from(_ dishType: String?) -> MenuCourse {
        switch (dishType ?? "").lowercased() {
        case "appetizer", "small_plate", "starter", "side": return .starters
        case "main", "entree", "entrée": return .mains
        case "dessert": return .desserts
        case "drink", "cocktail", "beverage": return .drinks
        default: return .other
        }
    }
}
