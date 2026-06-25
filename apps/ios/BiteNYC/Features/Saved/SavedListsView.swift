import SwiftUI

struct SavedListsView: View {
    @EnvironmentObject private var store: SavedListsStore
    @State private var showNewList = false
    @State private var newListName = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.lists) { list in
                    NavigationLink(value: list) {
                        HStack {
                            Text(list.emoji).font(.title3)
                            VStack(alignment: .leading) {
                                Text(list.name).fontWeight(.medium)
                                Text("\(list.restaurants.count) place\(list.restaurants.count == 1 ? "" : "s")")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .onDelete { offsets in
                    offsets.map { store.lists[$0].id }.forEach(store.deleteList)
                }
            }
            .navigationTitle("Saved")
            .navigationDestination(for: SavedList.self) { list in
                SavedListDetailView(listId: list.id)
            }
            .navigationDestination(for: RestaurantRoute.self) { RestaurantDetailView(slug: $0.slug) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewList = true } label: { Image(systemName: "plus") }
                }
            }
            .alert("New list", isPresented: $showNewList) {
                TextField("List name", text: $newListName)
                Button("Create") {
                    let name = newListName.trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty { store.createList(name: name) }
                    newListName = ""
                }
                Button("Cancel", role: .cancel) { newListName = "" }
            }
        }
    }
}

struct SavedListDetailView: View {
    let listId: UUID
    @EnvironmentObject private var store: SavedListsStore

    private var list: SavedList? { store.lists.first { $0.id == listId } }

    var body: some View {
        Group {
            if let list, !list.restaurants.isEmpty {
                List {
                    ForEach(list.restaurants) { r in
                        NavigationLink(value: RestaurantRoute(slug: r.slug)) {
                            HStack(spacing: 12) {
                                RemoteImage(url: r.heroImageURL)
                                    .frame(width: 54, height: 54).clipShape(RoundedRectangle(cornerRadius: 10))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(r.name).fontWeight(.medium)
                                    HStack(spacing: 6) {
                                        Text("\(r.neighborhood) · \(r.borough)")
                                            .font(.caption).foregroundStyle(.secondary)
                                        if let t = r.priceTier, t > 0 {
                                            Text(String(repeating: "$", count: t)).font(.caption).foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .onDelete { offsets in
                        offsets.map { list.restaurants[$0].id }.forEach { store.remove($0, from: listId) }
                    }
                }
            } else {
                ContentUnavailableView(
                    "No places yet",
                    systemImage: "bookmark",
                    description: Text("Save restaurants from search, explore, or a detail page.")
                )
            }
        }
        .navigationTitle(list.map { "\($0.emoji) \($0.name)" } ?? "List")
        .navigationBarTitleDisplayMode(.inline)
    }
}
