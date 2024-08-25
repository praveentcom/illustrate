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
    @State private var imageSet: ImageSet? = nil
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
            
            deleteICloudDocuments(containingSubstring: generation.id.uuidString)
        }
        try? modelContext.save()
        
        presentationMode.wrappedValue.dismiss()
    }
    
    var body: some View {
        Form {
            if (getSelectedGeneration() != nil || imageSet != nil) {
                Section {
                    ZStack {
                        if let colorPalette = getSelectedGeneration()?.colorPalette {
                            SmoothAnimatedGradientView(colors: colorPalette.compactMap { hex in
                                Color(getUniversalColorFromHex(hexString: hex))
                            })
                        }
                        
                        HStack (spacing: 16) {
#if os(macOS)
                            ICloudImageLoader(imageName: ".\(getSelectedGeneration()!.id.uuidString)_client") { requestImage in
                                if let requestImage = requestImage {
                                    ICloudImageLoader(imageName: ".\(getSelectedGeneration()!.id.uuidString)_mask") { maskImage in
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
                                    .id("mask_\(getSelectedGeneration()!.id.uuidString)")
                                }
                            }
                            .id("client_\(getSelectedGeneration()!.id.uuidString)")
#endif
                            
                            ICloudImageLoader(imageName: ".\(getSelectedGeneration()!.id.uuidString)_o50") { image in
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
                                            .contextMenu {
                                                Button("Download", systemImage: "arrow.down") {
                                                    image.saveImageToDownloads(fileName: getSelectedGeneration()!.id.uuidString)
                                                }
                                                Button("Share", systemImage: "square.and.arrow.up") {
                                                    image.shareImage()
                                                }
                                                Divider()
                                                Button("Delete", systemImage: "trash", role: .destructive) {
                                                    showDeleteConfirmation = true
                                                }
                                            }
                                        ICloudImageLoader(imageName: ".\(getSelectedGeneration()!.id.uuidString)_client") { requestImage in
                                            ICloudImageLoader(imageName: ".\(getSelectedGeneration()!.id.uuidString)_mask") { maskImage in
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
                                            }
                                            .id("image_mask_\(getSelectedGeneration()!.id.uuidString)")
                                        }
                                        .id("image_client_\(getSelectedGeneration()!.id.uuidString)")
#else
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
#endif
                                    }
                                }
                            }
                            .id("image_\(getSelectedGeneration()!.id.uuidString)")
                        }
                        .padding(.vertical, 8)
                    }
                    
                    if generations.count > 1 {
                        Picker("Select Image", selection: $generationIndex) {
                            ForEach(0..<generations.count, id: \.self) { index in
                                Text("\(index + 1)")
                                    .monospaced()
                                    .tag(index)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding()
                    }
                }
                
                if let prompt = getSelectedGeneration()?.prompt,
                   !prompt.isEmpty {
                    Section("User Prompts") {
                        SectionKeyValueView(icon: "text.quote", key: "Requested Prompt", value: prompt)
                        if let negativePrompt = getSelectedGeneration()?.negativePrompt,
                           !negativePrompt.isEmpty {
                            SectionKeyValueView(icon: "text.badge.minus", key: "Negative Prompt", value: negativePrompt)
                        }
                        if let searchPrompt = getSelectedGeneration()?.searchPrompt,
                           !searchPrompt.isEmpty {
                            SectionKeyValueView(icon: "rectangle.and.text.magnifyingglass", key: "Search Prompt", value: searchPrompt)
                        }
                    }
                }
                
                Section("Model Response") {
                    if let connection = getConnection(modelId: getSelectedGeneration()!.modelId) {
                        SectionKeyValueView(
                            icon: "link",
                            key: "Connection",
                            value: "",
                            customValueView: ConnectionLabel(connection: connection)
                        )
                    }
                    if let model = getModel(modelId: getSelectedGeneration()!.modelId) {
                        SectionKeyValueView(
                            icon: "link",
                            key: "Model",
                            value: "",
                            customValueView: ModelLabel(model: model)
                        )
                    }
                    SectionKeyValueView(icon: "sparkles", key: "Auto-enhance Opted", value: getSelectedGeneration()!.promptEnhanceOpted ? "Yes" : "No")
                    if let promptEnhanceOpted = getSelectedGeneration()?.promptEnhanceOpted,
                       let promptAfterEnhance = getSelectedGeneration()?.promptAfterEnhance,
                       !promptAfterEnhance.isEmpty,
                       promptEnhanceOpted {
                        SectionKeyValueView(icon: "text.quote", key: "Enhanced Prompt", value: getSelectedGeneration()!.promptAfterEnhance)
                    }
                    if let modelRevisedPrompt = getSelectedGeneration()?.modelRevisedPrompt,
                       !modelRevisedPrompt.isEmpty {
                        SectionKeyValueView(icon: "text.quote", key: "Response Prompt", value: modelRevisedPrompt)
                    }
                    SectionKeyValueView(icon: "dollarsign", key: "Cost", value: "\(String(format: "%.3f", getSelectedGeneration()!.creditUsed).replacingOccurrences(of: ".000", with: "")) \(getConnection(modelId: getSelectedGeneration()!.modelId)?.creditCurrency.rawValue ?? "Credits")")
                }
                
                Section("Image Metadata") {
                    SectionKeyValueView(
                        icon: "aspectratio.fill",
                        key: "Image Dimensions",
                        value: getSelectedGeneration()!.artDimensions.replacingOccurrences(of: "x", with: " x "),
                        monospaced: true
                    )
                    SectionKeyValueView(
                        icon: "internaldrive.fill",
                        key: "Image Size",
                        value: String(format: "%.2f MB", Double(getSelectedGeneration()!.size) / 1000000.0),
                        monospaced: true
                    )
                    SectionKeyValueView(icon: "paintpalette.fill", key: "Color Style", value: getSelectedGeneration()!.artStyle.rawValue)
                    SectionKeyValueView(icon: "paintbrush.fill", key: "Art Variant", value: getSelectedGeneration()!.artVariant.rawValue)
                    SectionKeyValueView(icon: "photo", key: "Image Quality", value: getSelectedGeneration()!.artQuality.rawValue, monospaced: true)
                }
                Section("Other Metadata") {
                    SectionKeyValueView(icon: "calendar", key: "Created", value: getSelectedGeneration()!.createdAt.formatted(
                        date: .abbreviated,
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
            if (imageSet != nil) {
                ToolbarItem(placement: .automatic) {
                    Button("Download", systemImage: "arrow.down") {
                        let image = loadImageFromiCloud("\(getSelectedGeneration()!.id.uuidString)")
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
                        let image = loadImageFromiCloud("\(getSelectedGeneration()!.id.uuidString)")
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
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }
            }
        }
        #if !os(macOS)
        .fileExporter(
            isPresented: $showDocumentPicker,
            document: UIImageFileDocument(
                image: imageSet != nil ? loadImageFromiCloud("\(getSelectedGeneration()?.id.uuidString ?? "")") ?? PlatformImage() : PlatformImage()
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
            if (imageSet != nil) {
                let image = loadImageFromiCloud("\(getSelectedGeneration()?.id.uuidString ?? "")")
                if let image = image {
                    ImageShareSheet(activityItems: [image])
                }
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
        .navigationTitle(labelForItem(.generationImage(setId: setId)))
    }
    
    private func loadData() {
        imageSet = allImageSets.first { $0.id == setId }
        generations = allGenerations.filter { $0.setId == setId }
    }
}
