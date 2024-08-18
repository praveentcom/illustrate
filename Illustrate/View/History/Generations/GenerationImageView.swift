import SwiftUI
import SwiftData
import UniformTypeIdentifiers

#if os(macOS)
import AppKit
#else
import UIKit

struct UIImageFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.png] }
    
    var image: UIImage
    
    init(image: UIImage) {
        self.image = image
    }
    
    init(configuration: ReadConfiguration) throws {
        self.image = UIImage()
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = image.pngData()!
        return FileWrapper(regularFileWithContents: data)
    }
}

struct ImageShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImageShareSheet>) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ImageShareSheet>) {}
}
#endif

struct MaskView: View {
    var maskImage: PlatformImage
    
    var body: some View {
#if os(macOS)
        Image(nsImage: maskImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(maxHeight: 400)
            .frame(maxWidth: .infinity)
            .opacity(0.4)
#else
        Image(uiImage: maskImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .opacity(0.4)
#endif
    }
}

struct GenerationImageView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) private var presentationMode
    
    @State var setId: UUID
    @State private var imageSet: ImageSet?
    @State private var generations: [Generation] = []
    @State private var generationIndex: Int = 0
    
    @State private var showMask: Bool = false
    @State private var showDeleteConfirmation = false
    @State private var showDocumentPicker = false
    @State private var showShareSheet = false
    
    @Query(sort: \ImageSet.createdAt) private var allImageSets: [ImageSet]
    @Query(sort: \Generation.createdAt, order: .reverse) private var allGenerations: [Generation]
    
    func getSelectedGeneration() -> Generation? {
        if generationIndex >= 0 && generationIndex < generations.count {
            return generations[generationIndex]
        }
        return nil
    }
    
    func deleteImageSet() async -> Void {
        modelContext.delete(imageSet!)
        for generation in generations {
            modelContext.delete(generation)
        }
        try? modelContext.save()
        
        presentationMode.wrappedValue.dismiss()
    }
    
    var body: some View {
        Form {
            if (getSelectedGeneration() != nil || imageSet != nil) {
                let image = loadImageFromDocumentsDirectory(withName: "\(getSelectedGeneration()!.id.uuidString)_o50")
                let requestImage = loadImageFromDocumentsDirectory(withName: "\(getSelectedGeneration()!.id.uuidString)_client")
                let maskImage = loadImageFromDocumentsDirectory(withName: "\(getSelectedGeneration()!.id.uuidString)_mask")
                
                Section {
                    ZStack {
                        if let colorPalette = getSelectedGeneration()?.colorPalette {
                            SmoothAnimatedGradientView(colors: colorPalette.compactMap { hex in
                                Color(getUniversalColorFromHex(hexString: hex))
                            })
                        }
                        
                        HStack (spacing: 16) {
#if os(macOS)
                            if let requestImage = requestImage {
                                VStack (spacing: 16) {
                                    Image(nsImage: requestImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .frame(maxHeight: 400)
                                        .overlay {
                                            if (showMask && maskImage != nil) {
                                                MaskView(maskImage: maskImage!)
                                            }
                                        }
                                        .shadow(color: .black.opacity(0.4), radius: 8)
                                        .frame(maxWidth: .infinity)
                                    HStack (spacing: 8) {
                                        HStack {
                                            Image(systemName: "info.circle")
                                            Text("Request Image")
                                        }
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(.thinMaterial)
                                        .cornerRadius(8)
                                        
                                        if (maskImage != nil) {
                                            Toggle(isOn: $showMask) {
                                                Text("Show Mask")
                                            }
                                            .toggleStyle(IllustrateToggleStyle())
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 8)
                                            .background(.thinMaterial)
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                            }
#endif
                            if let image = image {
                                VStack (spacing: 16) {
#if os(macOS)
                                    Image(nsImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .frame(maxHeight: 400)
                                        .shadow(color: .black.opacity(0.4), radius: 8)
                                        .frame(maxWidth: .infinity)
                                    if (requestImage != nil || maskImage != nil) {
                                        HStack {
                                            Image(systemName: "info.circle")
                                            Text("Generated Image")
                                        }
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(.thinMaterial)
                                        .cornerRadius(8)
                                    }
#else
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
#endif
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    if generations.count > 1 {
                        Picker("Select Image", selection: $generationIndex) {
                            ForEach(0..<generations.count, id: \.self) { index in
                                Text("\(index + 1)").tag(index)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding()
                    }
                }
                
                Section("User Prompts") {
                    SectionKeyValueView(icon: "text.quote", key: "Requested Prompt", value: getSelectedGeneration()!.prompt)
                    if (getSelectedGeneration()!.negativePrompt != nil) {
                        SectionKeyValueView(icon: "text.badge.minus", key: "Negative Prompt", value: getSelectedGeneration()!.negativePrompt!)
                    }
                    if (getSelectedGeneration()!.searchPrompt != nil) {
                        SectionKeyValueView(icon: "rectangle.and.text.magnifyingglass", key: "Search Prompt", value: getSelectedGeneration()!.searchPrompt!)
                    }
                }
                
                Section("Auto Enhance") {
                    SectionKeyValueView(icon: "sparkles", key: "Auto-enhance Opted", value: getSelectedGeneration()!.promptEnhanceOpted ? "Yes" : "No")
                    if (getSelectedGeneration()!.promptEnhanceOpted) {
                        SectionKeyValueView(icon: "text.quote", key: "Enhanced Prompt", value: getSelectedGeneration()!.promptAfterEnhance)
                    }
                }
                Section("Model Response") {
                    SectionKeyValueView(icon: "text.quote", key: "Response Prompt", value: getSelectedGeneration()!.modelRevisedPrompt ?? getSelectedGeneration()!.prompt)
                    SectionKeyValueView(icon: "dollarsign", key: "Cost", value: "\(getSelectedGeneration()!.creditUsed)")
                }
                Section("Image Metadata") {
                    SectionKeyValueView(icon: "arrow.down.left.and.arrow.up.right.rectangle", key: "Image Dimensions", value: getSelectedGeneration()!.artDimensions)
                    SectionKeyValueView(
                        icon: "internaldrive",
                        key: "Image Size",
                        value: String(format: "%.2f MB", Double(getSelectedGeneration()!.size) / 1000000.0)
                    )
                    SectionKeyValueView(icon: "paintpalette", key: "Color Style", value: getSelectedGeneration()!.artStyle.rawValue)
                    SectionKeyValueView(icon: "photo", key: "Quality", value: getSelectedGeneration()!.artQuality.rawValue)
                    SectionKeyValueView(icon: "photo.on.rectangle.angled.fill", key: "Art Style", value: getSelectedGeneration()!.artVariant.rawValue)
                }
                Section("Other Metadata") {
                    SectionKeyValueView(icon: "calendar", key: "Created", value: getSelectedGeneration()!.createdAt.formatted(
                        date: .numeric,
                        time: .shortened
                    ))
                }
            } else {
                Section("Image Details") {
                    Text("Loading...")
                }
                .onAppear {
                    loadData()
                }
            }
        }
        .formStyle(.grouped)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Download", systemImage: "arrow.down") {
                    let image = loadImageFromDocumentsDirectory(withName: "\(getSelectedGeneration()!.id.uuidString)")
                    if let image = image {
                        Task {
                            #if os(macOS)
                            image.saveImageToDownloads(fileName: getSelectedGeneration()!.id.uuidString)
                            #else
                            showDocumentPicker = true
                            #endif
                        }
                    }
                }
            }
            ToolbarItem(placement: .automatic) {
                Button("Share", systemImage: "square.and.arrow.up") {
                    let image = loadImageFromDocumentsDirectory(withName: "\(getSelectedGeneration()!.id.uuidString)")
                    if let image = image {
                        Task {
                            #if os(macOS)
                            image.shareImage()
                            #else
                            showShareSheet = true
                            #endif
                        }
                    }
                }
            }
            ToolbarItem(placement: .destructiveAction) {
                Button("Delete", systemImage: "trash") {
                    showDeleteConfirmation = true
                }
            }
        }
        #if !os(macOS)
        .fileExporter(
            isPresented: $showDocumentPicker,
            document: UIImageFileDocument(
                image: loadImageFromDocumentsDirectory(withName: "\(getSelectedGeneration()?.id.uuidString ?? "")") ?? PlatformImage()
            ),
            contentType: .png,
            defaultFilename: "illustrate_\(getSelectedGeneration()?.id.uuidString ?? "")"
        ) { result in
            switch result {
            case .success(let url):
                print("Saved to \(url)")
            case .failure(let error):
                print("Failed to save image: \(error.localizedDescription)")
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = loadImageFromDocumentsDirectory(withName: "\(getSelectedGeneration()?.id.uuidString ?? "")") {
                ImageShareSheet(activityItems: [image])
            }
        }
        #endif
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Confirm Deletion"),
                message: Text("Are you sure you want to delete this image set?"),
                primaryButton: .destructive(Text("Delete")) {
                    Task {
                        await deleteImageSet()
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .navigationTitle("Image Generation")
    }
    
    private func loadData() {
        imageSet = allImageSets.first { $0.id == setId }
        generations = allGenerations.filter { $0.setId == setId }
    }
}
