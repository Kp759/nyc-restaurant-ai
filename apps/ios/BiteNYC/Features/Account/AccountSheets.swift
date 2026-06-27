import SwiftUI

// MARK: - Edit profile

struct EditProfileSheet: View {
    @EnvironmentObject private var account: AccountStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var tagline = ""
    @State private var homeNeighborhood = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Your profile") {
                    TextField("Name", text: $name)
                    TextField("Tagline (e.g. NYC food explorer)", text: $tagline)
                    TextField("Home neighborhood", text: $homeNeighborhood)
                }
            }
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                name = account.profile.name
                tagline = account.profile.tagline
                homeNeighborhood = account.profile.homeNeighborhood
            }
        }
    }

    private func save() {
        var p = account.profile
        p.name = name.trimmingCharacters(in: .whitespaces)
        p.tagline = tagline.trimmingCharacters(in: .whitespaces)
        p.homeNeighborhood = homeNeighborhood.trimmingCharacters(in: .whitespaces)
        account.updateProfile(p)
        dismiss()
    }
}

// MARK: - Vibe editor

struct VibeEditorSheet: View {
    @EnvironmentObject private var account: AccountStore
    @Environment(\.dismiss) private var dismiss

    @State private var vibes: Set<String> = []
    @State private var cuisines: Set<String> = []
    @State private var priceCeiling = 4

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    group("Your vibe", options: VibeProfile.vibeOptions, selection: $vibes)
                    group("Favorite cuisines", options: VibeProfile.cuisineOptions, selection: $cuisines)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Budget").sectionHeaderStyle()
                        HStack(spacing: 8) {
                            ForEach(1...4, id: \.self) { tier in
                                Button {
                                    priceCeiling = (priceCeiling == tier) ? 4 : tier
                                } label: {
                                    Text(tier == 4 ? "Any" : "≤ " + String(repeating: "$", count: tier))
                                        .font(.subheadline.weight(.medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(priceCeiling == tier ? Theme.accent.opacity(0.2) : Theme.chipBackground)
                                        .foregroundStyle(priceCeiling == tier ? Theme.accent : .secondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("What's your vibe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear {
                vibes = Set(account.vibe.vibes)
                cuisines = Set(account.vibe.cuisines)
                priceCeiling = account.vibe.priceCeiling
            }
        }
    }

    private func group(_ title: String, options: [String], selection: Binding<Set<String>>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).sectionHeaderStyle()
            FlowLayout(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    let isOn = selection.wrappedValue.contains(option)
                    Button {
                        if isOn { selection.wrappedValue.remove(option) }
                        else { selection.wrappedValue.insert(option) }
                    } label: {
                        TagChip(text: prettyTag(option), selected: isOn)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func save() {
        var v = account.vibe
        v.vibes = VibeProfile.vibeOptions.filter { vibes.contains($0) }
        v.cuisines = VibeProfile.cuisineOptions.filter { cuisines.contains($0) }
        v.priceCeiling = priceCeiling
        account.updateVibe(v)
        dismiss()
    }
}

// MARK: - Reserve a table

struct ReserveSheet: View {
    let restaurant: Restaurant

    @EnvironmentObject private var account: AccountStore
    @EnvironmentObject private var router: AppRouter
    @Environment(\.dismiss) private var dismiss

    @State private var date = ReserveSheet.defaultDate
    @State private var partySize = 2
    @State private var occasion = "none"
    @State private var confirmed = false

    private static var defaultDate: Date {
        let cal = Calendar.current
        let tomorrow = cal.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return cal.date(bySettingHour: 19, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }

    private let occasions = ["none", "date_night", "birthday", "business", "friends", "solo", "celebration"]

    var body: some View {
        NavigationStack {
            Group {
                if confirmed { confirmationView } else { formView }
            }
            .navigationTitle(confirmed ? "Reserved!" : "Reserve a table")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !confirmed {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var formView: some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    RemoteImage(url: restaurant.heroImageURL)
                        .frame(width: 50, height: 50).clipShape(RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(restaurant.name).fontWeight(.semibold)
                        Text("\(restaurant.neighborhood) · \(restaurant.borough)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Section("Details") {
                DatePicker("Date & time", selection: $date, in: Date()...)
                Stepper("Party of \(partySize)", value: $partySize, in: 1...12)
                Picker("Occasion", selection: $occasion) {
                    ForEach(occasions, id: \.self) { o in
                        Text(o == "none" ? "No occasion" : prettyTag(o)).tag(o)
                    }
                }
            }
            Section {
                Button {
                    account.addReservation(
                        for: restaurant, date: date, partySize: partySize,
                        occasion: occasion == "none" ? nil : occasion
                    )
                    withAnimation { confirmed = true }
                } label: {
                    Label("Confirm reservation", systemImage: "calendar.badge.plus")
                        .frame(maxWidth: .infinity).fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent).tint(Theme.accent)
            }
            if let links = restaurant.bookingLinks, !links.isEmpty {
                Section("Or book with a provider") {
                    ForEach(links) { BookingButton(link: $0) }
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
            }
        }
    }

    private var confirmationView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64)).foregroundStyle(Theme.good)
            Text("Table reserved").font(.display(.title3, weight: .bold))
            Text("\(restaurant.name) · party of \(partySize)")
                .font(.subheadline).foregroundStyle(.secondary)
            Text(date.formatted(date: .complete, time: .shortened))
                .font(.subheadline).foregroundStyle(Theme.accent)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                Button {
                    dismiss()
                    router.selectedTab = .account
                } label: {
                    Text("View in Account").frame(maxWidth: .infinity).fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent).tint(Theme.accent)

                Button("Done") { dismiss() }.tint(Theme.accent)
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Write a review

struct WriteReviewSheet: View {
    let restaurant: Restaurant

    @EnvironmentObject private var account: AccountStore
    @Environment(\.dismiss) private var dismiss

    @State private var rating = 5
    @State private var text = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(restaurant.name).font(.headline)
                    HStack {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= rating ? "star.fill" : "star")
                                .font(.title2).foregroundStyle(Theme.warn)
                                .onTapGesture { rating = i }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                Section("Your review") {
                    TextField("What did you think? Dishes, vibe, service…",
                              text: $text, axis: .vertical)
                        .lineLimit(4...10)
                }
            }
            .navigationTitle("Write a review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        account.saveReview(for: restaurant, rating: rating, text: text)
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let existing = account.review(for: restaurant) {
                    rating = existing.rating
                    text = existing.text
                }
            }
        }
    }
}
