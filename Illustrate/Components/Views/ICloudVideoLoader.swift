import SwiftUI

class VideoCache {
    static let shared = VideoCache()
    private let cache = NSCache<NSString, NSURL>()
    private var failedAttempts = Set<String>()

    func set(_ url: URL, forKey key: String) {
        cache.setObject(url as NSURL, forKey: key as NSString)
        failedAttempts.remove(key)
    }

    func get(forKey key: String) -> URL? {
        return cache.object(forKey: key as NSString) as URL?
    }

    func setFailedAttempt(forKey key: String) {
        failedAttempts.insert(key)
    }

    func isFailedAttempt(forKey key: String) -> Bool {
        return failedAttempts.contains(key)
    }
}

struct ICloudVideoLoader<Content: View>: View {
    let videoName: String
    let content: (URL?) -> Content

    @State private var url: URL? = nil
    @State private var isLoading = true

    init(videoName: String, @ViewBuilder content: @escaping (URL?) -> Content) {
        self.videoName = videoName
        self.content = content

        if let cachedUrl = VideoCache.shared.get(forKey: videoName) {
            _url = State(initialValue: cachedUrl)
            _isLoading = State(initialValue: false)
        } else if VideoCache.shared.isFailedAttempt(forKey: videoName) {
            _url = State(initialValue: nil)
            _isLoading = State(initialValue: false)
        }
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(width: 20, height: 20)
            } else {
                content(url)
            }
        }
        .onAppear {
            if url == nil && isLoading {
                load()
            }
        }
    }

    private func load() {
        DispatchQueue.global(qos: .background).async {
            let loadedUrl = loadVideoFromiCloud(videoName)

            DispatchQueue.main.async {
                if let loadedUrl = loadedUrl {
                    VideoCache.shared.set(loadedUrl, forKey: videoName)
                    self.url = loadedUrl
                } else {
                    VideoCache.shared.setFailedAttempt(forKey: videoName)
                    self.url = nil
                }
                self.isLoading = false
            }
        }
    }
}
