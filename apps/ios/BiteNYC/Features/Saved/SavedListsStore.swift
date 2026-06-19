import Foundation
import Combine

/// Lightweight snapshot of a restaurant stored inside a saved list so the Saved
/// tab can render without re-fetching from the API.
struct SavedRestaurant: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var slug: String
    var neighborhood: String
    var borough: String
    var priceTier: Int?
    var rating: Double?
    var heroImageURL: String?

    init(_ r: Restaurant) {
        id = r.id
        name = r.name
        slug = r.slug
        neighborhood = r.neighborhood
        borough = r.borough
        priceTier = r.priceTier
        rating = r.rating
        heroImageURL = r.heroImageURL
    }
}

struct SavedList: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var emoji: String
    var restaurants: [SavedRestaurant]

    init(id: UUID = UUID(), name: String, emoji: String, restaurants: [SavedRestaurant] = []) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.restaurants = restaurants
    }
}

@MainActor
final class SavedListsStore: ObservableObject {
    @Published private(set) var lists: [SavedList] = []

    private let defaultsKey = "bitenyc.savedLists.v1"
    private let quickSaveName = "Want to try"

    init() {
        load()
        if lists.isEmpty { seedSuggestedLists() }
    }

    // MARK: Queries

    func isSaved(_ restaurant: Restaurant) -> Bool {
        lists.contains { $0.restaurants.contains(where: { $0.id == restaurant.id }) }
    }

    func lists(containing restaurant: Restaurant) -> Set<UUID> {
        Set(lists.filter { $0.restaurants.contains(where: { $0.id == restaurant.id }) }.map(\.id))
    }

    // MARK: Mutations

    /// Toggles the restaurant in the default "Want to try" list.
    func toggleQuickSave(_ restaurant: Restaurant) {
        let listId = ensureQuickSaveList()
        guard let idx = lists.firstIndex(where: { $0.id == listId }) else { return }
        if let r = lists[idx].restaurants.firstIndex(where: { $0.id == restaurant.id }) {
            lists[idx].restaurants.remove(at: r)
        } else {
            lists[idx].restaurants.insert(SavedRestaurant(restaurant), at: 0)
        }
        persist()
    }

    func add(_ restaurant: Restaurant, to listId: UUID) {
        guard let idx = lists.firstIndex(where: { $0.id == listId }) else { return }
        guard !lists[idx].restaurants.contains(where: { $0.id == restaurant.id }) else { return }
        lists[idx].restaurants.insert(SavedRestaurant(restaurant), at: 0)
        persist()
    }

    func remove(_ restaurantId: String, from listId: UUID) {
        guard let idx = lists.firstIndex(where: { $0.id == listId }) else { return }
        lists[idx].restaurants.removeAll { $0.id == restaurantId }
        persist()
    }

    @discardableResult
    func createList(name: String, emoji: String = "📍") -> UUID {
        let list = SavedList(name: name, emoji: emoji)
        lists.append(list)
        persist()
        return list.id
    }

    func deleteList(_ listId: UUID) {
        lists.removeAll { $0.id == listId }
        persist()
    }

    // MARK: Private

    private func ensureQuickSaveList() -> UUID {
        if let existing = lists.first(where: { $0.name == quickSaveName }) { return existing.id }
        return createList(name: quickSaveName, emoji: "🔖")
    }

    private func seedSuggestedLists() {
        lists = [
            SavedList(name: quickSaveName, emoji: "🔖"),
            SavedList(name: "Date night", emoji: "🕯️"),
            SavedList(name: "Cafes to try", emoji: "☕️"),
            SavedList(name: "Friends visiting NYC", emoji: "🗽"),
            SavedList(name: "Birthday dinner ideas", emoji: "🎂"),
            SavedList(name: "Late-night spots", emoji: "🌙"),
        ]
        persist()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([SavedList].self, from: data) else { return }
        lists = decoded
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(lists) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }
}
