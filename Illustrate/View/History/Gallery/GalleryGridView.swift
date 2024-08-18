import SwiftUI
import SwiftData

struct GalleryGridView: View {
    @Environment(\.modelContext) private var modelContext
    
    let sets: [ImageSet]
    let generations: [Generation]
    let contentType: EnumGenerationContentType
    
    #if os(iOS)
    typealias PlatformImage = UIImage
    #elseif os(macOS)
    typealias PlatformImage = NSImage
    #endif
    
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
            return Array(repeating: GridItem(.flexible(), spacing: 2), count: 5)
            #else
            return Array(repeating: GridItem(.flexible(), spacing: 2), count: 2)
            #endif
        }()
        
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(generations.filter { $0.contentType == contentType }, id: \.id) { generation in
                if let image = loadImageFromDocumentsDirectory(withName: "\(generation.id.uuidString)_o20") {
                    ImageCellView(image: image, generation: generation)
                        .onTapGesture {
                            selectedGeneration = generation
                            isNavigationActive = true
                        }
                } else {
                    Color(.clear)
                        .frame(maxWidth: .infinity, maxHeight: 200)
                }
            }
        }
        .navigationDestination(isPresented: $isNavigationActive) {
            if (selectedGeneration != nil) {
                if (selectedGeneration!.contentType == .IMAGE_2D) {
                    GenerationImageView(setId: selectedGeneration!.setId)
                } else {
                    GenerationVideoView(setId: selectedGeneration!.setId)
                }
            }
        }
    }
}
