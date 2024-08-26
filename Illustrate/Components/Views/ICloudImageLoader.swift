import SwiftUI

class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, PlatformImage>()
    private var failedAttempts = Set<String>()
    
    func set(_ image: PlatformImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
        failedAttempts.remove(key)
    }
    
    func get(forKey key: String) -> PlatformImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func setFailedAttempt(forKey key: String) {
        failedAttempts.insert(key)
    }
    
    func isFailedAttempt(forKey key: String) -> Bool {
        return failedAttempts.contains(key)
    }
}

struct ICloudImageLoader<Content: View>: View {
    let imageName: String
    let content: (PlatformImage?) -> Content
    
    @State private var image: PlatformImage? = nil
    @State private var isLoading = true
    
    init(imageName: String, @ViewBuilder content: @escaping (PlatformImage?) -> Content) {
        self.imageName = imageName
        self.content = content
        
        if let cachedImage = ImageCache.shared.get(forKey: imageName) {
            _image = State(initialValue: cachedImage)
            _isLoading = State(initialValue: false)
        } else if ImageCache.shared.isFailedAttempt(forKey: imageName) {
            _image = State(initialValue: nil)
            _isLoading = State(initialValue: false)
        }
    }
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(width: 20, height: 20)
            } else {
                content(image)
            }
        }
        .onAppear {
            if (image == nil && isLoading) {
                load()
            }
        }
    }
    
    private func load() {
        DispatchQueue.global(qos: .background).async {
            let loadedImage = loadImageFromiCloud(imageName)
            DispatchQueue.main.async {
                if let loadedImage = loadedImage {
                    ImageCache.shared.set(loadedImage, forKey: imageName)
                    self.image = loadedImage
                } else {
                    ImageCache.shared.setFailedAttempt(forKey: imageName)
                    self.image = nil
                }
                self.isLoading = false
            }
        }
    }
}
