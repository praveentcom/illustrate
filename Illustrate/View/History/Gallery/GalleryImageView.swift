import SwiftData
import SwiftUI

struct GalleryImageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ImageSet.createdAt, order: .reverse) private var sets: [ImageSet]
    @Query(sort: \Generation.createdAt, order: .reverse) private var generations: [Generation]

    @State private var selectedSetType: EnumSetType? = nil

    private var filteredSets: [ImageSet] {
        if let selectedSetType = selectedSetType {
            return sets.filter { $0.setType == selectedSetType }
        } else {
            return sets
        }
    }

    private var filteredGenerations: [Generation] {
        let filteredSetIds = filteredSets.map { $0.id }
        return generations.filter { filteredSetIds.contains($0.setId) }
    }

    var body: some View {
        VStack {
            if (filteredGenerations.filter { $0.contentType == .IMAGE_2D }.isEmpty) {
                Text("No requests.")
                    .opacity(0.5)
            } else {
                ScrollView {
                    GalleryGridView(sets: filteredSets, generations: filteredGenerations, contentType: .IMAGE_2D)
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Menu {
                    Button("All Generations", systemImage: "slider.horizontal.3", action: {
                        DispatchQueue.main.async {
                            selectedSetType = nil
                        }
                    })
                    ForEach(sectionItems(section: EnumNavigationSection.ImageGenerations)) { item in
                        Button(labelForItem(item), systemImage: iconForItem(item)) {
                            DispatchQueue.main.async {
                                selectedSetType = setTypeForItem(item)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }
        }
        .navigationTitle(labelForItem(.historyImageGallery))
    }
}
