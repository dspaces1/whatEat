import Foundation
import UIKit
import Combine

final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSURL, UIImage>()

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func insert(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}

@MainActor
final class ImageLoader: ObservableObject {
    @Published private(set) var image: UIImage?
    @Published private(set) var isLoading = false

    private var task: Task<Void, Never>?
    private var currentURL: URL?

    func load(from url: URL?) {
        task?.cancel()
        task = nil

        guard let url else {
            image = nil
            currentURL = nil
            isLoading = false
            return
        }

        if currentURL == url, image != nil {
            return
        }

        currentURL = url
        image = nil

        if let cached = ImageCache.shared.image(for: url) {
            image = cached
            isLoading = false
            return
        }

        isLoading = true
        task = Task {
            defer { isLoading = false }
            var request = URLRequest(url: url)
            request.cachePolicy = .returnCacheDataElseLoad
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode),
                      let uiImage = UIImage(data: data) else {
                    return
                }
                ImageCache.shared.insert(uiImage, for: url)
                if Task.isCancelled { return }
                image = uiImage
            } catch {
                if Task.isCancelled { return }
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}
