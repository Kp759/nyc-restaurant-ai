import SwiftUI

struct AddToListSheet: View {
    let restaurant: Restaurant

    @EnvironmentObject private var store: SavedListsStore
    @Environment(\.dismiss) private var dismiss
    @State private var newListName = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(store.lists) { list in
                        let contained = store.lists(containing: restaurant).contains(list.id)
                        Button {
                            if contained {
                                store.remove(restaurant.id, from: list.id)
                            } else {
                                store.add(restaurant, to: list.id)
                            }
                        } label: {
                            HStack {
                                Text("\(list.emoji)  \(list.name)")
                                Spacer()
                                Text("\(list.restaurants.count)").foregroundStyle(.secondary)
                                Image(systemName: contained ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(contained ? Theme.accent : .secondary)
                            }
                        }
                        .tint(.primary)
                    }
                }

                Section("New list") {
                    HStack {
                        TextField("List name", text: $newListName)
                        Button("Add") {
                            let name = newListName.trimmingCharacters(in: .whitespaces)
                            guard !name.isEmpty else { return }
                            let id = store.createList(name: name)
                            store.add(restaurant, to: id)
                            newListName = ""
                        }
                        .disabled(newListName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .navigationTitle("Save to list")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }
}
