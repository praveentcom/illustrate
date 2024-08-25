import SwiftData
import SwiftUI

struct GalleryGridView: View {
    @Environment(\.modelContext) private var modelContext

    let sets: [ImageSet]
    let generations: [Generation]
    let contentType: EnumGenerationContentType

    struct ImageCellView: View {
        let image: PlatformImage
        let generation: Generation

        var body: some View {
            #if os(macOS)
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
            #else
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
            #endif
        }
    }

    @State private var isNavigationActive: Bool = false
    @State private var selectedGeneration: Generation? = nil

    var body: some View {
        let columns: [GridItem] = {
            #if os(macOS)
                return Array(repeating: GridItem(.flexible(), spacing: 2), count: 6)
            #else
                return Array(repeating: GridItem(.flexible(), spacing: 2), count: UIDevice.current.userInterfaceIdiom == .pad ? 4 : 2)
            #endif
        }()

        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(generations.filter { $0.contentType == contentType }, id: \.id) { generation in
                ICloudImageLoader(imageName: ".\(generation.id.uuidString)_o20") { image in
                    if let image = image {
                        ImageCellView(image: image, generation: generation)
                            .onTapGesture {
                                selectedGeneration = generation
                                isNavigationActive = true
                            }
                    } else {
                        Color(secondaryLabel)
                            .frame(width: 20, height: 20)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
        }
        .navigationDestination(isPresented: $isNavigationActive) {
            if selectedGeneration != nil {
                if selectedGeneration!.contentType == .IMAGE_2D {
                    GenerationImageView(setId: selectedGeneration!.setId)
                } else {
                    GenerationVideoView(setId: selectedGeneration!.setId)
                }
            }
        }
    }
}
