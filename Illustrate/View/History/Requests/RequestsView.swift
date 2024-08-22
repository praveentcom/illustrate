import SwiftUI
import SwiftData

struct RequestsView: View {
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

    @State private var filteredGenerations: [Generation] = []
    
    struct ImageCellView: View {
        let image: PlatformImage
        let generation: Generation
        
        var body: some View {
            #if os(macOS)
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 20)
            #else
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 20)
            #endif
            
        }
    }
    
    @State private var isNavigationActive: Bool = false
    @State private var selectedGeneration: Generation? = nil
    
    @State private var sortOrder = [KeyPathComparator(\Generation.createdAt)]
    
    @TableColumnBuilder<Generation, KeyPathComparator<Generation>>
    var prefixColumns: some TableColumnContent<Generation, KeyPathComparator<Generation>> {
        TableColumn("Spot", value: \.id) { generation in
            if let image = loadImageFromDocumentsDirectory(withName: "\(generation.id.uuidString)_o20") {
                ImageCellView(image: image, generation: generation)
            } else {
                Color(.clear)
                    .frame(width: 20, height: 20)
            }
        }
        .width(min: 24, ideal: 32, max: 40)
        TableColumn("Date", value: \.createdAt) { generation in
            Text(generation.createdAt.formatted(date: .abbreviated, time: .shortened))
        }
        .width(min: 180, ideal: 180, max: 180)
    }
    
    @TableColumnBuilder<Generation, KeyPathComparator<Generation>>
    var modelInfoColumns: some TableColumnContent<Generation, KeyPathComparator<Generation>> {
        TableColumn("Partner", value: \.modelId) { generation in
            if let partner = getPartner(modelId: generation.modelId) {
                HStack {
                    Image("\(partner.partnerCode)_square".lowercased())
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text(partner.partnerName)
                }
            }
        }
        .width(min: 160, ideal: 160, max: 200)
        TableColumn("Model", value: \.modelId) { generation in
            Text(getModel(modelId: generation.modelId)?.modelName ?? "N/A")
        }
        .width(min: 160, ideal: 160, max: 200)
    }
    
    @TableColumnBuilder<Generation, KeyPathComparator<Generation>>
    var promptColumns: some TableColumnContent<Generation, KeyPathComparator<Generation>> {
        TableColumn("Prompt", value: \.prompt) { generation in
            if !generation.prompt.isEmpty {
                Text(generation.prompt)
            } else {
                Text("Prompt not added")
                    .opacity(0.5)
            }
        }
        .width(min: 400, ideal: 400, max: 800)
    }
    
    @TableColumnBuilder<Generation, KeyPathComparator<Generation>>
    var generationInfoColumns: some TableColumnContent<Generation, KeyPathComparator<Generation>> {
        TableColumn("Dimensions", value: \.artDimensions) { generation in
            Text("\(generation.artDimensions.replacingOccurrences(of: "x", with: " x "))")
                .monospaced()
        }
        .width(min: 160, ideal: 160, max: 160)
        TableColumn("Size", value: \.size) { generation in
            Text(String(format: "%.2f MB", Double(generation.size) / 1000000.0))
                .monospaced()
        }
        .width(min: 120, ideal: 120, max: 120)
        TableColumn("Cost", value: \.creditUsed) { generation in
            Text("\(String(format: "%.2f", generation.creditUsed).replacingOccurrences(of: ".00", with: "")) \(getPartner(modelId: generation.modelId)?.creditCurrency.rawValue ?? "Credits")")
        }
        .width(min: 120, ideal: 120, max: 120)
        TableColumn("Color Style", value: \.artStyle.rawValue)
            .width(min: 120, ideal: 120, max: 120)
        TableColumn("Art Variant", value: \.artVariant.rawValue)
            .width(min: 160, ideal: 160, max: 240)
        TableColumn("Quality", value: \.artQuality.rawValue) { generation in
            Text(generation.artQuality.rawValue)
                .monospaced()
        }
        .width(min: 80, ideal: 80, max: 80)
    }
    
    @TableColumnBuilder<Generation, KeyPathComparator<Generation>>
    var otherColumns: some TableColumnContent<Generation, KeyPathComparator<Generation>> {
        TableColumn("Status", value: \.status.rawValue)
            .width(min: 120, ideal: 120, max: 120)
    }
    
    @TableColumnBuilder<Generation, KeyPathComparator<Generation>>
    var actionColumns: some TableColumnContent<Generation, KeyPathComparator<Generation>> {
        TableColumn("Actions", value: \.id) { generation in
            Button("View") {
                selectedGeneration = generation
                isNavigationActive = true
            }
            .buttonStyle(BorderedButtonStyle())
        }
        .width(min: 120, ideal: 120, max: 120)
    }

    var body: some View {
        Table(of: Generation.self, sortOrder: $sortOrder) {
            prefixColumns
            modelInfoColumns
            promptColumns
            generationInfoColumns
            otherColumns
            actionColumns
        } rows: {
            ForEach(filteredGenerations) { generation in
                TableRow(generation)
                    .contextMenu {
                        Button("View") {
                            selectedGeneration = generation
                            isNavigationActive = true
                        }
                    }
            }
        }
        .onChange(of: sortOrder) {
             filteredGenerations.sort(using: sortOrder)
        }
        .onAppear {
            let filteredSetIds = filteredSets.map { $0.id }
            filteredGenerations = generations.filter { filteredSetIds.contains($0.setId) }
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
        .navigationTitle("All Requests")
    }
}
