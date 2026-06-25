import SwiftUI

enum AccountRoute: Hashable { case reservations, visited, reviews, savedLists }

struct AccountView: View {
    @EnvironmentObject private var account: AccountStore
    @EnvironmentObject private var saved: SavedListsStore
    @StateObject private var model = AccountViewModel()

    @State private var showEditProfile = false
    @State private var showVibeEditor = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    profileHeader
                    statsRow
                    vibeSection
                    recommendationsSection
                    savedListsSection
                    reservationsSection
                    visitedSection
                    reviewsSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Account")
            .navigationDestination(for: AccountRoute.self) { route in
                switch route {
                case .reservations: ReservationsListView()
                case .visited: VisitedListView()
                case .reviews: ReviewsListView()
                case .savedLists: SavedListsView()
                }
            }
            .navigationDestination(for: SavedList.self) { SavedListDetailView(listId: $0.id) }
            .navigationDestination(for: RestaurantRoute.self) { RestaurantDetailView(slug: $0.slug) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showEditProfile = true } label: { Image(systemName: "pencil") }
                }
            }
            .sheet(isPresented: $showEditProfile) { EditProfileSheet() }
            .sheet(isPresented: $showVibeEditor) { VibeEditorSheet() }
            .task(id: vibeKey) { await model.loadRecommendations(query: account.recommendationQuery) }
        }
    }

    private var vibeKey: String {
        "\(account.vibe.priceCeiling)|\(account.vibe.vibes.joined())|\(account.vibe.cuisines.joined())"
    }

    // MARK: Header

    private var profileHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Theme.accent, Color(red: 1.0, green: 0.55, blue: 0.2)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                Text(account.profile.initials)
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 3) {
                Text(account.profile.name).font(.display(.title2, weight: .bold))
                Text(account.profile.tagline).font(.subheadline).foregroundStyle(Theme.accent)
                if !account.profile.homeNeighborhood.isEmpty {
                    Label(account.profile.homeNeighborhood, systemImage: "mappin.and.ellipse")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal)
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            stat("Reservations", account.reservations.count, "calendar")
            stat("Been to", account.visited.count, "checkmark.seal")
            stat("Reviews", account.reviews.count, "star.bubble")
            stat("Saved", saved.lists.reduce(0) { $0 + $1.restaurants.count }, "bookmark")
        }
        .padding(.horizontal)
    }

    private func stat(_ label: String, _ value: Int, _ icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.subheadline).foregroundStyle(Theme.accent)
            Text("\(value)").font(.headline)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: What's your vibe

    private var vibeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("What's your vibe") {
                Button("Edit") { showVibeEditor = true }
                    .font(.caption.weight(.semibold)).tint(Theme.accent)
            }

            if account.vibe.isEmpty {
                Button { showVibeEditor = true } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Set your taste profile to get better picks")
                            .font(.subheadline).fontWeight(.medium)
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Theme.accent.opacity(0.12))
                    .foregroundStyle(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            } else {
                FlowLayout(spacing: 8) {
                    if account.vibe.priceCeiling < 4 {
                        TagChip(text: "≤ " + String(repeating: "$", count: account.vibe.priceCeiling),
                                systemImage: "dollarsign", selected: true)
                    }
                    ForEach(account.vibe.cuisines, id: \.self) { TagChip(text: prettyTag($0), selected: true) }
                    ForEach(account.vibe.vibes, id: \.self) { TagChip(text: prettyTag($0)) }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: Places you may like

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Places you may like")

            if model.isLoading && model.recommendations.isEmpty {
                ProgressView().frame(maxWidth: .infinity).padding()
            } else if model.recommendations.isEmpty {
                emptyHint("Set your vibe to see tailored picks.", icon: "wand.and.stars")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(model.recommendations) { r in
                            NavigationLink(value: RestaurantRoute(slug: r.slug)) {
                                RestaurantCard(restaurant: r)
                                    .frame(width: 280)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: Saved lists

    private var savedListsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Saved lists") {
                NavigationLink("See all", value: AccountRoute.savedLists)
                    .font(.caption.weight(.semibold)).tint(Theme.accent)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(saved.lists) { list in
                        NavigationLink(value: list) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(list.emoji).font(.title2)
                                Spacer(minLength: 0)
                                Text(list.name).font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary).lineLimit(1)
                                Text("\(list.restaurants.count) place\(list.restaurants.count == 1 ? "" : "s")")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .frame(width: 130, height: 100, alignment: .leading)
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

    // MARK: Reservations

    private var reservationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Reservations") {
                if !account.reservations.isEmpty { seeAll(.reservations) }
            }
            if account.upcomingReservations.isEmpty {
                emptyHint("No upcoming reservations. Reserve a table from any restaurant.",
                          icon: "calendar.badge.plus")
            } else {
                VStack(spacing: 10) {
                    ForEach(account.upcomingReservations.prefix(2)) { res in
                        NavigationLink(value: RestaurantRoute(slug: res.slug)) {
                            ReservationRow(reservation: res)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: Been to

    private var visitedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Places you've been") {
                if !account.visited.isEmpty { seeAll(.visited) }
            }
            if account.visited.isEmpty {
                emptyHint("Mark places as visited from their detail page.", icon: "checkmark.seal")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(account.sortedVisited.prefix(8)) { place in
                            NavigationLink(value: RestaurantRoute(slug: place.slug)) {
                                VisitedThumb(place: place)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: Reviews

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Your reviews") {
                if !account.reviews.isEmpty { seeAll(.reviews) }
            }
            if account.reviews.isEmpty {
                emptyHint("Share your take — write a review from a restaurant page.",
                          icon: "star.bubble")
            } else {
                VStack(spacing: 10) {
                    ForEach(account.sortedReviews.prefix(2)) { review in
                        NavigationLink(value: RestaurantRoute(slug: review.slug)) {
                            ReviewRow(review: review)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: Helpers

    private func seeAll(_ route: AccountRoute) -> some View {
        NavigationLink("See all", value: route)
            .font(.caption.weight(.semibold))
            .tint(Theme.accent)
    }

    @ViewBuilder
    private func sectionHeader<Accessory: View>(
        _ title: String,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() }
    ) -> some View {
        HStack {
            Text(title).sectionHeaderStyle()
            Spacer()
            accessory()
        }
        .padding(.horizontal)
    }

    private func emptyHint(_ text: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(.secondary)
            Text(text).font(.caption).foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

// MARK: - Row components

struct ReservationRow: View {
    let reservation: Reservation

    var body: some View {
        HStack(spacing: 12) {
            RemoteImage(url: reservation.heroImageURL)
                .frame(width: 56, height: 56).clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 3) {
                Text(reservation.restaurantName).fontWeight(.semibold).lineLimit(1)
                Label(reservation.date.formatted(date: .abbreviated, time: .shortened),
                      systemImage: "calendar")
                    .font(.caption).foregroundStyle(Theme.accent)
                HStack(spacing: 8) {
                    Label("\(reservation.partySize)", systemImage: "person.2")
                    if let occasion = reservation.occasion, !occasion.isEmpty {
                        Text("· \(prettyTag(occasion))")
                    }
                }
                .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            if reservation.isCancelled {
                Text("Cancelled").font(.caption2).foregroundStyle(Theme.bad)
            } else {
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct VisitedThumb: View {
    let place: VisitedPlace
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            RemoteImage(url: place.heroImageURL)
                .frame(width: 130, height: 90).clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text(place.name).font(.caption).fontWeight(.medium).lineLimit(1)
            Text(place.neighborhood).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
        }
        .frame(width: 130, alignment: .leading)
    }
}

struct ReviewRow: View {
    let review: UserReview
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(review.restaurantName).fontWeight(.semibold).lineLimit(1)
                Spacer()
                StarRow(rating: review.rating)
            }
            if !review.text.isEmpty {
                Text(review.text).font(.caption).foregroundStyle(.secondary).lineLimit(3)
            }
            Text(review.createdAt.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StarRow: View {
    let rating: Int
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundStyle(Theme.warn)
            }
        }
    }
}

// MARK: - Full list destinations

struct ReservationsListView: View {
    @EnvironmentObject private var account: AccountStore

    var body: some View {
        List {
            if !account.upcomingReservations.isEmpty {
                Section("Upcoming") {
                    ForEach(account.upcomingReservations) { res in
                        NavigationLink(value: RestaurantRoute(slug: res.slug)) {
                            ReservationRow(reservation: res)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .swipeActions {
                            Button("Cancel", role: .destructive) { account.cancelReservation(res.id) }
                        }
                    }
                }
            }
            if !account.pastReservations.isEmpty {
                Section("Past & cancelled") {
                    ForEach(account.pastReservations) { res in
                        ReservationRow(reservation: res)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .swipeActions {
                                Button("Delete", role: .destructive) { account.removeReservation(res.id) }
                            }
                    }
                }
            }
        }
        .overlay {
            if account.reservations.isEmpty {
                ContentUnavailableView("No reservations", systemImage: "calendar",
                                       description: Text("Reserve a table from any restaurant."))
            }
        }
        .navigationTitle("Reservations")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct VisitedListView: View {
    @EnvironmentObject private var account: AccountStore

    var body: some View {
        List {
            ForEach(account.sortedVisited) { place in
                NavigationLink(value: RestaurantRoute(slug: place.slug)) {
                    HStack(spacing: 12) {
                        RemoteImage(url: place.heroImageURL)
                            .frame(width: 54, height: 54).clipShape(RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(place.name).fontWeight(.medium)
                            Text("\(place.neighborhood) · \(place.borough)")
                                .font(.caption).foregroundStyle(.secondary)
                            Text("Visited \(place.visitedOn.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .overlay {
            if account.visited.isEmpty {
                ContentUnavailableView("No places yet", systemImage: "checkmark.seal",
                                       description: Text("Mark places as visited from their detail page."))
            }
        }
        .navigationTitle("Places you've been")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ReviewsListView: View {
    @EnvironmentObject private var account: AccountStore

    var body: some View {
        List {
            ForEach(account.sortedReviews) { review in
                NavigationLink(value: RestaurantRoute(slug: review.slug)) {
                    ReviewRow(review: review)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .swipeActions {
                    Button("Delete", role: .destructive) { account.deleteReview(review.id) }
                }
            }
        }
        .overlay {
            if account.reviews.isEmpty {
                ContentUnavailableView("No reviews yet", systemImage: "star.bubble",
                                       description: Text("Write a review from a restaurant page."))
            }
        }
        .navigationTitle("Your reviews")
        .navigationBarTitleDisplayMode(.inline)
    }
}
