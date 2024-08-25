import SwiftUI

struct ICloudImageLoader<Content: View>: View {
    let imageName: String
    let content: (PlatformImage?) -> Content
    
    @State private var image: PlatformImage?
    @State private var isLoading = true
    
    init(imageName: String, @ViewBuilder content: @escaping (PlatformImage?) -> Content) {
        self.imageName = imageName
        self.content = content
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(width: 20, height: 20)
                    .padding()
            } else {
                content(image)
            }
        }
        .onAppear {
            load()
        }
    }

    private func load() {
        DispatchQueue.global(qos: .background).async {
            let loadedImage = loadImageFromiCloud(imageName)
            DispatchQueue.main.async {
                self.image = loadedImage
                self.isLoading = false
            }
        }
    }
}
