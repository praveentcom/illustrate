import Foundation
import KeychainSwift
import SwiftData
import SwiftUI
import PhotosUI

@MainActor
class ImageToVideoViewModel: ObservableObject {
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
    @Published var selectedResolution: String = ""
    @Published var selectedFPS: Int = 24
    @Published var artQuality: EnumArtQuality = .HD
    @Published var artStyle: EnumArtStyle = .VIVID
    @Published var artVariant: EnumArtVariant = .NORMAL
    @Published var numberOfVideos: Int = 1
    @Published var promptEnhanceOpted: Bool = false
    @Published var motion: Double = 135
    @Published var stickyness: Double = 2.0
    @Published var durationSeconds: Int = 8
    @Published var generateAudio: Bool = true

    @Published var selectedImageItem: PhotosPickerItem?
    @Published var selectedImage: PlatformImage?
    @Published var colorPalette: [String] = []
    @Published var isPhotoPickerOpen: Bool = false
    @Published var isCropSheetOpen: Bool = false

    @Published var selectedLastFrameItem: PhotosPickerItem?
    @Published var selectedLastFrame: PlatformImage?
    @Published var isLastFramePickerOpen: Bool = false
    @Published var isLastFrameCropSheetOpen: Bool = false

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

        let videoImageModels = providerService.models(for: .VIDEO_IMAGE).filter {
            $0.providerId.uuidString == selectedProviderId
        }
        
        let veoModels = providerService.models(for: .VIDEO_TEXT).filter {
            $0.providerId.uuidString == selectedProviderId
        }
        
        return videoImageModels + veoModels
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
                ($0.modelSetType == .VIDEO_IMAGE || $0.modelSetType == .VIDEO_TEXT) &&
                $0.active
            }
        }
    }

    var isVeoModel: Bool {
        guard let model = getSelectedModel() else { return false }
        return !model.modelSupportedParams.supportedDurations.isEmpty
    }
    
    var supportsLastFrame: Bool {
        return getSelectedModel()?.modelSupportedParams.supportsLastFrame ?? false
    }
    
    var supportsAudio: Bool {
        return getSelectedModel()?.modelSupportedParams.supportsAudio ?? false
    }
    
    func getSupportedResolutions() -> [String] {
        guard let model = getSelectedModel() else { return [] }
        return model.modelSupportedParams.supportedResolutions
    }
    
    var hasResolutionOptions: Bool {
        return !getSupportedResolutions().isEmpty
    }
    
    func getSupportedFPS() -> [Int] {
        guard let model = getSelectedModel() else { return [] }
        return model.modelSupportedParams.supportedFPS
    }
    
    var hasFPSOptions: Bool {
        return !getSupportedFPS().isEmpty
    }
    
    func getSupportedDurations() -> [Int] {
        guard let model = getSelectedModel() else { return [] }
        return model.modelSupportedParams.supportedDurations
    }
    
    func getValidatedDuration() -> Int {
        let supported = getSupportedDurations().sorted()
        if supported.contains(durationSeconds) {
            return durationSeconds
        }

        let lower = supported.filter { $0 <= durationSeconds }
        return lower.last ?? supported.first ?? durationSeconds
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
                selectedResolution = getSupportedResolutions().last ?? ""
                selectedFPS = getSupportedFPS().first ?? 24
                if isVeoModel {
                    durationSeconds = getSupportedDurations().last ?? 8
                }
            }
        }
    }

    func updateDimensions(dimension: String) {
        guard artDimensions != dimension else { return }

        artDimensions = dimension
        selectedImage = nil
        selectedLastFrame = nil
        colorPalette = []
    }

    func validateAndSetDimensions() {
        let selectedModel = getSelectedModel()
        let supportedDimensions = selectedModel?.modelSupportedParams.dimensions ?? []

        if artDimensions.isEmpty {
            artDimensions = supportedDimensions.first ?? ""
        } else if !supportedDimensions.contains(artDimensions) {
            artDimensions = supportedDimensions.first ?? ""
        }
        
        let supportedResolutions = getSupportedResolutions()
        if selectedResolution.isEmpty || !supportedResolutions.contains(selectedResolution) {
            selectedResolution = supportedResolutions.last ?? ""
        }
        
        let supportedFPS = getSupportedFPS()
        if !supportedFPS.contains(selectedFPS) {
            selectedFPS = supportedFPS.first ?? 24
        }
        
        if isVeoModel {
            let supportedDurations = getSupportedDurations()
            if !supportedDurations.contains(durationSeconds) {
                durationSeconds = supportedDurations.last ?? 8
            }
        }
        
        if !supportsLastFrame {
            selectedLastFrame = nil
            selectedLastFrameItem = nil
        }
    }

    func processSelectedImage(loaded: Data) {
        #if os(macOS)
        selectedImage = NSImage(data: loaded)
        #else
        selectedImage = UIImage(data: loaded)
        #endif

        if let selectedImage = selectedImage {
            colorPalette = dominantColorsFromImage(selectedImage, clusterCount: 6)
            isCropSheetOpen = true
        }
    }

    func handleImageCropping(image: PlatformImage) {
        let targetSize: CGSize
        
        if artDimensions.contains(":") {
            let dims = getVideoDimensions(resolution: selectedResolution, aspectRatio: artDimensions)
            targetSize = CGSize(width: dims.width, height: dims.height)
        } else {
            targetSize = CGSize(
                width: getAspectRatio(dimension: artDimensions).actualWidth,
                height: getAspectRatio(dimension: artDimensions).actualHeight
            )
        }

        selectedImage = image.resizeImage(targetSize: targetSize)

        if let selectedImage = selectedImage {
            colorPalette = dominantColorsFromImage(selectedImage, clusterCount: 6)
        }

        isCropSheetOpen = false
    }

    func cancelImageCropping() {
        selectedImage = nil
        colorPalette = []
        isCropSheetOpen = false
    }

    func processSelectedLastFrame(loaded: Data) {
        #if os(macOS)
        selectedLastFrame = NSImage(data: loaded)
        #else
        selectedLastFrame = UIImage(data: loaded)
        #endif

        if selectedLastFrame != nil {
            isLastFrameCropSheetOpen = true
        }
    }

    func handleLastFrameCropping(image: PlatformImage) {
        let targetSize: CGSize
        
        if artDimensions.contains(":") {
            let dims = getVideoDimensions(resolution: selectedResolution, aspectRatio: artDimensions)
            targetSize = CGSize(width: dims.width, height: dims.height)
        } else {
            targetSize = CGSize(
                width: getAspectRatio(dimension: artDimensions).actualWidth,
                height: getAspectRatio(dimension: artDimensions).actualHeight
            )
        }

        selectedLastFrame = image.resizeImage(targetSize: targetSize)
        isLastFrameCropSheetOpen = false
    }

    func cancelLastFrameCropping() {
        selectedLastFrame = nil
        isLastFrameCropSheetOpen = false
    }

    func submitToQueue(providerKeys: [ProviderKey], queueManager: QueueManager, modelContext: ModelContext) {
        guard let selectedModel = getSelectedModel() else {
            errorState = ErrorState(
                message: "No model selected",
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
        
        var resolution: String? = nil
        if hasResolutionOptions {
            resolution = selectedResolution
        } else if isVeoModel {
            resolution = artDimensions.contains("1080") || artDimensions.contains("1920") ? "1080p" : "720p"
        }

        let request = VideoGenerationRequest(
            modelId: selectedModel.modelId.uuidString,
            prompt: prompt,
            negativePrompt: negativePrompt.isEmpty ? nil : negativePrompt,
            artDimensions: artDimensions,
            clientImage: selectedImage?.toBase64PNG(),
            clientLastFrame: selectedLastFrame?.toBase64PNG(),
            providerKey: providerKey,
            providerSecret: providerSecret,
            motion: isVeoModel ? nil : Int(motion),
            stickyness: isVeoModel ? nil : Int(stickyness),
            durationSeconds: isVeoModel ? getValidatedDuration() : nil,
            resolution: resolution,
            fps: hasFPSOptions ? selectedFPS : nil,
            generateAudio: supportsAudio ? generateAudio : nil
        )

        _ = queueManager.submitVideoGeneration(
            request: request,
            modelContext: modelContext
        )

        showQueuedToast = true
    }

    var canGenerate: Bool {
        return selectedImage != nil && !selectedModelId.isEmpty
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
