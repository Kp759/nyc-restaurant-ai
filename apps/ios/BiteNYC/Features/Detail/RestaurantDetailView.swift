import SwiftUI
import MapKit

struct RestaurantDetailView: View {
    let slug: String

    @EnvironmentObject private var saved: SavedListsStore
    @State private var restaurant: Restaurant?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showSaveSheet = false
    @State private var showReport = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView().frame(maxWidth: .infinity, minHeight: 300)
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
        .confirmationDialog("Report this listing?", isPresented: $showReport, titleVisibility: .visible) {
            if let restaurant {
                ForEach(["inaccurate", "spam", "nsfw", "copyright", "other"], id: \.self) { reason in
                    Button(prettyTag(reason)) { Task { await report(restaurant, reason: reason) } }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .task(id: slug) { await load() }
    }

    @ViewBuilder
    private func content(_ r: Restaurant) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero(r)
                header(r)
                if !(r.bookingLinks ?? []).isEmpty { bookingSection(r) }
                if !r.displayTags.isEmpty { tagsSection(r) }
                if let summary = r.editorialSummary ?? r.description { summarySection(summary) }
                if let clips = r.media?.filter({ $0.mediaType != "photo" }), !clips.isEmpty { clipsSection(clips) }
                if !r.mustTryDishes.isEmpty { dishesSection(r) }
                if !r.menuDishes.isEmpty { menuSection(r) }
                if let photos = r.media?.filter({ $0.mediaType == "photo" }), !photos.isEmpty { gallerySection(photos) }
                mapSection(r)
                if let similar = r.similar, !similar.isEmpty { similarSection(similar) }
            }
            .padding(.bottom, 32)
        }
    }

    private func hero(_ r: Restaurant) -> some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImage(url: r.heroImageURL)
                .frame(height: 240).frame(maxWidth: .infinity).clipped()
            LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .center, endPoint: .bottom)
                .frame(height: 240)
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
                Text(r.name).font(.title2).fontWeight(.bold)
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

    private func bookingSection(_ r: Restaurant) -> some View {
        VStack(spacing: 8) {
            ForEach(r.bookingLinks ?? []) { BookingButton(link: $0) }
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
        Text(text).font(.body).foregroundStyle(.primary.opacity(0.9)).padding(.horizontal)
    }

    private func dishesSection(_ r: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Must-try dishes").font(.headline).padding(.horizontal)
            ForEach(r.mustTryDishes) { dish in
                HStack(alignment: .top, spacing: 12) {
                    RemoteImage(url: dish.photoUrl)
                        .frame(width: 56, height: 56).clipShape(RoundedRectangle(cornerRadius: 10))
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

    private func menuSection(_ r: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Menu").font(.headline).padding(.horizontal)
            ForEach(r.menuDishes) { dish in
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(dish.name).font(.subheadline).fontWeight(.semibold)
                        Spacer()
                        if let type = dish.dishType, !type.isEmpty {
                            Text(prettyTag(type)).font(.caption2).foregroundStyle(Theme.accent)
                        }
                    }
                    if let desc = dish.description, !desc.isEmpty {
                        Text(desc).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                Divider().padding(.leading).opacity(0.4)
            }
        }
    }

    private func clipsSection(_ clips: [MediaItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Reels & clips").font(.headline).padding(.horizontal)
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
            Text("Photos").font(.headline).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(photos) { photo in
                        RemoteImage(url: photo.thumbnailUrl ?? photo.url)
                            .frame(width: 200, height: 140).clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func mapSection(_ r: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location").font(.headline).padding(.horizontal)
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
            Text("Similar places").font(.headline).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(similar) { s in
                        NavigationLink(value: RestaurantRoute(slug: s.slug)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(s.name).font(.subheadline).fontWeight(.semibold).lineLimit(1)
                                Text(s.neighborhood ?? "").font(.caption).foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(width: 170, alignment: .leading)
                            .background(Theme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
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
