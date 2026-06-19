import SwiftUI
import MapKit

struct ExploreView: View {
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
    private var content: some View {
        if model.isLoading && model.restaurants.isEmpty {
            Spacer(); ProgressView("Loading NYC spots…"); Spacer()
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
                        NavigationLink(value: RestaurantRoute(slug: r.slug)) {
                            RestaurantCard(restaurant: r)
                        }
                        .buttonStyle(.plain)
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
