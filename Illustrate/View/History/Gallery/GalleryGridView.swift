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
        let setType: EnumSetType?
        @State private var isHovered: Bool = false

        var body: some View {
            #if os(macOS)
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .overlay(
                        Color(systemBackground).opacity(isHovered ? 0.1 : 0)
                    )
                    .overlay(alignment: .bottomTrailing) {
                        if let setType = setType {
                            GenerationTypeOverlay(setType: setType)
                                .padding(6)
                        }
                    }
                    .onHover { hovering in
                        isHovered = hovering
                    }
            #else
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: .bottomTrailing) {
                        if let setType = setType {
                            GenerationTypeOverlay(setType: setType)
                                .padding(6)
                        }
                    }
            #endif
        }
    }
    
    struct GenerationTypeOverlay: View {
        let setType: EnumSetType
        
        var body: some View {
            Image(systemName: iconForSetType(setType))
                .font(.title3)
                .foregroundColor(Color(label))
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(systemBackground).opacity(0.7))
                )
        }
    }

    private func setType(for generation: Generation) -> EnumSetType? {
        return sets.first(where: { $0.id == generation.setId })?.setType
    }

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
                        NavigationLink(
                            value: generation.contentType == .IMAGE_2D ? EnumNavigationItem.generationImage(setId: generation.setId) : EnumNavigationItem.generationVideo(setId: generation.setId)
                        ) {
                            ImageCellView(image: image, generation: generation, setType: setType(for: generation))
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        Color(secondaryLabel)
                            .frame(width: 20, height: 20)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                .id("grid_\(generation.id.uuidString)")
            }
        }
    }
}
