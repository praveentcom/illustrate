import SwiftData
import SwiftUI
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

        init(configuration _: ReadConfiguration) throws {
            image = UIImage()
        }

        func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
            let data = image.pngData()!
            return FileWrapper(regularFileWithContents: data)
        }
    }

    struct ImageShareSheet: UIViewControllerRepresentable {
        var activityItems: [Any]
        var applicationActivities: [UIActivity]? = nil

        func makeUIViewController(context _: UIViewControllerRepresentableContext<ImageShareSheet>) -> UIActivityViewController {
            return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        }

        func updateUIViewController(_: UIActivityViewController, context _: UIViewControllerRepresentableContext<ImageShareSheet>) {}
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
                .drawingGroup()
        #else
            Image(uiImage: maskImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .opacity(0.4)
                .drawingGroup()
        #endif
    }
}

struct GenerationImageView: View {
    @Environment(\.openURL) var openURL
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) private var presentationMode

    let setId: UUID
    @State private var imageSet: ImageSet? = nil
    @State private var generations: [Generation] = []
    @State private var generationIndex: Int = 0

    @State private var showMask: Bool = false
    @State private var showDeleteConfirmation = false
    @State private var showDocumentPicker = false
    @State private var showShareSheet = false
    
    @State private var exportImage: PlatformImage? = nil
    
    private var selectedGeneration: Generation? {
        guard generationIndex >= 0 && generationIndex < generations.count else { return nil }
        return generations[generationIndex]
    }

    func getSelectedGeneration() -> Generation? {
        return selectedGeneration
    }

    func deleteImageSet() async {
        modelContext.delete(imageSet!)
        for generation in generations {
            modelContext.delete(generation)

            deleteICloudDocuments(containingSubstring: generation.id.uuidString)
        }
        try? modelContext.save()

        DispatchQueue.main.async {
            presentationMode.wrappedValue.dismiss()
        }
    }

    var body: some View {
        Form {
            if let generation = selectedGeneration {
                Section {
                    GenerationImageSection(
                        generation: generation,
                        showMask: $showMask,
                        showDeleteConfirmation: $showDeleteConfirmation
                    )

                    if generations.count > 1 {
                        Picker("Select Image", selection: $generationIndex) {
                            ForEach(0 ..< generations.count, id: \.self) { index in
                                Text("\(index + 1)")
                                    .monospaced()
                                    .tag(index)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding()
                    }
                }

                if !generation.prompt.isEmpty {
                    Section("User Prompts") {
                        SectionKeyValueView(icon: "text.quote", key: "Requested Prompt", value: generation.prompt)
                        if let negativePrompt = generation.negativePrompt, !negativePrompt.isEmpty {
                            SectionKeyValueView(icon: "text.badge.minus", key: "Negative Prompt", value: negativePrompt)
                        }
                        if let searchPrompt = generation.searchPrompt, !searchPrompt.isEmpty {
                            SectionKeyValueView(icon: "rectangle.and.text.magnifyingglass", key: "Search Prompt", value: searchPrompt)
                        }
                    }
                }

                Section("Model Response") {
                    if let connection = getConnection(modelId: generation.modelId) {
                        SectionKeyValueView(
                            icon: "link",
                            key: "Connection",
                            value: "",
                            customValueView: ConnectionLabel(connection: connection)
                        )
                    }
                    if let model = ConnectionService.shared.model(by: generation.modelId) {
                        SectionKeyValueView(
                            icon: "network",
                            key: "Model",
                            value: "",
                            customValueView: ModelLabel(model: model)
                        )
                    }
                    SectionKeyValueView(icon: "sparkles", key: "Auto-enhance opted", value: generation.promptEnhanceOpted ? "Yes" : "No")
                    if generation.promptEnhanceOpted && !generation.promptAfterEnhance.isEmpty {
                        SectionKeyValueView(icon: "text.quote", key: "Enhanced Prompt", value: generation.promptAfterEnhance)
                    }
                    if let modelRevisedPrompt = generation.modelRevisedPrompt, !modelRevisedPrompt.isEmpty {
                        SectionKeyValueView(icon: "text.quote", key: "Response Prompt", value: modelRevisedPrompt)
                    }
                    SectionKeyValueView(icon: "dollarsign", key: "Cost", value: "\(String(format: "%.3f", generation.creditUsed).replacingOccurrences(of: ".000", with: "")) \(getConnection(modelId: generation.modelId)?.creditCurrency.rawValue ?? "Credits")")
                }

                Section("Image Metadata") {
                    SectionKeyValueView(
                        icon: "aspectratio.fill",
                        key: "Image Dimensions",
                        value: generation.artDimensions.replacingOccurrences(of: "x", with: " x "),
                        monospaced: true
                    )
                    SectionKeyValueView(
                        icon: "internaldrive.fill",
                        key: "Image Size",
                        value: String(format: "%.2f MB", Double(generation.size) / 1_000_000.0),
                        monospaced: true
                    )
                    SectionKeyValueView(icon: "paintpalette.fill", key: "Color Style", value: generation.artStyle.rawValue)
                    SectionKeyValueView(icon: "paintbrush.fill", key: "Art Variant", value: generation.artVariant.rawValue)
                    SectionKeyValueView(icon: "photo", key: "Image Quality", value: generation.artQuality.rawValue, monospaced: true)
                }
                Section("Other Metadata") {
                    SectionKeyValueView(icon: "calendar", key: "Created", value: generation.createdAt.formatted(
                        date: .abbreviated,
                        time: .shortened
                    ))
                }
                Section("Notice something wrong?") {
                    HStack {
                        Text("Send an email")
                        Spacer()
                        Link("Submit feedback", destination: getFeedbackLink())
                    }
                }
            } else if imageSet == nil {
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
            if let generation = selectedGeneration {
                ToolbarItem(placement: .automatic) {
                    Button("Download", systemImage: "arrow.down") {
                        let image = loadImageFromiCloud("\(generation.id.uuidString)")
                        if let image = image {
                            #if os(macOS)
                                image.saveImageToDownloads(fileName: generation.id.uuidString)
                            #else
                                exportImage = image
                                showDocumentPicker = true
                            #endif
                        }
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button("Share", systemImage: "square.and.arrow.up") {
                        let image = loadImageFromiCloud("\(generation.id.uuidString)")
                        if let image = image {
                            #if os(macOS)
                                image.shareImage()
                            #else
                                exportImage = image
                                showShareSheet = true
                            #endif
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
                image: exportImage ?? PlatformImage()
            ),
            contentType: .png,
            defaultFilename: "illustrate_\(selectedGeneration?.id.uuidString ?? "")"
        ) { result in
            switch result {
            case let .success(url):
                print("Saved to \(url)")
            case let .failure(error):
                print("Failed to save image: \(error.localizedDescription)")
            }
            exportImage = nil
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = exportImage {
                ImageShareSheet(activityItems: [image])
            }
        }
        .onChange(of: showShareSheet) { _, isPresented in
            if !isPresented {
                exportImage = nil
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
        let imageSetDescriptor = FetchDescriptor<ImageSet>(predicate: #Predicate { $0.id == setId })
        let generationsDescriptor = FetchDescriptor<Generation>(
            predicate: #Predicate { $0.setId == setId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            imageSet = try modelContext.fetch(imageSetDescriptor).first
            generations = try modelContext.fetch(generationsDescriptor)
        } catch {
            print("Error fetching data: \(error)")
        }
    }
}

private struct GenerationImageSection: View {
    let generation: Generation
    @Binding var showMask: Bool
    @Binding var showDeleteConfirmation: Bool
    
    private var imageId: String { generation.id.uuidString }
    private var clientImageName: String { ".\(imageId)_client" }
    private var maskImageName: String { ".\(imageId)_mask" }
    private var optimizedImageName: String { ".\(imageId)_o50" }
    
    var body: some View {
        ZStack {
            SmoothAnimatedGradientView(colors: generation.colorPalette.compactMap { hex in
                Color(getUniversalColorFromHex(hexString: hex))
            })

            HStack(spacing: 16) {
                #if os(macOS)
                requestImageView
                #endif
                
                generatedImageView
            }
            .padding(.vertical, 8)
        }
    }
    
    #if os(macOS)
    @ViewBuilder
    private var requestImageView: some View {
        ICloudImageLoader(imageName: clientImageName) { requestImage in
            if let requestImage = requestImage {
                ICloudImageLoader(imageName: maskImageName) { maskImage in
                    VStack(spacing: 16) {
                        Image(nsImage: requestImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .frame(maxHeight: 400)
                            .overlay {
                                if showMask, let maskImage = maskImage {
                                    MaskView(maskImage: maskImage)
                                }
                            }
                            .shadow(color: .black.opacity(0.4), radius: 8)
                            .frame(maxWidth: .infinity)
                            .drawingGroup()
                        
                        HStack(spacing: 8) {
                            InfoLabel("Request Image")

                            if maskImage != nil {
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
                .id("mask_\(imageId)")
            }
        }
        .id("client_\(imageId)")
    }
    #endif
    
    @ViewBuilder
    private var generatedImageView: some View {
        ICloudImageLoader(imageName: optimizedImageName) { image in
            if let image = image {
                VStack(spacing: 16) {
                    #if os(macOS)
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .frame(maxHeight: 400)
                        .shadow(color: .black.opacity(0.4), radius: 8)
                        .frame(maxWidth: .infinity)
                        .drawingGroup()
                        .contextMenu {
                            Button("Download", systemImage: "arrow.down") {
                                image.saveImageToDownloads(fileName: imageId)
                            }
                            Button("Share", systemImage: "square.and.arrow.up") {
                                image.shareImage()
                            }
                            Divider()
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                showDeleteConfirmation = true
                            }
                        }
                    
                    ICloudImageLoader(imageName: clientImageName) { requestImage in
                        ICloudImageLoader(imageName: maskImageName) { maskImage in
                            if requestImage != nil || maskImage != nil {
                                InfoLabel("Generated Image")
                            }
                        }
                        .id("image_mask_\(imageId)")
                    }
                    .id("image_client_\(imageId)")
                    #else
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .drawingGroup()
                    #endif
                }
            }
        }
        .id("image_\(imageId)")
    }
}
