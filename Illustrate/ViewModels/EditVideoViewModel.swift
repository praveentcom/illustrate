import AVFoundation
import Foundation
import KeychainSwift
import PhotosUI
import SwiftData
import SwiftUI

@MainActor
class EditVideoViewModel: ObservableObject {
    private let providerService: ProviderService
    private let keychain: KeychainSwift

    @Published var selectedProviderId: String = ""
    @Published var selectedModelId: String = ""
    @Published var errorState = ErrorState(message: "", isShowing: false)
    @Published var isNavigationActive: Bool = false
    @Published var selectedSetId: UUID? = nil
    @Published var showQueuedToast: Bool = false

    @Published var prompt: String = ""
    @Published var negativePrompt: String = ""
    @Published var artDimensions: String = ""
    @Published var durationSeconds: Int = 8
    @Published var generateAudio: Bool = true

    @Published var selectedVideoItem: PhotosPickerItem?
    @Published var selectedVideoData: Data?
    @Published var selectedVideoThumbnail: PlatformImage?
    @Published var selectedVideoURL: URL?
    @Published var isVideoPickerOpen: Bool = false
    @Published var isVideoPreviewOpen: Bool = false
    @Published var isProcessingVideo: Bool = false

    var focusedField: Field? = nil

    enum Field: Int, CaseIterable {
        case prompt, negativePrompt
    }

    init(
        providerService: ProviderService = ProviderService.shared,
        keychain: KeychainSwift = KeychainSwift()
    ) {
        self.providerService = providerService
        self.keychain = keychain

        self.keychain.accessGroup = keychainAccessGroup
        self.keychain.synchronizable = true
    }

    func getSupportedModels(providerKeys: [ProviderKey]) -> [ProviderModel] {
        guard !selectedProviderId.isEmpty else { return [] }

        return providerService.allModels.filter {
            $0.providerId.uuidString == selectedProviderId &&
            $0.modelSupportedParams.supportsVideoInput &&
            $0.active
        }
    }

    func getSelectedModel() -> ProviderModel? {
        guard !selectedModelId.isEmpty else { return nil }
        return providerService.model(by: selectedModelId)
    }

    func getSupportedProviders(providerKeys: [ProviderKey]) -> [Provider] {
        return providers.filter { provider in
            providerKeys.contains { $0.providerId == provider.providerId } &&
            providerService.allModels.contains {
                $0.providerId == provider.providerId &&
                $0.modelSupportedParams.supportsVideoInput &&
                $0.active
            }
        }
    }

    func initialize(providerKeys: [ProviderKey]) {
        guard !providerKeys.isEmpty && selectedModelId.isEmpty else { return }

        let supportedProviders = getSupportedProviders(providerKeys: providerKeys)

        if let firstSupportedProvider = supportedProviders.first,
           let key = providerKeys.first(where: { $0.providerId == firstSupportedProvider.providerId }) {
            selectedProviderId = key.providerId.uuidString

            let models = getSupportedModels(providerKeys: providerKeys)
            selectedModelId = models.first?.modelId.uuidString ?? ""

            if !selectedProviderId.isEmpty, !selectedModelId.isEmpty {
                artDimensions = getSelectedModel()?.modelSupportedParams.dimensions.first ?? ""
            }
        }
    }

    func validateAndSetDimensions() {
        let selectedModel = getSelectedModel()
        let supportedDimensions = selectedModel?.modelSupportedParams.dimensions ?? []

        if artDimensions.isEmpty {
            artDimensions = supportedDimensions.first ?? ""
        } else if !supportedDimensions.contains(artDimensions) {
            artDimensions = supportedDimensions.first ?? ""
        }
    }

    func getSupportedDurations() -> [Int] {
        guard let model = getSelectedModel() else { return [] }
        return model.modelSupportedParams.supportedDurations
    }

    func processSelectedVideo() async {
        guard let videoItem = selectedVideoItem else { return }
        
        isProcessingVideo = true
        
        do {
            if let movie = try await videoItem.loadTransferable(type: VideoTransferable.self) {
                selectedVideoData = movie.data
                selectedVideoThumbnail = await generateThumbnail(from: movie.data)
            }
        } catch {
            errorState = ErrorState(
                message: "Failed to load video: \(error.localizedDescription)",
                isShowing: true
            )
        }
        
        isProcessingVideo = false
    }
    
    private func generateThumbnail(from videoData: Data) async -> PlatformImage? {
        if let oldURL = selectedVideoURL {
            try? FileManager.default.removeItem(at: oldURL)
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        
        do {
            try videoData.write(to: tempURL)
            selectedVideoURL = tempURL
            
            let asset = AVURLAsset(url: tempURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            let time = CMTime(seconds: 0.1, preferredTimescale: 600)
            let cgImage = try await imageGenerator.image(at: time).image
            
            #if os(macOS)
            return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            #else
            return UIImage(cgImage: cgImage)
            #endif
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            selectedVideoURL = nil
            return nil
        }
    }

    func clearVideo() {
        if let url = selectedVideoURL {
            try? FileManager.default.removeItem(at: url)
        }
        selectedVideoItem = nil
        selectedVideoData = nil
        selectedVideoThumbnail = nil
        selectedVideoURL = nil
    }

    func submitToQueue(providerKeys: [ProviderKey], queueManager: QueueManager, modelContext: ModelContext) {
        guard let selectedModel = getSelectedModel() else {
            errorState = ErrorState(
                message: "No model selected",
                isShowing: true
            )
            return
        }
        
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorState = ErrorState(
                message: "Prompt is required to extend the video",
                isShowing: true
            )
            return
        }
        
        guard let videoData = selectedVideoData else {
            errorState = ErrorState(
                message: "Please select a video to extend",
                isShowing: true
            )
            return
        }

        guard let providerSecret = keychain.get(selectedModel.providerId.uuidString) else {
            errorState = ErrorState(
                message: "Keychain record not found",
                isShowing: true
            )
            return
        }

        guard let providerKey = providerKeys.first(where: {
            $0.providerId == selectedModel.providerId
        }) else {
            errorState = ErrorState(
                message: "Provider key not found",
                isShowing: true
            )
            return
        }

        let request = VideoGenerationRequest(
            modelId: selectedModel.modelId.uuidString,
            prompt: prompt,
            negativePrompt: negativePrompt.isEmpty ? nil : negativePrompt,
            artDimensions: artDimensions,
            clientVideo: videoData.base64EncodedString(),
            providerKey: providerKey,
            providerSecret: providerSecret,
            durationSeconds: durationSeconds,
            resolution: "720p",
            generateAudio: generateAudio
        )

        _ = queueManager.submitVideoGeneration(
            request: request,
            modelContext: modelContext
        )

        showQueuedToast = true
    }

    var canGenerate: Bool {
        return !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
               selectedVideoData != nil && 
               !selectedModelId.isEmpty
    }

    var hasProvider: Bool {
        return !selectedModelId.isEmpty
    }

    func resetNavigation() {
        focusedField = nil
        isNavigationActive = false
        selectedSetId = nil
    }
}

struct VideoTransferable: Transferable {
    let data: Data
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .movie) { data in
            VideoTransferable(data: data)
        }
    }
}

