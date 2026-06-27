import SwiftUI

/// Full menu on its own screen — grouped by course, like Google Maps.
struct FullMenuView: View {
    let restaurantName: String
    let dishes: [Dish]

    var body: some View {
        ScrollView {
            MenuGroupedList(dishes: dishes)
                .padding(.vertical)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Menu")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Reusable grouped menu list (detail preview + full menu screen).
struct MenuGroupedList: View {
    let dishes: [Dish]

    var body: some View {
        let grouped = Dictionary(grouping: dishes) { MenuCourse.from($0.dishType) }
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Spacer()
                Text("\(dishes.count) item\(dishes.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            ForEach(MenuCourse.allCases) { course in
                if let items = grouped[course], !items.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Label(course.title, systemImage: course.icon)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Theme.accent)
                            .padding(.horizontal)

                        ForEach(items.sorted { ($0.rank ?? 0) < ($1.rank ?? 0) }) { dish in
                            MenuDishRow(dish: dish)
                        }
                    }
                }
            }
        }
    }
}

struct MenuDishRow: View {
    let dish: Dish

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(dish.name).font(.subheadline).fontWeight(.semibold)
                if dish.isMustTry == true {
                    Image(systemName: "star.fill").font(.caption2).foregroundStyle(Theme.warn)
                }
                Spacer()
            }
            if let desc = dish.description ?? dish.whyTry, !desc.isEmpty {
                Text(desc).font(.caption).foregroundStyle(.secondary)
            }
            Divider().opacity(0.4)
        }
        .padding(.horizontal)
    }
}
