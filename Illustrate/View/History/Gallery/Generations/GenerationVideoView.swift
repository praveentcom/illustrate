import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import AVKit
import AVFoundation

#if os(macOS)
import AppKit
#else
import UIKit

struct VideoFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.movie] }
    
    var url: URL?
    
    init(url: URL?) {
        self.url = url
    }
    
    init(configuration: ReadConfiguration) throws {
        self.url = URL(fileURLWithPath: "")
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try Data(contentsOf: url!)
        return FileWrapper(regularFileWithContents: data)
    }
}

struct VideoShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<VideoShareSheet>) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<VideoShareSheet>) {}
}
#endif

struct GenerationVideoView: View {
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
                            
                            ICloudVideoLoader(videoName: "\(getSelectedGeneration()!.id.uuidString)") { videoUrl in
                                if let videoUrl = videoUrl {
                                    VStack (spacing: 16) {
#if os(macOS)
                                        VideoPlayer(player: AVPlayer(url: videoUrl))
                                            .frame(maxHeight: 400)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .shadow(color: .black.opacity(0.4), radius: 8)
                                            .frame(maxWidth: .infinity)
                                        ICloudImageLoader(imageName: ".\(getSelectedGeneration()!.id.uuidString)_client") { requestImage in
                                            ICloudImageLoader(imageName: ".\(getSelectedGeneration()!.id.uuidString)_mask") { maskImage in
                                                if (requestImage != nil || maskImage != nil) {
                                                    HStack {
                                                        Image(systemName: "info.circle")
                                                        Text("Generated Video")
                                                    }
                                                    .padding(.vertical, 4)
                                                    .padding(.horizontal, 8)
                                                    .background(.thinMaterial)
                                                    .cornerRadius(8)
                                                }
                                            }
                                            .id("video_mask_\(getSelectedGeneration()!.id.uuidString)")
                                        }
                                        .id("video_client_\(getSelectedGeneration()!.id.uuidString)")
#else
                                        VideoPlayer(player: AVPlayer(url: videoUrl))
                                            .aspectRatio(contentMode: .fill)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
#endif
                                    }
                                }
                            }
                            .id("video_\(getSelectedGeneration()!.id.uuidString)")
                        }
                        .padding(.vertical, 8)
                    }
                    
                    if generations.count > 1 {
                        Picker("Select Video", selection: $generationIndex) {
                            ForEach(0..<generations.count, id: \.self) { index in
                                Text("\(index + 1)").tag(index)
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
                
                Section("Video Metadata") {
                    SectionKeyValueView(
                        icon: "aspectratio.fill",
                        key: "Image Dimensions",
                        value: getSelectedGeneration()!.artDimensions.replacingOccurrences(of: "x", with: " x "),
                        monospaced: true)
                    SectionKeyValueView(
                        icon: "internaldrive.fill",
                        key: "Video Size",
                        value: String(format: "%.2f MB", Double(getSelectedGeneration()!.size) / 1000000.0),
                        monospaced: true
                    )
                    SectionKeyValueView(icon: "paintpalette.fill", key: "Color Style", value: getSelectedGeneration()!.artStyle.rawValue)
                    SectionKeyValueView(icon: "paintbrush.fill", key: "Art Variant", value: getSelectedGeneration()!.artVariant.rawValue)
                    SectionKeyValueView(icon: "photo", key: "Video Quality", value: getSelectedGeneration()!.artQuality.rawValue)
                }
                Section("Other Metadata") {
                    SectionKeyValueView(icon: "calendar", key: "Created", value: getSelectedGeneration()!.createdAt.formatted(
                        date: .abbreviated,
                        time: .shortened
                    ))
                }
            } else {
                Section("Video Details") {
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
                        let videoURL: URL? = loadVideoFromiCloud("\(getSelectedGeneration()!.id.uuidString)")
                        if let videoURL = videoURL {
                            Task {
                                #if os(macOS)
                                saveVideoToDownloads(url: videoURL, fileName: "\(getSelectedGeneration()!.id.uuidString)")
                                #else
                                showDocumentPicker = true
                                #endif
                            }
                        }
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button("Share", systemImage: "square.and.arrow.up") {
                        let videoURL: URL? = loadVideoFromiCloud("\(getSelectedGeneration()!.id.uuidString)")
                        if let videoURL = videoURL {
                            Task {
                                #if os(macOS)
                                shareVideo(url: videoURL)
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
        }
        #if !os(macOS)
        .fileExporter(
            isPresented: $showDocumentPicker,
            document: VideoFileDocument(
                url: imageSet != nil ? loadVideoFromiCloud("\(getSelectedGeneration()?.id.uuidString ?? "")") : nil
            ),
            contentType: .movie,
            defaultFilename: "illustrate_\(getSelectedGeneration()?.id.uuidString ?? "")"
        ) { result in
            switch result {
            case .success(let url):
                print("Saved to \(url)")
            case .failure(let error):
                print("Failed to save video: \(error.localizedDescription)")
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if (imageSet != nil) {
                let videoURL: URL? = loadVideoFromiCloud("\(getSelectedGeneration()?.id.uuidString ?? "")")
                if let videoURL = videoURL {
                    VideoShareSheet(activityItems: [videoURL])
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
        .navigationTitle(labelForItem(.generationVideo(setId: setId)))
    }
    
    private func loadData() {
        imageSet = allImageSets.first { $0.id == setId }
        generations = allGenerations.filter { $0.setId == setId }
    }
}
