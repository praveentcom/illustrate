import SwiftUI
import SwiftData

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
        ScrollView {
            GalleryGridView(sets: filteredSets, generations: filteredGenerations, contentType: .IMAGE_2D)
        }
        .toolbar {
            ToolbarItem {
                Menu {
                    Button("All Generations", action: { selectedSetType = nil })
                    Button(getSetTypeInfo(setType: .GENERATE).label, action: { selectedSetType = .GENERATE })
                    Button(getSetTypeInfo(setType: .EDIT_UPSCALE).label, action: { selectedSetType = .EDIT_UPSCALE })
                    Button(getSetTypeInfo(setType: .EDIT_EXPAND).label, action: { selectedSetType = .EDIT_EXPAND })
                    Button(getSetTypeInfo(setType: .EDIT_MASK).label, action: { selectedSetType = .EDIT_MASK })
                    Button(getSetTypeInfo(setType: .EDIT_MASK_ERASE).label, action: { selectedSetType = .EDIT_MASK_ERASE })
                    Button(getSetTypeInfo(setType: .EDIT_REPLACE).label, action: { selectedSetType = .EDIT_REPLACE })
                    Button(getSetTypeInfo(setType: .REMOVE_BACKGROUND).label, action: { selectedSetType = .REMOVE_BACKGROUND })
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }
        }
        .navigationTitle("Image Gallery")
    }
}
