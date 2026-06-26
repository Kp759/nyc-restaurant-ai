import SwiftUI
import MapKit

struct ExploreView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var model = ExploreViewModel()
    @State private var mode: Mode = .list
    @State private var showFilters = false
    @State private var path = NavigationPath()

    enum Mode: String, CaseIterable { case list = "List", map = "Map" }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                modePicker
                quickFilterBar
                curatedPicksBar
                Divider()
                content
            }
            .navigationTitle("Explore NYC")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilters = true
                    } label: {
                        Label("Filters", systemImage: "slider.horizontal.3")
                        if model.activeFilterCount > 0 {
                            Text("\(model.activeFilterCount)")
                                .font(.caption2).padding(5)
                                .background(Theme.accent).clipShape(Circle())
                        }
                    }
                }
            }
            .navigationDestination(for: RestaurantRoute.self) { RestaurantDetailView(slug: $0.slug) }
            .sheet(isPresented: $showFilters) {
                ExploreFilterSheet(model: model)
            }
            .task {
                await model.loadMetadataIfNeeded()
                if model.restaurants.isEmpty { await model.load() }
            }
        }
    }

    private var modePicker: some View {
        Picker("Mode", selection: $mode) {
            ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var quickFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Menu {
                    Button("All boroughs") { model.borough = nil; reload() }
                    ForEach(model.boroughs, id: \.self) { b in
                        Button(b) { model.borough = b; reload() }
                    }
                } label: { TagChip(text: model.borough ?? "Borough", systemImage: "building.2", selected: model.borough != nil) }

                Menu {
                    Button("All neighborhoods") { model.neighborhood = nil; reload() }
                    ForEach(model.neighborhoodOptions) { n in
                        Button(n.name) { model.neighborhood = n.name; reload() }
                    }
                } label: { TagChip(text: model.neighborhood ?? "Neighborhood", systemImage: "mappin.and.ellipse", selected: model.neighborhood != nil) }

                Menu {
                    Button("Any price") { model.maxPriceTier = nil; reload() }
                    ForEach(1...4, id: \.self) { tier in
                        Button(String(repeating: "$", count: tier)) { model.maxPriceTier = tier; reload() }
                    }
                } label: { TagChip(text: model.maxPriceTier.map { "≤ " + String(repeating: "$", count: $0) } ?? "Price", systemImage: "dollarsign", selected: model.maxPriceTier != nil) }

                Button { model.openNow.toggle(); reload() } label: {
                    TagChip(text: "Open late", systemImage: "moon.stars", selected: model.openNow)
                }
                Button { model.reservationAvailable.toggle(); reload() } label: {
                    TagChip(text: "Reservable", systemImage: "calendar", selected: model.reservationAvailable)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private var curatedPicksBar: some View {
        let categories = model.vibeCategories.isEmpty ? HomeVibeCategories.fallback : model.vibeCategories
        if !categories.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("NYC vibes")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories) { category in
                            Button { router.askInChat(category.label) } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    if let hood = category.neighborhood, !hood.isEmpty {
                                        Text(hood)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    Text(category.label)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(maxWidth: 180, alignment: .leading)
                                .background(Theme.chipBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private var content: some View {
        if model.isLoading && model.restaurants.isEmpty {
            Spacer(); FoodPunLoadingView(quotes: LoadingQuotes.general); Spacer()
        } else if let error = model.errorMessage, model.restaurants.isEmpty {
            ErrorBanner(message: error) { reload() }
        } else if mode == .list {
            listView
        } else {
            ExploreMapView(restaurants: model.restaurants) { slug in
                path.append(RestaurantRoute(slug: slug))
            }
        }
    }

    private var listView: some View {
        ScrollView {
            if model.restaurants.isEmpty {
                Text("No spots match these filters.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(model.restaurants) { r in
                        VStack(spacing: 8) {
                            NavigationLink(value: RestaurantRoute(slug: r.slug)) {
                                RestaurantCard(restaurant: r)
                            }
                            .buttonStyle(.plain)

                            Button { router.reserve(r) } label: {
                                Label("Reserve a table", systemImage: "calendar.badge.plus")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                                    .background(Theme.accent.opacity(0.14))
                                    .foregroundStyle(Theme.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .refreshable { await model.load() }
    }

    private func reload() {
        Task { await model.load() }
    }
}

/// MapKit view with a marker per restaurant; tapping a marker opens detail.
struct ExploreMapView: View {
    let restaurants: [Restaurant]
    let onSelect: (String) -> Void

    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7308, longitude: -73.9973),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    )

    var body: some View {
        Map(position: $position) {
            ForEach(restaurants) { r in
                Annotation(r.name, coordinate: CLLocationCoordinate2D(latitude: r.latitude, longitude: r.longitude)) {
                    Button { onSelect(r.slug) } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.title2).foregroundStyle(Theme.accent)
                            Text(r.priceLabel).font(.caption2).fontWeight(.bold)
                        }
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .flat))
    }
}
