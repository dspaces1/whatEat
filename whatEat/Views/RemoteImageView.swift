import SwiftUI

struct RemoteImageView: View {
    let url: URL?
    var contentMode: ContentMode = .fill
    var showsPlaceholderIcon = true
    var placeholderBackground = Color.gray.opacity(0.2)
    var placeholderIconName = "photo"
    var placeholderIconColor = Color.gray.opacity(0.5)
    var placeholderIconFont: Font = .title2

    @StateObject private var loader = ImageLoader()

    var body: some View {
        ZStack {
            placeholderBackground
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity)
            } else if showsPlaceholderIcon {
                Image(systemName: placeholderIconName)
                    .font(placeholderIconFont)
                    .foregroundColor(placeholderIconColor)
            }
        }
        .task(id: url) {
            loader.load(from: url)
        }
        .onDisappear {
            loader.cancel()
        }
    }
}
