import SwiftUI

/// Full-screen swipeable photo viewer for restaurant media.
struct PhotoGalleryViewer: View {
    let photos: [MediaItem]
    @Binding var selectedIndex: Int?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            TabView(selection: Binding(
                get: { selectedIndex ?? 0 },
                set: { selectedIndex = $0 }
            )) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    ZoomablePhoto(url: photo.url)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: photos.count > 1 ? .automatic : .never))
            .background(Color.black.ignoresSafeArea())
            .navigationTitle(photos.count > 1 ? "\((selectedIndex ?? 0) + 1) of \(photos.count)" : "Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

private struct ZoomablePhoto: View {
    let url: String?

    var body: some View {
        GeometryReader { geo in
            RemoteImage(url: url, contentMode: .fit)
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
