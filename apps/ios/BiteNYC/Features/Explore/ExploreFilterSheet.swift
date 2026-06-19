import SwiftUI

struct ExploreFilterSheet: View {
    @ObservedObject var model: ExploreViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Location") {
                    Picker("Borough", selection: Binding(
                        get: { model.borough ?? "" },
                        set: { model.borough = $0.isEmpty ? nil : $0 }
                    )) {
                        Text("All").tag("")
                        ForEach(model.boroughs, id: \.self) { Text($0).tag($0) }
                    }
                    Picker("Neighborhood", selection: Binding(
                        get: { model.neighborhood ?? "" },
                        set: { model.neighborhood = $0.isEmpty ? nil : $0 }
                    )) {
                        Text("All").tag("")
                        ForEach(model.neighborhoodOptions) { Text($0.name).tag($0.name) }
                    }
                }

                Section("Budget") {
                    Picker("Max price", selection: Binding(
                        get: { model.maxPriceTier ?? 0 },
                        set: { model.maxPriceTier = $0 == 0 ? nil : $0 }
                    )) {
                        Text("Any").tag(0)
                        ForEach(1...4, id: \.self) { Text(String(repeating: "$", count: $0)).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Good for / open") {
                    Toggle("Open late", isOn: $model.openNow)
                    Toggle("Takes reservations", isOn: $model.reservationAvailable)
                }

                Section("Vibe") {
                    FlowLayout(spacing: 8) {
                        ForEach(model.vibeTags, id: \.self) { tag in
                            Button {
                                if model.selectedVibes.contains(tag) {
                                    model.selectedVibes.remove(tag)
                                } else {
                                    model.selectedVibes.insert(tag)
                                }
                            } label: {
                                TagChip(text: prettyTag(tag), selected: model.selectedVibes.contains(tag))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") { model.resetFilters() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Show results") {
                        dismiss()
                        Task { await model.load() }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
