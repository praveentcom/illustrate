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
        }
        try? modelContext.save()
        
        presentationMode.wrappedValue.dismiss()
    }
    
    var body: some View {
        Form {
            if (getSelectedGeneration() != nil || imageSet != nil) {
                let videoUrl: URL? = loadVideoUrlFromDocumentsDirectory(withName: "\(getSelectedGeneration()!.id.uuidString)")
                
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
                            if let videoUrl = videoUrl {
                                VStack (spacing: 16) {
#if os(macOS)
                                    VideoPlayer(player: AVPlayer(url: videoUrl))
                                        .frame(maxHeight: 400)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .shadow(color: .black.opacity(0.4), radius: 8)
                                        .frame(maxWidth: .infinity)
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
#else
                                    VideoPlayer(player: AVPlayer(url: videoUrl))
                                        .aspectRatio(contentMode: .fill)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
#endif
                                }
                            }
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
                Section("Video Metadata") {
                    SectionKeyValueView(icon: "arrow.down.left.and.arrow.up.right.rectangle", key: "Image Dimensions", value: getSelectedGeneration()!.artDimensions)
                    SectionKeyValueView(
                        icon: "internaldrive",
                        key: "Video Size",
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
            ToolbarItem(placement: .automatic) {
                Button("Download", systemImage: "arrow.down") {
                    let videoURL: URL? = loadVideoUrlFromDocumentsDirectory(withName: "\(getSelectedGeneration()!.id.uuidString)")
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
                    let videoURL: URL? = loadVideoUrlFromDocumentsDirectory(withName: "\(getSelectedGeneration()!.id.uuidString)")
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
        #if !os(macOS)
        .fileExporter(
            isPresented: $showDocumentPicker,
            document: VideoFileDocument(
                url: loadVideoUrlFromDocumentsDirectory(withName: "\(getSelectedGeneration()?.id.uuidString ?? "")")
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
            let videoURL: URL? = loadVideoUrlFromDocumentsDirectory(withName: "\(getSelectedGeneration()!.id.uuidString)")
            if let videoURL = videoURL {
                VideoShareSheet(activityItems: [videoURL])
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
        .navigationTitle("Video Generation")
    }
    
    private func loadData() {
        imageSet = allImageSets.first { $0.id == setId }
        generations = allGenerations.filter { $0.setId == setId }
    }
}
