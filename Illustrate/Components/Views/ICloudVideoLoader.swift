import SwiftUI

struct ICloudVideoLoader<Content: View>: View {
    let videoName: String
    let content: (URL?) -> Content
    
    @State private var url: URL?
    @State private var isLoading = true
    
    init(videoName: String, @ViewBuilder content: @escaping (URL?) -> Content) {
        self.videoName = videoName
        self.content = content
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(width: 20, height: 20)
                    .padding()
            } else {
                content(url)
            }
        }
        .onAppear {
            load()
        }
    }

    private func load() {
        DispatchQueue.global(qos: .background).async {
            let loadedUrl = loadVideoFromiCloud(videoName)
            DispatchQueue.main.async {
                self.url = loadedUrl
                self.isLoading = false
            }
        }
    }
}
