import SwiftUI
import SwiftData

struct GalleryVideoView: View {
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
        ScrollView {
            GalleryGridView(sets: filteredSets, generations: filteredGenerations, contentType: .VIDEO)
        }
        .toolbar {
            ToolbarItem {
                Menu {
                    Button("All Generations", action: { selectedSetType = nil })
                    Button(getSetTypeInfo(setType: .VIDEO_IMAGE).label, action: { selectedSetType = .VIDEO_IMAGE })
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }
        }
        .navigationTitle("Video Gallery")
    }
}
